const User = require('../models/User');
const Donation = require('../models/Donation');
const { notify } = require('../services/notificationService');

// @desc    Get admin dashboard stats with advanced analytics
// @route   GET /api/admin/dashboard
// @access  Private (Admin)
exports.getDashboardStats = async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // 1. Basic Counts
    const totalDonors = await User.countDocuments({ role: 'donor' });
    const totalNGOs = await User.countDocuments({ role: 'ngo' });
    const pendingNGOs = await User.countDocuments({ role: 'ngo', status: 'pending' });

    // Status distribution
    const statusCounts = await Donation.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    const activeDonations = await Donation.countDocuments({ status: { $in: ['waiting', 'accepted', 'on_the_way', 'arrived', 'picked_up'] } });
    const completedDonations = await Donation.countDocuments({ status: 'completed' });
    const todayDonations = await Donation.countDocuments({ createdAt: { $gte: today } });

    // 2. Impact Analytics
    const impactStats = await Donation.aggregate([
      { $match: { status: 'completed' } },
      { $group: {
          _id: null,
          totalMembersServed: { $sum: '$deliveryDetails.membersServed' },
          foodSavedKg: { $sum: { $multiply: ['$deliveryDetails.membersServed', 0.5] } }
      }}
    ]);

    const impact = impactStats[0] || { totalMembersServed: 0, foodSavedKg: 0 };
    const co2Saved = (impact.foodSavedKg * 2.5).toFixed(2);

    // 3. Chart Data: Daily Donations (Last 7 Days)
    const dailyDonations = await Donation.aggregate([
      { $match: { createdAt: { $gte: sevenDaysAgo } } },
      { $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          count: { $sum: 1 }
      }},
      { $sort: { _id: 1 } }
    ]);

    // 4. Category Distribution
    const categoryStats = await Donation.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);

    // 5. Recent Activity Feed
    const recentActivity = await Donation.find()
      .sort('-createdAt')
      .limit(8)
      .populate('donorId', 'name')
      .populate('assignedNgoId', 'name');

    res.status(200).json({
      success: true,
      data: {
        counts: {
          totalDonors,
          totalNGOs,
          pendingNGOs,
          activeDonations,
          completedDonations,
          todayDonations,
          statusDistribution: statusCounts
        },
        impact: {
          membersServed: impact.totalMembersServed,
          mealsServed: impact.totalMembersServed,
          foodSavedKg: impact.foodSavedKg,
          co2Saved
        },
        charts: {
          dailyDonations,
          categories: categoryStats
        },
        recentActivity
      },
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all users with search, filter, pagination
// @route   GET /api/admin/users
// @access  Private (Admin)
exports.getUsers = async (req, res, next) => {
    try {
        const { role, status, search, page = 1, limit = 10 } = req.query;
        const query = { role: { $ne: 'admin' } };

        if (role) query.role = role;
        if (status) query.status = status;
        if (search) {
            query.$or = [
                { name: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } },
                { phoneNumber: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (page - 1) * limit;
        const total = await User.countDocuments(query);
        const users = await User.find(query)
            .select('-password')
            .sort('-createdAt')
            .skip(skip)
            .limit(parseInt(limit));

        res.status(200).json({
            success: true,
            count: users.length,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            },
            data: users
        });
    } catch (err) {
        next(err);
    }
};

// @desc    Get all NGOs (reusing getUsers or specialized)
exports.getNGOs = async (req, res, next) => {
    req.query.role = 'ngo';
    return this.getUsers(req, res, next);
};

// @desc    Approve/Reject NGO
// @route   PUT /api/admin/ngos/:id/status
// @access  Private (Admin)
exports.updateNGOStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const ngo = await User.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!ngo) {
      return res.status(404).json({ success: false, message: 'NGO not found' });
    }

    notify({
        userId: ngo._id,
        title: status === 'approved' ? 'Account Approved! 🎊' : 'Account Rejected ⚠️',
        body: status === 'approved'
            ? 'Your NGO account has been verified. You can now start accepting donations.'
            : 'We could not verify your NGO account at this time. Please check your details or contact support.',
        category: 'PROFILE',
        priority: 'high'
    });

    res.status(200).json({ success: true, message: `NGO successfully ${status}`, data: ngo });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all donations with search, filter, pagination
// @route   GET /api/admin/donations
// @access  Private (Admin)
exports.getAllDonations = async (req, res, next) => {
    try {
        const { status, category, search, page = 1, limit = 10 } = req.query;
        const query = {};

        if (status) query.status = status;
        if (category) query.category = category;
        if (search) {
            query.$or = [
                { foodName: { $regex: search, $options: 'i' } },
                { pickupAddress: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (page - 1) * limit;
        const total = await Donation.countDocuments(query);
        const donations = await Donation.find(query)
            .populate('donorId', 'name phoneNumber')
            .populate('assignedNgoId', 'name phoneNumber')
            .sort('-createdAt')
            .skip(skip)
            .limit(parseInt(limit));

        res.status(200).json({
            success: true,
            count: donations.length,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            },
            data: donations
        });
    } catch (err) {
        next(err);
    }
};

// @desc    Get system-wide reports for export
// @route   GET /api/admin/reports/donations
// @access  Private (Admin)
exports.getDonationReport = async (req, res, next) => {
    try {
        const { startDate, endDate } = req.query;
        const query = {};

        if (startDate && endDate) {
            query.createdAt = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        }

        const donations = await Donation.find(query)
            .populate('donorId', 'name email phoneNumber')
            .populate('assignedNgoId', 'name email phoneNumber')
            .sort('-createdAt');

        // Note: Formatting for CSV/Excel can happen here or on client
        res.status(200).json({ success: true, count: donations.length, data: donations });
    } catch (err) {
        next(err);
    }
};

// @desc    Send Announcement
exports.sendAnnouncement = async (req, res, next) => {
    try {
      const { title, body, priority } = req.body;
      const users = await User.find({ status: 'approved' });

      users.forEach(user => {
          notify({
              userId: user._id,
              title: `📢 ${title}`,
              body,
              category: 'ANNOUNCEMENT',
              priority: priority || 'medium'
          });
      });

      res.status(200).json({ success: true, message: 'Announcement sent to all users' });
    } catch (err) {
      next(err);
    }
};
