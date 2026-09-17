const path = require('path');
const dns = require('dns');
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Fix for Node.js DNS resolution issues with MongoDB Atlas
dns.setServers(['8.8.8.8', '8.8.4.4']);
dns.setDefaultResultOrder('ipv4first');

const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');
const connectDB = require('./config/database');
const errorHandler = require('./middleware/errorMiddleware');
const auditLogger = require('./middleware/auditMiddleware');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

// Route files
const auth = require('./routes/authRoutes');
const users = require('./routes/userRoutes');
const donations = require('./routes/donationRoutes');
const notifications = require('./routes/notificationRoutes');
const admin = require('./routes/adminRoutes');
const emergency = require('./routes/emergencyRoutes');
const chat = require('./routes/chatRoutes');
const ratings = require('./routes/ratingRoutes');

const app = express();

// Body parser
app.use(express.json());
app.use(cookieParser());
app.use(auditLogger);
app.use(morgan('dev'));
app.use(helmet());

// Enable CORS
app.use(cors({
  origin: "*",
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'token']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 100,
});
app.use(limiter);

// Brute-force protection for login/reset
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Too many login attempts, please try again after 15 minutes'
});
app.use('/api/auth/login', loginLimiter);
app.use('/api/auth/forgot-password', loginLimiter);
app.use('/api/auth/reset-password', loginLimiter);

// Set static folder
app.use(express.static(path.join(__dirname, 'uploads')));

// Mount routers
app.use('/api/auth', auth);
app.use('/api/user', users);
app.use('/api/donations', donations);
app.use('/api/notifications', notifications);
app.use('/api/admin', admin);
app.use('/api/emergency', emergency);
app.use('/api/chat', chat);
app.use('/api/ratings', ratings);

app.use(errorHandler);

// Basic health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Backend is running successfully',
    timestamp: new Date(),
    mongoStatus: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

app.get('/', (req, res) => res.send('API is running...'));

const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, "0.0.0.0", () => console.log(`Server running on port ${PORT}`));

// Socket.io Setup
const io = require('socket.io')(server, {
  cors: { origin: "*", methods: ["GET", "POST"] }
});

global.io = io;

const jwt = require('jsonwebtoken');
const User = require('./models/User');
const Donation = require('./models/Donation');
const LocationLog = require('./models/LocationLog');
const Message = require('./models/Message');
const Chat = require('./models/Chat');

// Track online users
const onlineUsers = new Map();

io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.token;
    if (!token) return next(new Error('Authentication error'));

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) return next(new Error('User not found'));

    socket.user = user;
    next();
  } catch (err) {
    next(new Error('Invalid token'));
  }
});

io.on('connection', (socket) => {
  const userId = socket.user.id.toString();
  onlineUsers.set(userId, socket.id);

  // Join personal and online status rooms
  socket.join(userId);
  socket.broadcast.emit('user_online', { userId, status: 'online' });

  // --- Chat Events ---

  socket.on('join_chat', (chatId) => {
    socket.join(`chat_${chatId}`);
  });

  socket.on('typing', ({ chatId, receiverId }) => {
    socket.to(`chat_${chatId}`).emit('typing_status', { chatId, senderId: userId, isTyping: true });
  });

  socket.on('stop_typing', ({ chatId, receiverId }) => {
    socket.to(`chat_${chatId}`).emit('typing_status', { chatId, senderId: userId, isTyping: false });
  });

  socket.on('send_message', async (messageData) => {
    // Note: sendMessage controller already broadcasts to chat room and personal rooms
    // This event can be used for extra client-side specific triggers if needed
  });

  socket.on('message_seen', async ({ chatId, messageId }) => {
    await Message.findByIdAndUpdate(messageId, { status: 'seen' });
    socket.to(`chat_${chatId}`).emit('message_status_update', { messageId, status: 'seen' });
  });

  // --- Delivery Tracking Events ---

  socket.on('join_delivery', async (donationId) => {
    socket.join(`delivery_${donationId}`);
  });

  socket.on('update_location', async (data) => {
    const { donationId, latitude, longitude, accuracy, speed, heading } = data;
    socket.to(`delivery_${donationId}`).emit('location_update', { ...data, volunteerId: userId, timestamp: new Date() });

    const updateFields = {
      currentLatitude: latitude,
      currentLongitude: longitude,
      lastLocationUpdate: new Date()
    };

    if (latitude && longitude) {
      const coords = [parseFloat(longitude), parseFloat(latitude)];
      updateFields.location = {
        type: 'Point',
        coordinates: coords
      };

      // Requirement: Historical GPS Logging
      try {
        if (donationId) {
          await LocationLog.create({
            donationId,
            volunteerId: userId,
            location: {
              type: 'Point',
              coordinates: coords
            },
            accuracy: accuracy || 0,
            speed: speed || 0,
            heading: heading || 0,
            timestamp: new Date()
          });
        }
      } catch (logErr) {
        console.error('Location Log Error:', logErr.message);
      }
    }

    await User.findByIdAndUpdate(userId, updateFields);
  });

  socket.on('disconnect', () => {
    onlineUsers.delete(userId);
    socket.broadcast.emit('user_offline', { userId, lastSeen: new Date() });
  });
});

const { checkExpiringDonations } = require('./services/notificationService');

// Background Tasks
setInterval(checkExpiringDonations, 15 * 60 * 1000); // Every 15 mins

process.on('unhandledRejection', (err) => {
  console.log(`Error: ${err.message}`);
});
