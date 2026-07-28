const express = require('express');
const {
  getDashboardStats,
  getNGOs,
  updateNGOStatus,
  getAllDonations,
} = require('../controllers/adminController');

const router = express.Router();

const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);
router.use(authorize('admin'));

router.get('/dashboard', getDashboardStats);
router.get('/ngos', getNGOs);
router.put('/ngos/:id/status', updateNGOStatus);
router.get('/donations', getAllDonations);

module.exports = router;
