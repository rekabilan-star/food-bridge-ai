const express = require('express');
const {
  getNotifications,
  markAsRead,
  markAllRead,
  deleteNotification,
  deleteAllNotifications
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect); // All notification routes are protected

router.get('/', getNotifications);
router.put('/read-all', markAllRead);
router.delete('/delete-all', deleteAllNotifications);
router.put('/:id/read', markAsRead);
router.delete('/:id', deleteNotification);

module.exports = router;
