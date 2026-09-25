const Rating = require('../models/Rating');
const User = require('../models/User');
const Donation = require('../models/Donation');

// @desc    Rate a user
// @route   POST /api/ratings
// @access  Private
exports.createRating = async (req, res, next) => {
  try {
    const { donationId, toUserId, rating, review } = req.body;

    if (!donationId || !toUserId || !rating) {
      return res.status(400).json({ success: false, message: 'Donation ID, recipient user ID, and rating are required' });
    }

    const donation = await Donation.findById(donationId);
    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    if (donation.status !== 'completed') {
      return res.status(400).json({ success: false, message: 'Ratings can only be submitted for completed donations' });
    }

    const donorIdStr = donation.donorId?._id ? donation.donorId._id.toString() : donation.donorId?.toString();
    const assignedNgoIdStr = donation.assignedNgoId?._id ? donation.assignedNgoId._id.toString() : donation.assignedNgoId?.toString();
    const volunteerIdStr = donation.volunteerId?._id ? donation.volunteerId._id.toString() : donation.volunteerId?.toString();

    const isParty = (donorIdStr === req.user.id) || (assignedNgoIdStr === req.user.id) || (volunteerIdStr === req.user.id);
    if (!isParty && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to rate this donation' });
    }

    // Ensure toUserId is a legitimate counterparty and not self
    const validCounterparties = [donorIdStr, assignedNgoIdStr, volunteerIdStr].filter(Boolean);
    if (!validCounterparties.includes(toUserId.toString()) || toUserId.toString() === req.user.id) {
      return res.status(400).json({ success: false, message: 'Invalid rating recipient for this donation' });
    }

    const existingRating = await Rating.findOne({ donationId, fromUserId: req.user.id });
    if (existingRating) {
      return res.status(400).json({ success: false, message: 'You have already rated for this donation' });
    }

    const ratingDoc = await Rating.create({
      donationId,
      fromUserId: req.user.id,
      toUserId,
      rating,
      review
    });

    // Update recipient's average rating
    const user = await User.findById(toUserId);
    if (user) {
      const currentTotal = user.totalRatings || 0;
      const currentAvg = user.averageRating || 0;
      const newTotal = currentTotal + 1;
      const newAvg = ((currentAvg * currentTotal) + rating) / newTotal;

      await User.findByIdAndUpdate(toUserId, {
        averageRating: parseFloat(newAvg.toFixed(2)),
        totalRatings: newTotal
      });
    }

    res.status(201).json({
      success: true,
      data: ratingDoc,
    });
  } catch (err) {
    next(err);
  }
};
