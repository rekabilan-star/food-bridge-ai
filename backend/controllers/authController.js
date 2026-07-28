const User = require('../models/User');

exports.registerDonor = async (req, res, next) => {
  try {
    const { name, email, password, phoneNumber, address, latitude, longitude } = req.body;
    const user = await User.create({
      name, email, password, phoneNumber, address, latitude, longitude, role: 'donor',
    });
    sendTokenResponse(user, 201, res);
  } catch (err) {
    next(err);
  }
};

exports.registerNgo = async (req, res, next) => {
  try {
    const { name, email, password, phoneNumber, address, latitude, longitude, ngoRegistrationNumber } = req.body;
    const user = await User.create({
      name, email, password, phoneNumber, address, latitude, longitude, ngoRegistrationNumber, role: 'ngo', status: 'pending',
    });
    sendTokenResponse(user, 201, res);
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide an email and password' });
    }
    const user = await User.findOne({ email }).select('+password');
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    sendTokenResponse(user, 200, res);
  } catch (err) {
    next(err);
  }
};

const sendTokenResponse = async (user, statusCode, res) => {
  const token = user.getSignedJwtToken();
  const refreshToken = user.getRefreshToken();

  await user.save({ validateBeforeSave: false });

  res.status(statusCode).json({
    success: true,
    token,
    refreshToken,
    user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        phoneNumber: user.phoneNumber,
        address: user.address,
        status: user.status
    }
  });
};

exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token is required' });
    }

    const user = await User.findOne({ refreshToken });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    sendTokenResponse(user, 200, res);
  } catch (err) {
    next(err);
  }
};
