const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  chatId: {
    type: mongoose.Schema.ObjectId,
    ref: 'Chat',
    required: true,
  },
  senderId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  receiverId: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true,
  },
  text: {
    type: String,
  },
  messageType: {
    type: String,
    enum: ['text', 'image', 'pdf', 'audio', 'location'],
    default: 'text',
  },
  fileUrl: String,
  fileName: String,

  // Status
  status: {
    type: String,
    enum: ['sent', 'delivered', 'seen'],
    default: 'sent',
  },

  // Reply feature
  replyTo: {
    type: mongoose.Schema.ObjectId,
    ref: 'Message',
  },

  // Edit/Delete feature
  isEdited: {
    type: Boolean,
    default: false,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  deletedFor: [{
    type: mongoose.Schema.ObjectId,
    ref: 'User'
  }],

  createdAt: {
    type: Date,
    default: Date.now,
  },
});

MessageSchema.index({ chatId: 1, createdAt: -1 });

module.exports = mongoose.model('Message', MessageSchema);
