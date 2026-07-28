const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please add a name'],
  },
  email: {
    type: String,
    required: [true, 'Please add an email'],
    unique: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email',
    ],
  },
  password: {
    type: String,
    required: [true, 'Please add a password'],
    minlength: 6,
    select: false,
  },
  role: {
    type: String,
    enum: ['donor', 'ngo', 'admin', 'volunteer'],
    default: 'donor',
  },
  phoneNumber: {
    type: String,
    required: [true, 'Please add a phone number'],
  },
  address: String,
  latitude: Number,
  longitude: Number,
  profileImage: String,

  // Real-time location for NGO/Volunteer tracking
  currentLatitude: Number,
  currentLongitude: Number,
  lastLocationUpdate: Date,

  // NGO Specific
  ngoRegistrationNumber: String,
  ngoCertificateUrl: String,
  ngoIdProofUrl: String,

  // Feature 5: NGO Availability
  availabilityStatus: {
    type: String,
    enum: ['Available', 'Busy', 'Offline'],
    default: 'Available',
  },

  // Feature 8: Ratings
  averageRating: {
    type: Number,
    default: 0,
  },
  totalRatings: {
    type: Number,
    default: 0,
  },

  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  refreshToken: String,
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

UserSchema.methods.getSignedJwtToken = function () {
  return jwt.sign({ id: this._id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

UserSchema.methods.getRefreshToken = function () {
  const refreshToken = jwt.sign({ id: this._id }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });
  this.refreshToken = refreshToken;
  return refreshToken;
};

UserSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);
