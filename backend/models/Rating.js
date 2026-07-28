const mongoose = require('mongoose');

const RatingSchema = new mongoose.Schema({
  donationId: {
    type: mongoose.Schema.ObjectId,
    ref: 'Donation',
    required: true,
  },
  fromUserId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  toUserId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5,
  },
  review: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Rating', RatingSchema);
