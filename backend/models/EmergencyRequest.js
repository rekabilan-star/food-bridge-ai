const mongoose = require('mongoose');

const EmergencyRequestSchema = new mongoose.Schema({
  ngoId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: [true, 'Please add a title'],
  },
  reason: {
    type: String,
    required: [true, 'Please add a reason'],
  },
  requiredMembers: {
    type: Number,
    required: [true, 'Please specify how many people need food'],
  },
  foodType: {
    type: String,
    enum: ['Veg', 'Non-Veg', 'Any'],
    default: 'Any',
  },
  address: {
    type: String,
    required: true,
  },
  latitude: {
    type: Number,
    required: true,
  },
  longitude: {
    type: Number,
    required: true,
  },
  requiredBefore: {
    type: Date,
    required: true,
  },
  priority: {
    type: String,
    enum: ['High', 'Medium', 'Low'],
    default: 'Medium',
  },
  status: {
    type: String,
    enum: ['active', 'fulfilled', 'expired', 'cancelled'],
    default: 'active',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('EmergencyRequest', EmergencyRequestSchema);
