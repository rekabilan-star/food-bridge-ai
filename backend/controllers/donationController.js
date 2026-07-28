const Donation = require('../models/Donation');
const User = require('../models/User');
const { recommendNgos } = require('../services/aiMatchingService');
const { sendPushNotification } = require('../services/fcmService');

const { optimizeRoute } = require('../services/routeOptimizationService');

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
    const donation = await Donation.create(req.body);
    res.status(201).json({ success: true, donation });
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

    if (status === 'accepted' && req.user.role === 'ngo') {
      donation.assignedNgoId = req.user.id;
      // Notify Donor
      await sendPushNotification(
        donation.donorId,
        'Donation Accepted',
        `An NGO (${req.user.name}) has accepted your food donation!`
      );
    }

    donation.status = status;
    donation.timeline.push({
      status,
      description: description || `Status updated to ${status.replace(/_/g, ' ')}`,
      time: Date.now(),
    });

    await donation.save();

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

    const status = req.user.role === 'donor' ? 'cancelled' : 'rejected';

    donation.status = status;
    donation.cancellation = {
      cancelledBy: req.user.id,
      reason,
      time: Date.now()
    };
    donation.timeline.push({
      status,
      description: `Donation ${status} by ${req.user.role}: ${reason}`,
      time: Date.now(),
    });

    await donation.save();

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

    donation.volunteerId = volunteerId;
    donation.status = 'accepted'; // or 'volunteer_assigned'
    donation.timeline.push({
      status: 'accepted',
      description: 'A volunteer has been assigned to your donation.',
      time: Date.now(),
    });

    await donation.save();

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
    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    if (donation.qrCode !== qrCode) {
      return res.status(400).json({ success: false, message: 'Invalid QR Code' });
    }

    if (donation.status === 'picked_up') {
        return res.status(400).json({ success: false, message: 'Already picked up' });
    }

    donation.status = 'picked_up';
    donation.timeline.push({
      status: 'picked_up',
      description: 'QR Code verified. Food has been picked up by NGO.',
      time: Date.now(),
    });

    await donation.save();

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

    donation.status = 'completed';
    donation.deliveryDetails = {
      photoUrl,
      location: { address, latitude, longitude },
      membersServed,
      notes,
      completedAt: Date.now(),
    };

    donation.timeline.push({
      status: 'completed',
      description: `Food delivered successfully. Served ${membersServed} people.`,
      time: Date.now(),
    });

    await donation.save();

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
    const donations = await Donation.find({
        assignedNgoId: req.user.id,
        status: { $in: ['accepted', 'on_the_way', 'arrived', 'picked_up'] }
    }).populate('donorId', 'name phoneNumber currentLatitude currentLongitude').sort('-createdAt');

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
