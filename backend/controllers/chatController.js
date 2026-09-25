const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');
const { notify } = require('../services/notificationService');

// @desc    Get or Create Chat
// @route   POST /api/chat
// @access  Private
exports.getOrCreateChat = async (req, res, next) => {
  try {
    const { receiverId, donationId } = req.body;

    if (!receiverId) {
      return res.status(400).json({ success: false, message: 'Receiver ID is required' });
    }

    let query = {
      participants: { $all: [req.user.id, receiverId] }
    };

    if (donationId) {
      const Donation = require('../models/Donation');
      const donation = await Donation.findById(donationId);
      if (donation) {
        const isDonor = donation.donorId && donation.donorId.toString() === req.user.id;
        const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
        const isVolunteer = donation.volunteerId && donation.volunteerId.toString() === req.user.id;
        if (!isDonor && !isAssignedNgo && !isVolunteer && req.user.role !== 'admin') {
          return res.status(403).json({ success: false, message: 'Not authorized to initiate chat for this donation' });
        }
      }
      query.donationId = donationId;
    }

    let chat = await Chat.findOne(query)
      .populate('participants', 'name profileImage lastLocationUpdate role')
      .populate('lastMessage');

    if (!chat) {
      chat = await Chat.create({
        participants: [req.user.id, receiverId],
        donationId: donationId || null,
        unreadCounts: new Map([[req.user.id, 0], [receiverId, 0]])
      });
      chat = await chat.populate('participants', 'name profileImage lastLocationUpdate role');
    }

    res.status(200).json({
      success: true,
      data: chat,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get Chat Messages with Pagination
// @route   GET /api/chat/:id/messages
// @access  Private
exports.getChatMessages = async (req, res, next) => {
  try {
    const chat = await Chat.findById(req.params.id);
    if (!chat) {
      return res.status(404).json({ success: false, message: 'Chat not found' });
    }

    const isParticipant = chat.participants.some(p => p.toString() === req.user.id);
    if (!isParticipant && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to view messages in this chat' });
    }

    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 30;
    const startIndex = (page - 1) * limit;

    const messages = await Message.find({
      chatId: req.params.id,
      deletedFor: { $ne: req.user.id }
    })
    .sort('-createdAt')
    .skip(startIndex)
    .limit(limit)
    .populate('replyTo');

    // Reset unread count for this user
    await Chat.findByIdAndUpdate(req.params.id, {
      [`unreadCounts.${req.user.id}`]: 0
    });

    res.status(200).json({
      success: true,
      count: messages.length,
      data: messages,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Send Message
// @route   POST /api/chat/:id/messages
// @access  Private
exports.sendMessage = async (req, res, next) => {
  try {
    const { text, receiverId, messageType, fileUrl, fileName, replyTo } = req.body;
    const chatId = req.params.id;

    if (!receiverId) {
      return res.status(400).json({ success: false, message: 'Receiver ID is required' });
    }

    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ success: false, message: 'Chat not found' });
    }

    const isParticipant = chat.participants.some(p => p.toString() === req.user.id);
    if (!isParticipant && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to send messages in this chat' });
    }

    // Duplicate message prevention: same sender, same chat, same text within last 2 seconds
    const twoSecondsAgo = new Date(Date.now() - 2000);
    const isDuplicate = await Message.findOne({
        chatId,
        senderId: req.user.id,
        text,
        createdAt: { $gte: twoSecondsAgo }
    });

    if (isDuplicate) {
        return res.status(200).json({ success: true, data: isDuplicate });
    }

    const newMessage = await Message.create({
      chatId,
      senderId: req.user.id,
      receiverId,
      text,
      messageType: messageType || 'text',
      fileUrl,
      fileName,
      replyTo,
      status: 'sent'
    });

    // Update Chat last message and unread count
    chat.lastMessage = newMessage._id;
    if (!chat.unreadCounts) chat.unreadCounts = new Map();
    const currentUnread = chat.unreadCounts.get(receiverId.toString()) || 0;
    chat.unreadCounts.set(receiverId.toString(), currentUnread + 1);
    await chat.save();

    // Broadcast via Socket.io if available
    if (global.io) {
        global.io.to(`chat_${chatId}`).emit('new_message', newMessage);
        global.io.to(receiverId.toString()).emit('chat_update', { chatId });
    }

    // Notify via history
    notify({
      userId: receiverId,
      title: `Message from ${req.user.name} 💬`,
      body: messageType === 'text' ? text : `Sent you an ${messageType}`,
      category: 'CHAT',
      priority: 'medium',
      data: {
        chatId: chatId.toString(),
        type: 'CHAT_MESSAGE'
      }
    });

    res.status(201).json({
      success: true,
      data: newMessage,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get User Chats
// @route   GET /api/chat
// @access  Private
exports.getUserChats = async (req, res, next) => {
  try {
    const chats = await Chat.find({
        participants: req.user.id,
        isDeleted: { $ne: true }
    })
      .populate('participants', 'name profileImage role lastLocationUpdate')
      .populate('donationId', 'foodName status')
      .populate('lastMessage')
      .sort('-updatedAt');

    res.status(200).json({
      success: true,
      data: chats,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Update Message Status (Delivered/Seen)
// @route   PUT /api/chat/messages/:id/status
// @access  Private
exports.updateMessageStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const message = await Message.findByIdAndUpdate(req.params.id, { status }, { new: true });

    if (message && global.io) {
        global.io.to(`chat_${message.chatId}`).emit('message_status_update', {
            messageId: message._id,
            status: message.status
        });
    }

    res.status(200).json({
      success: true,
      data: message,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Edit Message
// @route   PUT /api/chat/messages/:id
// @access  Private
exports.editMessage = async (req, res, next) => {
  try {
    const { text } = req.body;
    const message = await Message.findById(req.params.id);

    if (!message || message.senderId.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized' });
    }

    message.text = text;
    message.isEdited = true;
    await message.save();

    res.status(200).json({
      success: true,
      data: message,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Delete Message
// @route   DELETE /api/chat/messages/:id
// @access  Private
exports.deleteMessage = async (req, res, next) => {
  try {
    const { deleteForEveryone } = req.query;
    const message = await Message.findById(req.params.id);

    if (!message) {
      return res.status(404).json({ success: false, message: 'Message not found' });
    }

    if (deleteForEveryone === 'true') {
      if (message.senderId.toString() !== req.user.id) {
        return res.status(401).json({ success: false, message: 'Not authorized to delete for everyone' });
      }
      message.isDeleted = true;
      message.text = 'This message was deleted';
      await message.save();
    } else {
      // Delete only for this user
      if (!message.deletedFor.includes(req.user.id)) {
        message.deletedFor.push(req.user.id);
        await message.save();
      }
    }

    res.status(200).json({
      success: true,
      message: 'Message deleted',
    });
  } catch (err) {
    next(err);
  }
};
