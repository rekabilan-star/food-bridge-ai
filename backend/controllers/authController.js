const User = require('../models/User');
const OTP = require('../models/OTP');
const crypto = require('crypto');
const { notify } = require('../services/notificationService');
const sms = require('../services/smsService');
const emailService = require('../services/emailService');

// @desc    Register Donor
// @route   POST /api/auth/register/donor
// @access  Public
exports.registerDonor = async (req, res, next) => {
  try {
    const { name, email, password, phoneNumber, address, latitude, longitude } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
        return res.status(400).json({ success: false, message: 'An account with this email already exists' });
    }

    const user = await User.create({
      name, email, password, phoneNumber, address, latitude, longitude, role: 'donor',
    });

    // Send Welcome Notification
    notify({
      userId: user._id,
      title: 'Welcome to FoodBridge AI! 🥗',
      body: 'Thank you for joining our mission to rescue food. You can now start donating surplus food.',
      category: 'PROFILE'
    });

    sendTokenResponse(user, 201, res, req);
  } catch (err) {
    next(err);
  }
};

// @desc    Register NGO
// @route   POST /api/auth/register/ngo
// @access  Public
exports.registerNgo = async (req, res, next) => {
  try {
    const { name, email, password, phoneNumber, address, latitude, longitude, ngoRegistrationNumber, certificateUrl, idProofUrl, acceptedCategories, maxDailyMeals } = req.body;

    // Check if NGO already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
        return res.status(400).json({ success: false, message: 'An account with this email already exists' });
    }

    const user = await User.create({
      name, email, password, phoneNumber, address, latitude, longitude, ngoRegistrationNumber, ngoCertificateUrl: certificateUrl, ngoIdProofUrl: idProofUrl, role: 'ngo', status: 'pending',
      acceptedCategories: acceptedCategories || [],
      maxDailyMeals: maxDailyMeals || 0,
    });

    sendTokenResponse(user, 201, res, req);
  } catch (err) {
    next(err);
  }
};

// @desc    Login User
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { email, password, deviceInfo, os } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide an email and password' });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Check if account is locked
    if (user.lockUntil && user.lockUntil > Date.now()) {
        const remainingMinutes = Math.ceil((user.lockUntil - Date.now()) / 60000);
        return res.status(423).json({
            success: false,
            message: `Account is locked. Try again in ${remainingMinutes} minutes`
        });
    }

    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      // Increment login attempts
      user.loginAttempts += 1;
      if (user.loginAttempts >= 5) {
          user.lockUntil = Date.now() + 15 * 60 * 1000; // Lock for 15 mins
          user.loginAttempts = 0; // Reset for after lock period
          await user.save();
          return res.status(423).json({ success: false, message: 'Too many failed attempts. Account locked for 15 minutes' });
      }
      await user.save();
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Reset login attempts on success
    user.loginAttempts = 0;
    user.lockUntil = undefined;
    user.lastLogin = Date.now();

    // Add to login history
    user.loginHistory.unshift({
        ip: req.ip,
        deviceInfo: deviceInfo || 'Unknown',
        os: os || 'Unknown'
    });

    // Keep only last 10 login records
    if (user.loginHistory.length > 10) {
        user.loginHistory.pop();
    }

    await user.save();

    sendTokenResponse(user, 200, res, req);
  } catch (err) {
    next(err);
  }
};

const sendTokenResponse = async (user, statusCode, res, req) => {
  const token = user.getSignedJwtToken();
  const refreshToken = user.getRefreshToken();

  await user.save({ validateBeforeSave: false });

  res.status(statusCode).json({
    success: true,
    token,
    refreshToken,
    user: {
      id: user._id,
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phoneNumber: user.phoneNumber,
      address: user.address,
      latitude: user.latitude,
      longitude: user.longitude,
      profileImage: user.profileImage,
      status: user.status,
      availabilityStatus: user.availabilityStatus || 'Available',
      averageRating: user.averageRating || 0,
      totalRatings: user.totalRatings || 0,
      lastLogin: user.lastLogin,
      ngoRegistrationNumber: user.ngoRegistrationNumber,
      ngoCertificateUrl: user.ngoCertificateUrl,
      ngoIdProofUrl: user.ngoIdProofUrl,
      acceptedCategories: user.acceptedCategories || [],
      maxDailyMeals: user.maxDailyMeals || 0
    }
  });
};

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

// @desc    Refresh Token
// @route   POST /api/auth/refresh-token
// @access  Public
exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token is required' });
    }

    const jwt = require('jsonwebtoken');
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    } catch (jwtErr) {
      return res.status(401).json({ success: false, message: 'Expired or invalid refresh token' });
    }

    const user = await User.findOne({ _id: decoded.id, refreshToken });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    sendTokenResponse(user, 200, res, req);
  } catch (err) {
    next(err);
  }
};

// @desc    Forgot Password - Request OTP
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res, next) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ success: false, message: 'Please provide an email' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ success: false, message: 'No account found with this email' });
        }

        // Generate secure 6-digit OTP
        const otp = crypto.randomInt(100000, 999999).toString();

        // Delete any existing OTPs for this email to prevent reuse
        await OTP.deleteMany({ email: user.email, purpose: 'forgot_password' });

        // Save new OTP to DB (5 mins expiry)
        await OTP.create({
            email: user.email,
            otp: otp,
            purpose: 'forgot_password',
            expiresAt: Date.now() + 5 * 60 * 1000
        });

        // Send Email
        const emailSent = await emailService.sendOTP(user.email, otp);

        // Also send SMS as backup if configured
        sms.send({
            userId: user._id,
            phoneNumber: user.phoneNumber,
            templateKey: 'PASSWORD_OTP',
            args: [otp]
        });

        res.status(200).json({
            success: true,
            message: emailSent ? 'OTP sent to your email' : 'Failed to send email, please check your phone for SMS',
            otp: process.env.NODE_ENV === 'development' ? otp : undefined
        });
    } catch (err) {
        next(err);
    }
};

// @desc    Verify OTP and Reset Password
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res, next) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ success: false, message: 'Please provide email, OTP and new password' });
        }

        const otpRecord = await OTP.findOne({ email, otp, purpose: 'forgot_password' });
        if (!otpRecord) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Update password
        user.password = newPassword;
        user.loginAttempts = 0;
        user.lockUntil = undefined;
        await user.save();

        // Delete OTP immediately after use
        await OTP.deleteMany({ email, purpose: 'forgot_password' });

        res.status(200).json({ success: true, message: 'Password reset successful. You can now login with your new password.' });
    } catch (err) {
        next(err);
    }
};

// @desc    Verify Email OTP
// @route   POST /api/auth/verify-email
// @access  Private
exports.verifyEmail = async (req, res, next) => {
    try {
        const { otp } = req.body;
        const user = await User.findById(req.user.id);

        const otpRecord = await OTP.findOne({ email: user.email, otp, purpose: 'email_verification' });
        if (!otpRecord) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        user.isEmailVerified = true;
        await user.save();
        await OTP.deleteMany({ email: user.email, purpose: 'email_verification' });

        res.status(200).json({ success: true, message: 'Email verified successfully' });
    } catch (err) {
        next(err);
    }
};
