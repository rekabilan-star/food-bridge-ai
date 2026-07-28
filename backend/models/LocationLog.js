const mongoose = require('mongoose');

const LocationLogSchema = new mongoose.Schema({
  donationId: {
    type: mongoose.Schema.ObjectId,
    ref: 'Donation',
    required: true,
  },
  volunteerId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
    },
  },
  accuracy: Number,
  speed: Number,
  heading: Number,
  timestamp: {
    type: Date,
    default: Date.now,
  },
});

LocationLogSchema.index({ location: '2dsphere' });
LocationLogSchema.index({ donationId: 1, timestamp: -1 });

module.exports = mongoose.model('LocationLog', LocationLogSchema);
