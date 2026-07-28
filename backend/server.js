const path = require('path');
const dns = require('dns');
const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Fix for Node.js DNS resolution issues with MongoDB Atlas
// This forces Node to use Google DNS which we verified works for resolving your cluster
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

// Cookie parser
app.use(cookieParser());

// Audit Logger
app.use(auditLogger);

// Dev logging middleware
app.use(morgan('dev'));

// Set security headers
app.use(helmet());

// Enable CORS
app.use(cors({
  origin: "*", // For production, replace with specific domain if using a web frontend
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'token']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 mins
  max: 100, // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Specific limiter for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 mins
  max: 20, // 20 requests per 15 mins
  message: 'Too many login/registration attempts, please try again after 15 minutes'
});
app.use('/api/auth', authLimiter);

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

// Basic health check route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Backend is running successfully',
    timestamp: new Date(),
    mongoStatus: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

app.get('/', (req, res) => {
  res.send('API is running...');
});

// For Flutter reachability test
app.get('/api', (req, res) => {
  res.json({ success: true, message: 'Smart Food Distribution API is online' });
});

const PORT = process.env.PORT || 5000;

const server = app.listen(
  PORT,
  "0.0.0.0",
  () => console.log(
    `Server running in ${process.env.NODE_ENV} mode on port ${PORT}`
  )
);

// Socket.io Setup with JWT Authentication
const io = require('socket.io')(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const jwt = require('jsonwebtoken');
const User = require('./models/User');
const Donation = require('./models/Donation');
const LocationLog = require('./models/LocationLog');

io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.token;
    if (!token) return next(new Error('Authentication error: No token provided'));

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) return next(new Error('Authentication error: User not found'));

    socket.user = user;
    next();
  } catch (err) {
    next(new Error('Authentication error: Invalid token'));
  }
});

io.on('connection', (socket) => {
  console.log(`Authenticated client connected: ${socket.id} (User: ${socket.user.name})`);

  socket.on('join_delivery', async (donationId) => {
    // Check if user is authorized for this donation
    const donation = await Donation.findById(donationId);
    if (!donation) return;

    const isAuthorized =
      donation.donorId.toString() === socket.user.id ||
      donation.assignedNgoId?.toString() === socket.user.id ||
      donation.volunteerId?.toString() === socket.user.id ||
      socket.user.role === 'admin';

    if (isAuthorized) {
      socket.join(`delivery_${donationId}`);
      console.log(`User ${socket.user.name} joined delivery room: ${donationId}`);
    }
  });

  socket.on('update_location', async (data) => {
    const { donationId, latitude, longitude, accuracy, speed, heading } = data;

    // 1. Broadcast to all users in the delivery room
    socket.to(`delivery_${donationId}`).emit('location_update', {
      latitude,
      longitude,
      accuracy,
      speed,
      heading,
      volunteerId: socket.user.id,
      timestamp: new Date()
    });

    // 2. Update User's current location in DB
    await User.findByIdAndUpdate(socket.user.id, {
      currentLatitude: latitude,
      currentLongitude: longitude,
      lastLocationUpdate: new Date()
    });

    // 3. Log location for history (Async, don't block)
    LocationLog.create({
      donationId,
      volunteerId: socket.user.id,
      location: { coordinates: [longitude, latitude] },
      accuracy,
      speed,
      heading
    }).catch(err => console.error('Location Log Error:', err));
  });

  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  console.log(`Error: ${err.message}`);
});
