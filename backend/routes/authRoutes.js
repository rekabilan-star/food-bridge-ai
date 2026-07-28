const express = require('express');
const { check } = require('express-validator');
const { registerDonor, registerNgo, login, getMe, refreshToken } = require('../controllers/authController');
const { validate } = require('../middleware/validationMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/register/donor', [
    check('name', 'Name is required').not().isEmpty(),
    check('email', 'Please include a valid email').isEmail(),
    check('password', 'Please enter a password with 6 or more characters').isLength({ min: 6 }),
    check('phoneNumber', 'Phone number is required').not().isEmpty(),
], validate, registerDonor);

router.post('/register/ngo', [
    check('name', 'Name is required').not().isEmpty(),
    check('email', 'Please include a valid email').isEmail(),
    check('password', 'Please enter a password with 6 or more characters').isLength({ min: 6 }),
    check('phoneNumber', 'Phone number is required').not().isEmpty(),
    check('ngoRegistrationNumber', 'NGO registration number is required').not().isEmpty(),
], validate, registerNgo);

router.post('/login', [
    check('email', 'Please include a valid email').isEmail(),
    check('password', 'Password is required').exists(),
], validate, login);

router.post('/refresh-token', refreshToken);

router.get('/me', protect, getMe);

module.exports = router;
