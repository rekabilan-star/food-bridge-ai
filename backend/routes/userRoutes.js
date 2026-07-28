const express = require('express');
const { getProfile, updateProfile, getImpactAnalytics, updateAvailability } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.put('/availability', updateAvailability);
router.get('/impact', getImpactAnalytics);

module.exports = router;
