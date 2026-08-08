const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema({
  participants: [{
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  }],
  donationId: {
    type: mongoose.Schema.ObjectId,
    ref: 'Donation',
  },
  lastMessage: {
    type: mongoose.Schema.ObjectId,
    ref: 'Message',
  },
  unreadCounts: {
    type: Map,
    of: Number,
    default: {}
  },
  pinnedBy: [{
    type: mongoose.Schema.ObjectId,
    ref: 'User'
  }],
  isDeleted: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  }
});

ChatSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

ChatSchema.index({ participants: 1 });
ChatSchema.index({ updatedAt: -1 });

module.exports = mongoose.model('Chat', ChatSchema);
