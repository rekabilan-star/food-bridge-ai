const Rating = require('../models/Rating');
const User = require('../models/User');

// @desc    Rate a user
// @route   POST /api/ratings
// @access  Private
exports.createRating = async (req, res, next) => {
  try {
    const { donationId, toUserId, rating, review } = req.body;

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
    const totalRatings = user.totalRatings + 1;
    const averageRating = ((user.averageRating * user.totalRatings) + rating) / totalRatings;

    await User.findByIdAndUpdate(toUserId, {
      averageRating,
      totalRatings
    });

    res.status(201).json({
      success: true,
      data: ratingDoc,
    });
  } catch (err) {
    next(err);
  }
};
