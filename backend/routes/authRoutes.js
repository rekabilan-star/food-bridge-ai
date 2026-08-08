const express = require('express');
const { check } = require('express-validator');
const { validate } = require('../middleware/validationMiddleware');
const {
  registerDonor,
  registerNgo,
  login,
  getMe,
  refreshToken,
  forgotPassword,
  resetPassword,
  verifyEmail
} = require('../controllers/authController');

const router = express.Router();

const { protect } = require('../middleware/authMiddleware');

router.post('/register/donor', [
    check('name', 'Name is required').not().isEmpty(),
    check('email', 'Please include a valid email').isEmail(),
    check('password', 'Please enter a password with 6 or more characters').isLength({ min: 6 }),
    check('phoneNumber', 'Phone number is required').not().isEmpty(),
    check('latitude', 'Latitude is required').isFloat(),
    check('longitude', 'Longitude is required').isFloat(),
    validate
], registerDonor);

router.post('/register/ngo', [
    check('name', 'NGO Name is required').not().isEmpty(),
    check('email', 'Please include a valid email').isEmail(),
    check('password', 'Please enter a password with 6 or more characters').isLength({ min: 6 }),
    check('phoneNumber', 'Phone number is required').not().isEmpty(),
    check('ngoRegistrationNumber', 'Registration number is required').not().isEmpty(),
    check('latitude', 'Latitude is required').isFloat(),
    check('longitude', 'Longitude is required').isFloat(),
    validate
], registerNgo);

router.post('/login', [
    check('email', 'Please include a valid email').isEmail(),
    check('password', 'Password is required').exists(),
    validate
], login);

router.post('/refresh-token', refreshToken);

router.post('/forgot-password', [
    check('email', 'Please include a valid email').isEmail(),
    validate
], forgotPassword);

router.post('/reset-password', [
    check('email', 'Please include a valid email').isEmail(),
    check('otp', '6-digit OTP is required').isLength({ min: 6, max: 6 }),
    check('newPassword', 'Please enter a password with 6 or more characters').isLength({ min: 6 }),
    validate
], resetPassword);

router.get('/me', protect, getMe);
router.post('/verify-email', protect, verifyEmail);

module.exports = router;
