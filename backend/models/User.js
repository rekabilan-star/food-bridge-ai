const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

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
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
    },
  },
  profileImage: String,

  // Security Features
  isEmailVerified: {
    type: Boolean,
    default: false,
  },
  loginAttempts: {
    type: Number,
    default: 0,
  },
  lockUntil: {
    type: Date,
  },
  lastLogin: {
    type: Date,
  },
  loginHistory: [{
    timestamp: { type: Date, default: Date.now },
    ip: String,
    deviceInfo: String,
    os: String
  }],

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
  resetPasswordToken: String,
  resetPasswordExpire: Date,

  createdAt: {
    type: Date,
    default: Date.now,
  },
});

UserSchema.index({ location: '2dsphere' });

UserSchema.pre('save', async function (next) {
  if (this.isModified('latitude') || this.isModified('longitude') || this.isModified('currentLatitude') || this.isModified('currentLongitude')) {
    const lat = this.currentLatitude || this.latitude;
    const lng = this.currentLongitude || this.longitude;
    if (lat && lng) {
      this.location = {
        type: 'Point',
        coordinates: [lng, lat],
      };
    }
  }

  if (!this.isModified('password')) {
    return next();
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

// Generate and hash password token
UserSchema.methods.getResetPasswordToken = function () {
  // Generate token
  const resetToken = crypto.randomBytes(20).toString('hex');

  // Hash token and set to resetPasswordToken field
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  // Set expire
  this.resetPasswordExpire = Date.now() + 10 * 60 * 1000;

  return resetToken;
};

module.exports = mongoose.model('User', UserSchema);
