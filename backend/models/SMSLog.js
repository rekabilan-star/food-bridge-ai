const mongoose = require('mongoose');

const SMSLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
  },
  phoneNumber: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  provider: {
    type: String,
    enum: ['Twilio', 'Fast2SMS', 'MSG91'],
    required: true,
  },
  status: {
    type: String,
    enum: ['sent', 'failed', 'delivered'],
    default: 'sent',
  },
  templateName: String,
  error: String,
  retryCount: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

SMSLogSchema.index({ phoneNumber: 1, createdAt: -1 });
SMSLogSchema.index({ status: 1 });

module.exports = mongoose.model('SMSLog', SMSLogSchema);
