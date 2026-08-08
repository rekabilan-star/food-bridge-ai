const express = require('express');
const {
  getDashboardStats,
  getUsers,
  getNGOs,
  updateNGOStatus,
  getAllDonations,
  getDonationReport,
  sendAnnouncement
} = require('../controllers/adminController');
const { getSMSLogs, getSMSStats } = require('../controllers/smsController');

const router = express.Router();

const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);
router.use(authorize('admin'));

router.get('/dashboard', getDashboardStats);
router.get('/users', getUsers);
router.get('/ngos', getNGOs);
router.put('/ngos/:id/status', updateNGOStatus);
router.get('/donations', getAllDonations);
router.get('/reports/donations', getDonationReport);
router.post('/announcement', sendAnnouncement);

// SMS Routes
router.get('/sms-logs', getSMSLogs);
router.get('/sms-stats', getSMSStats);

module.exports = router;
