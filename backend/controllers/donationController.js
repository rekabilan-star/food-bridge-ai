const Donation = require('../models/Donation');
const User = require('../models/User');
const { recommendNgos } = require('../services/aiMatchingService');
const { optimizeRoute } = require('../services/routeOptimizationService');
const { notify } = require('../services/notificationService');
const sms = require('../services/smsService');

// @desc    Get optimized route for volunteer
// @route   GET /api/donations/volunteer/route
// @access  Private (Volunteer)
exports.getVolunteerRoute = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.query; // Current volunteer location

    if (!latitude || !longitude) {
        return res.status(400).json({ success: false, message: 'Current location is required' });
    }

    const donations = await Donation.find({
      volunteerId: req.user.id,
      status: { $in: ['accepted', 'on_the_way', 'arrived', 'picked_up'] }
    }).populate('donorId', 'name phoneNumber latitude longitude');

    const tasks = donations.map(d => ({
      id: d._id,
      type: d.status === 'picked_up' ? 'delivery' : 'pickup',
      latitude: d.status === 'picked_up' ? d.assignedNgoId?.latitude || d.latitude : d.latitude,
      longitude: d.status === 'picked_up' ? d.assignedNgoId?.longitude || d.longitude : d.longitude,
      bestBeforeTime: d.bestBeforeTime,
      foodName: d.foodName,
      address: d.pickupAddress
    }));

    const optimizedTasks = optimizeRoute({ latitude: parseFloat(latitude), longitude: parseFloat(longitude) }, tasks);

    res.status(200).json({ success: true, count: optimizedTasks.length, tasks: optimizedTasks });
  } catch (err) {
    next(err);
  }
};

// @desc    Get AI Recommended NGOs for a donation
// @route   GET /api/donations/:id/recommendations
// @access  Private (Donor/Admin)
exports.getDonationRecommendations = async (req, res, next) => {
  try {
    const donation = await Donation.findById(req.params.id);
    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    const recommendations = await recommendNgos(donation);
    res.status(200).json({ success: true, recommendations });
  } catch (err) {
    next(err);
  }
};

