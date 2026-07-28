const User = require('../models/User');
const Donation = require('../models/Donation');

exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(req.user.id, req.body, { new: true, runValidators: true });
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

exports.updateAvailability = async (req, res, next) => {
  try {
    const { availabilityStatus } = req.body;
    const user = await User.findByIdAndUpdate(req.user.id, { availabilityStatus }, { new: true });
    res.status(200).json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

exports.getImpactAnalytics = async (req, res, next) => {
  try {
    const donations = await Donation.find({ donorId: req.user.id, status: 'completed' });
    let totalWeight = 0;
    donations.forEach(d => { totalWeight += (d.membersServed * 0.5); });
    res.status(200).json({
      success: true,
      data: {
        totalDonations: donations.length,
        totalWeightSaved: totalWeight,
        mealsProvided: donations.reduce((acc, d) => acc + d.membersServed, 0),
        co2Reduction: totalWeight * 2.5,
        waterSaved: totalWeight * 50,
      },
    });
  } catch (err) {
    next(err);
  }
};
