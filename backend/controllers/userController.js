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
    const fieldsToUpdate = {
      name: req.body.name,
      phoneNumber: req.body.phoneNumber,
      address: req.body.address,
      profileImage: req.body.profileImage,
      currentLatitude: req.body.currentLatitude,
      currentLongitude: req.body.currentLongitude
    };

    // Remove undefined fields
    Object.keys(fieldsToUpdate).forEach(key => fieldsToUpdate[key] === undefined && delete fieldsToUpdate[key]);

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, { new: true, runValidators: true });
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
    const isNGO = req.user.role === 'ngo';
    const filter = isNGO ? { assignedNgoId: req.user.id } : { donorId: req.user.id };

    const donations = await Donation.find({ ...filter, status: 'completed' });

    const totalDonations = donations.length;
    const mealsProvided = donations.reduce((acc, d) => acc + (d.deliveryDetails?.membersServed || d.membersServed || 0), 0);
    const totalWeightSaved = mealsProvided * 0.5; // 0.5kg per meal

    // Charts: Monthly distribution
    const monthlyStats = await Donation.aggregate([
      { $match: { ...filter, status: 'completed' } },
      { $group: {
          _id: { $month: "$createdAt" },
          count: { $sum: 1 },
          meals: { $sum: { $ifNull: ["$deliveryDetails.membersServed", "$membersServed"] } }
      }},
      { $sort: { "_id": 1 } }
    ]);

    // Category distribution
    const categoryStats = await Donation.aggregate([
      { $match: { ...filter, status: 'completed' } },
      { $group: {
          _id: "$category",
          count: { $sum: 1 }
      }}
    ]);

    // NGO Specific metrics
    let ngoMetrics = {};
    if (isNGO) {
        const allAssigned = await Donation.countDocuments({ assignedNgoId: req.user.id });
        const pending = await Donation.countDocuments({ assignedNgoId: req.user.id, status: { $in: ['accepted', 'on_the_way', 'arrived', 'picked_up'] } });

        // Average pickup time (Accepted -> Picked Up)
        const times = donations.filter(d => {
            const accepted = d.timeline.find(t => t.status === 'accepted');
            const picked = d.timeline.find(t => t.status === 'picked_up');
            return accepted && picked;
        }).map(d => {
            const accepted = d.timeline.find(t => t.status === 'accepted').time;
            const picked = d.timeline.find(t => t.status === 'picked_up').time;
            return (new Date(picked) - new Date(accepted)) / (1000 * 60); // minutes
        });

        const avgPickupTime = times.length > 0 ? (times.reduce((a, b) => a + b, 0) / times.length).toFixed(1) : 0;

        ngoMetrics = {
            pending,
            allAssigned,
            completionRate: allAssigned > 0 ? ((totalDonations / allAssigned) * 100).toFixed(1) : 0,
            avgPickupTime
        };
    }

    res.status(200).json({
      success: true,
      data: {
        totalDonations,
        totalWeightSaved,
        mealsProvided,
        co2Reduction: totalWeightSaved * 2.5,
        waterSaved: totalWeightSaved * 50,
        charts: {
            monthly: monthlyStats,
            categories: categoryStats
        },
        ngoMetrics: isNGO ? ngoMetrics : undefined
      },
    });
  } catch (err) {
    next(err);
  }
};
