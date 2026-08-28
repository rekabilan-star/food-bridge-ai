const Notification = require('../models/Notification');
const User = require('../models/User');

/**
 * Send a notification to a user via DB and Socket.IO (FCM REMOVED)
 * @param {Object} options
 * @param {string} options.userId - Target user ID
 * @param {string} options.title - Notification title
 * @param {string} options.body - Notification body
 * @param {string} options.category - DONATION, CHAT, etc.
 * @param {string} options.priority - low, medium, high
 * @param {Object} options.data - Metadata for deep linking
 */
exports.notify = async (options) => {
  try {
    const { userId, title, body, category, priority, data } = options;

    // 1. Save to Database for history
    const notification = await Notification.create({
      userId,
      title,
      body,
      category: category || 'SYSTEM',
      priority: priority || 'medium',
      data: data || {}
    });

    // 2. Emit via Socket.io for Real-time in-app alerts
    if (global.io) {
      // Send the full notification object
      global.io.to(userId.toString()).emit('new_notification', notification);

      // Also update unread count for badge
      const unreadCount = await Notification.countDocuments({ userId, read: false });
      global.io.to(userId.toString()).emit('unread_count_update', { unreadCount });
    }

    return notification;
  } catch (err) {
    console.error('Notification Service Error:', err);
  }
};

/**
 * Check for donations expiring soon and notify NGOs via Socket.IO
 */
exports.checkExpiringDonations = async () => {
    try {
        const Donation = require('../models/Donation');
        const now = new Date();
        const twoHoursLater = new Date(now.getTime() + 2 * 60 * 60 * 1000);

        const expiringSoon = await Donation.find({
            status: 'waiting',
            bestBeforeTime: { $gte: now, $lte: twoHoursLater },
            expiryNotified: { $ne: true }
        });

        for (const donation of expiringSoon) {
            // Notify only approved NGOs within 20 KM
            let eligibleNgos = [];
            if (donation.latitude && donation.longitude) {
                try {
                    eligibleNgos = await User.aggregate([
                        {
                            $geoNear: {
                                near: {
                                    type: "Point",
                                    coordinates: [parseFloat(donation.longitude), parseFloat(donation.latitude)]
                                },
                                distanceField: "distance",
                                maxDistance: 20000, // 20 km in meters (boundary <= 20 KM)
                                query: {
                                    role: 'ngo',
                                    status: 'approved'
                                },
                                spherical: true
                            }
                        }
                    ]);
                } catch (geoErr) {
                    console.error('Geo query error in checkExpiringDonations:', geoErr);
                }
            }

            for (const ngo of eligibleNgos) {
                await this.notify({
                    userId: ngo._id,
                    title: 'Urgent: Food Expiring Soon! ⏰',
                    body: `${donation.foodName} will expire in less than 2 hours. Please rescue it now!`,
                    category: 'DONATION',
                    priority: 'high',
                    data: { donationId: donation._id.toString() }
                });
            }
            donation.expiryNotified = true;
            await donation.save();
        }
    } catch (err) {
        console.error('Expiry Check Error:', err);
    }
};
