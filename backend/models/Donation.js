const mongoose = require('mongoose');

const TimelineSchema = new mongoose.Schema({
  status: String,
  time: { type: Date, default: Date.now },
  description: String,
});

const FoodItemSchema = new mongoose.Schema({
  foodName: { type: String, required: true },
  category: { type: String, required: true },
  membersServed: { type: Number, required: true },
});

const DonationSchema = new mongoose.Schema({
  donorId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  // Feature 1: Multiple Food Items
  items: [FoodItemSchema],

  // Keep these for backward compatibility or as summary fields
  foodName: String,
  category: String,
  membersServed: Number,

  imageUrl: {
    type: String,
  },

  // Feature 2: Quality Checklist
  checklist: {
    isFreshlyPrepared: { type: Boolean, default: false },
    isProperlyPacked: { type: Boolean, default: false },
    foodType: { type: String, enum: ['Veg', 'Non-Veg', 'Both'], default: 'Veg' },
    hasAllergens: { type: Boolean, default: false },
  },

  preparedTime: {
    type: Date,
    required: true,
  },
  bestBeforeTime: {
    type: Date,
    required: true,
  },

  // Feature 3: Donation Scheduling
  isScheduled: { type: Boolean, default: false },
  scheduledTimestamp: { type: Date },

  pickupAddress: {
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
  specialInstructions: String,
  status: {
    type: String,
    enum: [
      'waiting',
      'accepted',
      'on_the_way',
      'arrived',
      'picked_up',
      'delivered',
      'completed',
      'cancelled',
      'rejected',
    ],
    default: 'waiting',
  },
  assignedNgoId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
  },
  volunteerId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
  },
  qrCode: {
    type: String,
    unique: true,
    sparse: true,
  },
  timeline: [TimelineSchema],

  // Feature 6: Donation Cancellation
  cancellation: {
    cancelledBy: { type: mongoose.Schema.ObjectId, ref: 'User' },
    reason: String,
    time: Date,
  },

  // Delivery Confirmation Details
  deliveryDetails: {
    photoUrl: String,
    signatureUrl: String,
    receiverName: String,
    location: {
      address: String,
      latitude: Number,
      longitude: Number,
    },
    membersServed: Number,
    notes: String,
    completedAt: Date,
  },

  createdAt: {
    type: Date,
    default: Date.now,
  },
});

DonationSchema.pre('save', function (next) {
  if (this.isNew) {
    this.timeline.push({
      status: 'waiting',
      description: 'Donation submitted and waiting for NGO acceptance.',
    });
    this.qrCode = `QR-${this._id}-${Math.random().toString(36).substr(2, 9)}`;

    // Summary fields update if items exist
    if (this.items && this.items.length > 0) {
      this.foodName = this.items[0].foodName + (this.items.length > 1 ? ` +${this.items.length - 1} more` : '');
      this.category = this.items[0].category;
      this.membersServed = this.items.reduce((sum, item) => sum + item.membersServed, 0);
    }
  }
  next();
});

module.exports = mongoose.model('Donation', DonationSchema);
