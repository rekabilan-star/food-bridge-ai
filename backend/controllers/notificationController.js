const Notification = require('../models/Notification');
const User = require('../models/User');

// @desc    Get user notifications
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const startIndex = (page - 1) * limit;

    let query = { userId: req.user.id };

    // Filter by read/unread
    if (req.query.read !== undefined) {
      query.read = req.query.read === 'true';
    }

    // Filter by category
    if (req.query.category) {
      query.category = req.query.category;
    }

    // Filter by date range
    if (req.query.startDate && req.query.endDate) {
      query.createdAt = {
        $gte: new Date(req.query.startDate),
        $lte: new Date(req.query.endDate)
      };
    }

    // Search in title and body
    if (req.query.search) {
      query.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { body: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    const total = await Notification.countDocuments(query);
    const notifications = await Notification.find(query)
      .sort('-createdAt')
      .skip(startIndex)
      .limit(limit);

    const unreadCount = await Notification.countDocuments({ userId: req.user.id, read: false });

    res.status(200).json({
      success: true,
      count: notifications.length,
      unreadCount: unreadCount || 0,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit) || 1
      },
      notifications: notifications || []
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res, next) => {
  try {
    let notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    if (notification.userId.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized' });
    }

    notification.read = true;
    await notification.save();

    res.status(200).json({ success: true, notification });
  } catch (err) {
    next(err);
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private
exports.markAllRead = async (req, res, next) => {
  try {
    const result = await Notification.updateMany(
      { userId: req.user.id, read: false },
      { read: true }
    );

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
      updatedCount: result.modifiedCount || 0,
      unreadCount: 0
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res, next) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    if (notification.userId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this notification' });
    }

    await notification.deleteOne();

    res.status(200).json({ success: true, message: 'Notification deleted' });
  } catch (err) {
    next(err);
  }
};

// @desc    Delete all notifications
// @route   DELETE /api/notifications/delete-all
// @access  Private
exports.deleteAllNotifications = async (req, res, next) => {
  try {
    const result = await Notification.deleteMany({ userId: req.user.id });

    res.status(200).json({
      success: true,
      message: 'All notifications deleted',
      deletedCount: result.deletedCount || 0
    });
  } catch (err) {
    next(err);
  }
};
