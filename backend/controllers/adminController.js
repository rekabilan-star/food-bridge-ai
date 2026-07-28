const User = require('../models/User');
const Donation = require('../models/Donation');

// @desc    Get admin dashboard stats
// @route   GET /api/admin/dashboard
// @access  Private (Admin)
exports.getDashboardStats = async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const totalDonors = await User.countDocuments({ role: 'donor' });
    const totalNGOs = await User.countDocuments({ role: 'ngo' });
    const pendingNGOs = await User.countDocuments({ role: 'ngo', status: 'pending' });
    const activeDonations = await Donation.countDocuments({ status: { $in: ['waiting', 'accepted', 'on_the_way', 'arrived', 'picked_up'] } });
    const completedDonations = await Donation.countDocuments({ status: 'completed' });
    const todayDonations = await Donation.countDocuments({ createdAt: { $gte: today } });

    res.status(200).json({
      success: true,
      data: {
        totalDonors,
        totalNGOs,
        pendingNGOs,
        activeDonations,
        completedDonations,
        todayDonations,
      },
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all NGOs (with filter)
// @route   GET /api/admin/ngos
// @access  Private (Admin)
exports.getNGOs = async (req, res, next) => {
  try {
    const status = req.query.status;
    let query = { role: 'ngo' };
    if (status) query.status = status;

    const ngos = await User.find(query).sort('-createdAt');

    res.status(200).json({
      success: true,
      count: ngos.length,
      data: ngos,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Approve/Reject NGO
// @route   PUT /api/admin/ngos/:id/status
// @access  Private (Admin)
exports.updateNGOStatus = async (req, res, next) => {
  try {
    const { status } = req.body; // approved or rejected

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

    res.status(200).json({
      success: true,
      message: `NGO successfully ${status}`,
      data: ngo,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all donations
// @route   GET /api/admin/donations
// @access  Private (Admin)
exports.getAllDonations = async (req, res, next) => {
  try {
    const donations = await Donation.find()
      .populate('donorId', 'name phoneNumber')
      .populate('assignedNgoId', 'name phoneNumber')
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: donations.length,
      data: donations,
    });
  } catch (err) {
    next(err);
  }
};