// @desc    Create new donation
// @route   POST /api/donations
// @access  Private (Donor)
exports.createDonation = async (req, res, next) => {
  try {
    req.body.donorId = req.user.id;

    // Duplicate Check: Same donor, same primary food name, same pickup address within last 30 mins
    const thirtyMinsAgo = new Date(Date.now() - 30 * 60 * 1000);
    const potentialDuplicate = await Donation.findOne({
      donorId: req.user.id,
      foodName: req.body.foodName || (req.body.items && req.body.items[0]?.foodName),
      pickupAddress: req.body.pickupAddress,
      createdAt: { $gte: thirtyMinsAgo },
      status: { $ne: 'cancelled' }
    });

    if (potentialDuplicate) {
      return res.status(400).json({
        success: false,
        message: 'A similar donation was recently posted. Please wait before posting again or edit the existing one.'
      });
    }

    const donation = await Donation.create(req.body);

    // Trigger: Donation Created - Notify all NGOs in area
    const ngos = await User.find({ role: 'ngo', status: 'approved' });
    ngos.forEach(ngo => {
      notify({
        userId: ngo._id,
        title: 'New Donation Available 🥗',
        body: `${req.user.name} just posted a new donation: ${donation.foodName}. Check it out!`,
        category: 'DONATION',
        priority: 'high',
        data: { donationId: donation._id.toString() }
      });
    });

    if (global.io) {
      global.io.emit('new_donation', donation);
    }

    res.status(201).json({ success: true, donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Update donation
// @route   PUT /api/donations/:id
// @access  Private (Donor)
exports.updateDonation = async (req, res, next) => {
  try {
    let donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Make sure user is donation owner
    if (donation.donorId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Not authorized to update this donation' });
    }

    // Only allow update if status is 'waiting'
    if (donation.status !== 'waiting') {
      return res.status(400).json({ success: false, message: 'Cannot update donation after it has been accepted' });
    }

    // Update fields
    Object.keys(req.body).forEach((key) => {
        if (key !== '_id' && key !== 'donorId' && key !== 'status') {
            donation[key] = req.body[key];
        }
    });

    await donation.save();

    res.status(200).json({ success: true, donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Delete donation
// @route   DELETE /api/donations/:id
// @access  Private (Donor)
exports.deleteDonation = async (req, res, next) => {
  try {
    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Make sure user is donation owner or admin
    if (donation.donorId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this donation' });
    }

    // Only allow delete if status is 'waiting'
    if (donation.status !== 'waiting') {
      return res.status(400).json({ success: false, message: 'Cannot delete donation after it has been accepted' });
    }

    await donation.deleteOne();

    res.status(200).json({ success: true, message: 'Donation deleted successfully', data: {} });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all donations for a donor
// @route   GET /api/donations/donor
// @access  Private (Donor)
exports.getDonorDonations = async (req, res, next) => {
  try {
    const { status, search } = req.query;
    let query = { donorId: req.user.id };

    if (status) query.status = status;
    if (search) {
      query.$or = [
        { foodName: { $regex: search, $options: 'i' } },
        { 'items.foodName': { $regex: search, $options: 'i' } }
      ];
    }

    const donations = await Donation.find(query).sort('-createdAt');
    res.status(200).json({ success: true, count: donations.length, donations });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all available donations
// @route   GET /api/donations
// @access  Private (NGO)
exports.getAvailableDonations = async (req, res, next) => {
  try {
    const { search } = req.query;
    let query = { status: 'waiting' };

    if (search) {
      query.$or = [
        { foodName: { $regex: search, $options: 'i' } },
        { 'items.foodName': { $regex: search, $options: 'i' } }
      ];
    }

    const donations = await Donation.find(query).populate('donorId', 'name phoneNumber').sort('-createdAt');
    res.status(200).json({ success: true, count: donations.length, donations });
  } catch (err) {
    next(err);
  }
};

// @desc    Update donation status (Transition and Timeline)
// @route   PUT /api/donations/:id/status
// @access  Private
exports.updateDonationStatus = async (req, res, next) => {
  try {
    const { status, description } = req.body;
    let donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Authorization checks
    if (status === 'accepted') {
      if (donation.status !== 'waiting') {
        return res.status(400).json({ success: false, message: 'Donation already accepted or processed' });
      }
      if (req.user.role !== 'ngo') {
        return res.status(403).json({ success: false, message: 'Only NGOs can accept donations' });
      }
      donation.assignedNgoId = req.user.id;
    } else {
      // For any other status update, user must be either the donor, assigned NGO, or admin
      const isDonor = donation.donorId.toString() === req.user.id;
      const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
      const isVolunteer = donation.volunteerId && donation.volunteerId.toString() === req.user.id;

      if (!isDonor && !isAssignedNgo && !isVolunteer && req.user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Not authorized to update status for this donation' });
      }
    }

    donation.status = status;
    donation.timeline.push({
      status,
      description: description || `Food Rescue: Status updated to ${status.toUpperCase().replace(/_/g, ' ')}`,
      time: Date.now(),
    });

    await donation.save();

    // Refresh donation with donor details for notification
    donation = await Donation.findById(donation._id).populate('donorId', 'name phoneNumber');

    // Notify via Socket.IO for real-time tracking (both to donor room and broadcast)
    if (global.io) {
      const socketPayload = {
        donationId: donation._id.toString(),
        status: donation.status,
        timeline: donation.timeline,
        donation
      };
      if (donation.donorId && donation.donorId._id) {
        global.io.to(donation.donorId._id.toString()).emit('donation_status_update', socketPayload);
      }
      global.io.emit('donation_status_update', socketPayload);
    }

    // Professional Titles and Icons for different statuses
    let notifTitle = 'Donation Update 📢';
    let notifCategory = 'DONATION';

    switch(status) {
        case 'accepted':
            notifTitle = 'Donation Accepted ✅';
            break;
        case 'on_the_way':
            notifTitle = 'Partner On The Way 🚚';
            break;
        case 'arrived':
            notifTitle = 'Partner Arrived 📍';
            break;
        case 'picked_up':
            notifTitle = 'Food Picked Up 🥗';
            break;
        case 'delivered':
            notifTitle = 'Food Delivered 🏁';
            break;
        case 'completed':
            notifTitle = 'Mission Successful! 🎉';
            break;
        case 'cancelled':
            notifTitle = 'Donation Cancelled ❌';
            break;
    }

    // Traditional notification for history
    notify({
      userId: donation.donorId._id,
      title: notifTitle,
      body: `Update for ${donation.foodName}: ${description || 'Your rescue mission is moving forward!'}`,
      category: notifCategory,
      priority: status === 'accepted' ? 'high' : 'medium',
      data: { donationId: donation._id.toString() }
    });

    // SMS triggers for major milestones
    if (['accepted', 'on_the_way', 'delivered', 'completed'].includes(status)) {
        sms.send({
            userId: donation.donorId._id,
            phoneNumber: donation.donorId.phoneNumber,
            templateKey: status === 'accepted' ? 'DONATION_ACCEPTED' : 'PICKUP_STARTED',
            args: status === 'accepted' ? [req.user.name, donation.foodName] : [donation.foodName]
        });
    }

    res.status(200).json({ success: true, donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Cancel donation
// @route   PUT /api/donations/:id/cancel
// @access  Private (Donor/NGO)
exports.cancelDonation = async (req, res, next) => {
  try {
    const { reason } = req.body;
    let donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Authorization: Only donor or assigned NGO can cancel
    const isDonor = donation.donorId.toString() === req.user.id;
    const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;

    if (!isDonor && !isAssignedNgo && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to cancel this donation' });
    }

    // Only allow cancellation if donation is not already completed, cancelled, or rejected
    if (['completed', 'cancelled', 'rejected'].includes(donation.status)) {
      return res.status(400).json({ success: false, message: `Cannot cancel donation in '${donation.status}' status` });
    }

    const status = req.user.role === 'donor' ? 'cancelled' : 'rejected';

    donation.status = status;
    donation.cancellation = {
      cancelledBy: req.user.id,
      reason: reason || 'Cancelled by user',
      time: Date.now()
    };
    donation.timeline.push({
      status,
      description: `Donation ${status} by ${req.user.role}: ${reason || 'No reason provided'}`,
      time: Date.now(),
    });

    await donation.save();

    // Refresh for populating details
    donation = await Donation.findById(donation._id).populate('donorId', 'name phoneNumber').populate('assignedNgoId', 'name phoneNumber');

    // Notify via Socket.IO for real-time tracking
    if (global.io) {
      const socketPayload = {
        donationId: donation._id.toString(),
        status: donation.status,
        timeline: donation.timeline,
        donation
      };
      if (donation.donorId && donation.donorId._id) {
        global.io.to(donation.donorId._id.toString()).emit('donation_status_update', socketPayload);
      }
      global.io.emit('donation_status_update', socketPayload);
    }

    // Trigger: Donation Cancelled/Rejected
    const targetUser = req.user.role === 'donor' ? donation.assignedNgoId : donation.donorId;
    if (targetUser) {
        notify({
            userId: targetUser._id,
            title: `Donation ${status === 'cancelled' ? 'Cancelled' : 'Rejected'} ❌`,
            body: `Donation for ${donation.foodName} was ${status} by ${req.user.name}. Reason: ${reason}`,
            category: 'DONATION',
            priority: 'high',
            data: { donationId: donation._id.toString() }
          });

        // SMS Trigger
        sms.send({
            userId: targetUser._id,
            phoneNumber: targetUser.phoneNumber,
            templateKey: status === 'cancelled' ? 'DONATION_CANCELLED' : 'DONATION_REJECTED',
            args: status === 'cancelled' ? [donation.foodName] : [donation.foodName, reason]
        });
    }

    res.status(200).json({ success: true, message: `Donation ${status}`, donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Assign volunteer to donation
// @route   PUT /api/donations/:id/assign-volunteer
// @access  Private (NGO/Admin)
exports.assignVolunteer = async (req, res, next) => {
  try {
    const { volunteerId } = req.body;
    let donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    const volunteer = await User.findById(volunteerId);
    if (!volunteer) return res.status(404).json({ success: false, message: 'Volunteer not found' });

    donation.volunteerId = volunteerId;
    donation.status = 'accepted';
    donation.timeline.push({
      status: 'accepted',
      description: 'A volunteer has been assigned to your donation.',
      time: Date.now(),
    });

    await donation.save();

    // Trigger: NGO Assigned / Volunteer Assigned
    notify({
        userId: volunteerId,
        title: 'New Assignment 📝',
        body: `You have been assigned to a new food rescue task: ${donation.foodName}.`,
        category: 'DONATION',
        priority: 'high',
        data: { donationId: donation._id.toString() }
      });

    // SMS Trigger
    sms.send({
        userId: volunteerId,
        phoneNumber: volunteer.phoneNumber,
        templateKey: 'NGO_ASSIGNED',
        args: [donation.foodName]
    });

    res.status(200).json({ success: true, donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Update NGO live location
// @route   PUT /api/donations/location
// @access  Private (NGO)
exports.updateLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        currentLatitude: latitude,
        currentLongitude: longitude,
        lastLocationUpdate: Date.now(),
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      data: {
        latitude: user.currentLatitude,
        longitude: user.currentLongitude,
      },
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Verify QR Pickup
// @route   POST /api/donations/:id/verify-pickup
// @access  Private (NGO)
exports.verifyPickup = async (req, res, next) => {
  try {
    const { qrCode } = req.body;
    let donation = await Donation.findById(req.params.id).populate('donorId', 'name phoneNumber');

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Authorization: Only assigned NGO, volunteer, or admin can verify pickup
    const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
    const isVolunteer = donation.volunteerId && donation.volunteerId.toString() === req.user.id;

    if (!isAssignedNgo && !isVolunteer && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to verify pickup for this donation' });
    }

    if (donation.status === 'picked_up' || donation.status === 'completed') {
      return res.status(400).json({ success: false, message: 'Donation has already been picked up or completed' });
    }

    if (donation.status === 'waiting') {
      return res.status(400).json({ success: false, message: 'Donation must be accepted before pickup verification' });
    }

    if (!qrCode || donation.qrCode !== qrCode) {
      return res.status(400).json({ success: false, message: 'Invalid QR Code' });
    }

    donation.status = 'picked_up';
    donation.timeline.push({
      status: 'picked_up',
      description: 'QR Code verified. Food has been picked up by NGO.',
      time: Date.now(),
    });

    await donation.save();

    // Broadcast Socket.IO update AFTER successful DB save
    if (global.io) {
      const socketPayload = {
        donationId: donation._id.toString(),
        status: donation.status,
        timeline: donation.timeline,
        donation
      };
      if (donation.donorId && donation.donorId._id) {
        global.io.to(donation.donorId._id.toString()).emit('donation_status_update', socketPayload);
      }
      global.io.emit('donation_status_update', socketPayload);
    }

    // Trigger: Pickup Completed - Notify Donor
    notify({
      userId: donation.donorId._id,
      title: 'Food Picked Up Successfully 🥗',
      body: `Your donation for ${donation.foodName} has been picked up. Thank you for your contribution!`,
      category: 'DONATION',
      priority: 'medium',
      data: { donationId: donation._id.toString() }
    });

    // SMS Trigger
    sms.send({
      userId: donation.donorId._id,
      phoneNumber: donation.donorId.phoneNumber,
      templateKey: 'PICKUP_COMPLETED',
      args: [donation.foodName]
    });

    res.status(200).json({ success: true, message: 'QR Verified Successfully', donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Confirm Delivery (Distribution)
// @route   POST /api/donations/:id/confirm-delivery
// @access  Private (NGO)
exports.confirmDelivery = async (req, res, next) => {
  try {
    const { photoUrl, address, latitude, longitude, membersServed, notes } = req.body;

    let donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Authorization: Only assigned NGO, volunteer, or admin can confirm delivery
    const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
    const isVolunteer = donation.volunteerId && donation.volunteerId.toString() === req.user.id;

    if (!isAssignedNgo && !isVolunteer && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to confirm delivery for this donation' });
    }

    if (donation.status === 'completed') {
      return res.status(400).json({ success: false, message: 'Delivery has already been confirmed' });
    }

    if (donation.status === 'waiting') {
      return res.status(400).json({ success: false, message: 'Donation must be picked up before confirming delivery' });
    }

    donation.status = 'completed';
    donation.deliveryDetails = {
      photoUrl: photoUrl || '',
      location: { address: address || '', latitude: latitude || 0, longitude: longitude || 0 },
      membersServed: membersServed || 0,
      notes: notes || '',
      completedAt: Date.now(),
    };

    donation.timeline.push({
      status: 'completed',
      description: `Food delivered successfully. Served ${membersServed || 0} people.`,
      time: Date.now(),
    });

    await donation.save();

    // Broadcast Socket.IO update AFTER successful DB save
    if (global.io) {
      const socketPayload = {
        donationId: donation._id.toString(),
        status: donation.status,
        timeline: donation.timeline,
        donation
      };
      if (donation.donorId) {
        global.io.to(donation.donorId.toString()).emit('donation_status_update', socketPayload);
      }
      global.io.emit('donation_status_update', socketPayload);
    }

    // Notify Donor about completion
    notify({
      userId: donation.donorId,
      title: 'Mission Accomplished! 🎉',
      body: `Your food donation reached ${membersServed || 0} people in need. Great job!`,
      category: 'DONATION',
      priority: 'medium',
      data: { donationId: donation._id.toString() }
    });

    res.status(200).json({ success: true, message: 'Delivery Confirmed', donation });
  } catch (err) {
    next(err);
  }
};

// @desc    Get NGO's assigned donations
// @route   GET /api/donations/ngo/assigned
// @access  Private (NGO)
exports.getNgoAssignedDonations = async (req, res, next) => {
  try {
    const { status } = req.query;
    let query = { assignedNgoId: req.user.id };

    if (status) {
      query.status = status;
    } else {
      query.status = { $in: ['accepted', 'on_the_way', 'arrived', 'picked_up', 'delivered', 'completed'] };
    }

    const donations = await Donation.find(query)
      .populate('donorId', 'name phoneNumber currentLatitude currentLongitude')
      .sort('-createdAt');

    res.status(200).json({ success: true, count: donations.length, donations });
  } catch (err) {
    next(err);
  }
};

// @desc    Get single donation detail
// @route   GET /api/donations/:id
// @access  Private
exports.getDonation = async (req, res, next) => {
  try {
    const donation = await Donation.findById(req.params.id)
        .populate('donorId', 'name phoneNumber currentLatitude currentLongitude profileImage averageRating')
        .populate('assignedNgoId', 'name phoneNumber currentLatitude currentLongitude profileImage averageRating');

    if (!donation) {
        return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    res.status(200).json({ success: true, data: donation });
  } catch (err) {
    next(err);
  }
};
