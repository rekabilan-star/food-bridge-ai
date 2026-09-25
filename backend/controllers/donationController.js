const Donation = require('../models/Donation');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { recommendNgos } = require('../services/aiMatchingService');
const { optimizeRoute } = require('../services/routeOptimizationService');
const osrmService = require('../services/osrmService');
const { notify } = require('../services/notificationService');
const geolib = require('geolib');

/**
 * Emit targeted donation status updates strictly to relevant rooms (no global leak)
 */
async function emitTargetedStatusUpdate(donation) {
  if (!global.io || !donation) return;
  const socketPayload = {
    donationId: donation._id.toString(),
    status: donation.status,
    timeline: donation.timeline,
    donation
  };

  const targetRooms = new Set();
  const donorId = donation.donorId?._id ? donation.donorId._id.toString() : donation.donorId?.toString();
  if (donorId) targetRooms.add(donorId);

  const ngoId = donation.assignedNgoId?._id ? donation.assignedNgoId._id.toString() : donation.assignedNgoId?.toString();
  if (ngoId) targetRooms.add(ngoId);

  const volId = donation.volunteerId?._id ? donation.volunteerId._id.toString() : donation.volunteerId?.toString();
  if (volId) targetRooms.add(volId);

  targetRooms.add(`delivery_${donation._id.toString()}`);

  targetRooms.forEach(room => {
    global.io.to(room).emit('donation_status_update', socketPayload);
  });

  // Legitimate admin notification
  try {
    const admins = await User.find({ role: 'admin' }).select('_id');
    admins.forEach(admin => {
      global.io.to(admin._id.toString()).emit('donation_status_update', socketPayload);
    });
  } catch (err) {
    console.error('Error sending socket update to admins:', err);
  }
}


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

    const isDonor = donation.donorId && donation.donorId.toString() === req.user.id;
    if (!isDonor && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to view recommendations for this donation' });
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

    // Trigger: Find approved NGOs strictly within 20 KM (20,000 meters)
    let eligibleNgos = [];
    if (donation.latitude && donation.longitude) {
      try {
        eligibleNgos = await User.aggregate([
          {
            $geoNear: {
              near: {
                type: 'Point',
                coordinates: [parseFloat(donation.longitude), parseFloat(donation.latitude)]
              },
              distanceField: 'distance',
              maxDistance: 20000, // 20 km in meters (boundary <= 20 KM)
              query: {
                role: 'ngo',
                status: 'approved'
              },
              spherical: true
            }
          }
        ]);
      } catch (geoErr) {
        console.error('GeoNear query error on createDonation, falling back to geolib filter:', geoErr);
        const allApprovedNgos = await User.find({ role: 'ngo', status: 'approved' });
        eligibleNgos = allApprovedNgos.filter(ngo => {
          const ngoLat = ngo.currentLatitude || ngo.latitude;
          const ngoLng = ngo.currentLongitude || ngo.longitude;
          if (!ngoLat || !ngoLng || (ngoLat === 0 && ngoLng === 0)) return false;
          const dist = geolib.getDistance(
            { latitude: donation.latitude, longitude: donation.longitude },
            { latitude: ngoLat, longitude: ngoLng }
          );
          return dist <= 20000;
        });
      }
    }

    // Notify only eligible approved NGOs within 20 KM
    eligibleNgos.forEach(ngo => {
      notify({
        userId: ngo._id,
        title: 'New Donation Available 🥗',
        body: `${req.user.name} just posted a new donation: ${donation.foodName}. Check it out!`,
        category: 'DONATION',
        priority: 'high',
        data: { donationId: donation._id.toString() },
        expiresAt: donation.bestBeforeTime
      });

      if (global.io) {
        global.io.to(ngo._id.toString()).emit('new_donation', donation);
      }
    });

    // Also notify admins for real-time monitoring without broad global emit
    const admins = await User.find({ role: 'admin' }).select('_id');
    admins.forEach(admin => {
      if (global.io) {
        global.io.to(admin._id.toString()).emit('new_donation', donation);
      }
    });

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

// @desc    Get all available donations within 20 KM
// @route   GET /api/donations
// @access  Private (NGO/Admin)
exports.getAvailableDonations = async (req, res, next) => {
  try {
    const { search } = req.query;
    let query = {
      status: 'waiting',
      bestBeforeTime: { $gt: new Date() }
    };

    if (search) {
      query.$or = [
        { foodName: { $regex: search, $options: 'i' } },
        { 'items.foodName': { $regex: search, $options: 'i' } }
      ];
    }

    // Admins have access to all waiting donations across the platform
    if (req.user.role === 'admin') {
      const donations = await Donation.find(query).populate('donorId', 'name phoneNumber').sort('-createdAt');
      return res.status(200).json({ success: true, count: donations.length, donations });
    }

    // For NGOs: Must be approved to view available surplus donations
    if (req.user.role === 'ngo') {
      if (req.user.status !== 'approved') {
        return res.status(200).json({ success: true, count: 0, donations: [] });
      }

      // Resolve trusted NGO location
      const ngoLat = req.user.currentLatitude || req.user.latitude;
      const ngoLng = req.user.currentLongitude || req.user.longitude;

      if (!ngoLat || !ngoLng || (ngoLat === 0 && ngoLng === 0)) {
        return res.status(200).json({ success: true, count: 0, donations: [] });
      }

      // Geospatial $near query on Donation.location (max 20,000m)
      try {
        const geoQuery = {
          ...query,
          location: {
            $near: {
              $geometry: {
                type: 'Point',
                coordinates: [parseFloat(ngoLng), parseFloat(ngoLat)]
              },
              $maxDistance: 20000 // 20 km in meters (boundary <= 20 KM)
            }
          }
        };

        const donations = await Donation.find(geoQuery).populate('donorId', 'name phoneNumber');
        return res.status(200).json({ success: true, count: donations.length, donations });
      } catch (geoErr) {
        console.error('Geo query error in getAvailableDonations, falling back to geolib distance filter:', geoErr);
        const allDonations = await Donation.find(query).populate('donorId', 'name phoneNumber').sort('-createdAt');
        const filteredDonations = allDonations.filter(d => {
          if (!d.latitude || !d.longitude || (d.latitude === 0 && d.longitude === 0)) return false;
          const dist = geolib.getDistance(
            { latitude: d.latitude, longitude: d.longitude },
            { latitude: ngoLat, longitude: ngoLng }
          );
          return dist <= 20000;
        });

        return res.status(200).json({ success: true, count: filteredDonations.length, donations: filteredDonations });
      }
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
      if (req.user.role !== 'ngo') {
        return res.status(403).json({ success: false, message: 'Only NGOs can accept donations' });
      }
      if (req.user.status !== 'approved') {
        return res.status(403).json({ success: false, message: 'Only approved NGOs can accept donations' });
      }
      if (donation.status !== 'waiting') {
        return res.status(400).json({ success: false, message: 'Donation already accepted or processed' });
      }

      // Strict Geographic Range Authorization (0 < distance <= 20 KM)
      const ngoLat = req.user.currentLatitude || req.user.latitude;
      const ngoLng = req.user.currentLongitude || req.user.longitude;
      const donLat = donation.latitude;
      const donLng = donation.longitude;

      if (!ngoLat || !ngoLng || !donLat || !donLng || (ngoLat === 0 && ngoLng === 0) || (donLat === 0 && donLng === 0)) {
        return res.status(400).json({
          success: false,
          message: 'Valid geographic location coordinates required to verify 20 KM operating distance'
        });
      }

      const distanceMeters = geolib.getDistance(
        { latitude: donLat, longitude: donLng },
        { latitude: ngoLat, longitude: ngoLng }
      );
      const distanceKm = distanceMeters / 1000;

      if (distanceKm > 20) {
        return res.status(403).json({
          success: false,
          message: `Donation is outside your 20 KM operating range (${distanceKm.toFixed(1)} KM away)`
        });
      }

      // Check if food is expired before acceptance
      if (donation.bestBeforeTime && new Date() >= new Date(donation.bestBeforeTime)) {
        await Donation.updateOne({ _id: donation._id, status: 'waiting' }, { status: 'expired' });
        return res.status(400).json({
          success: false,
          message: 'This donation has expired and can no longer be accepted'
        });
      }

      // Atomic Acceptance Update to prevent race conditions & check expiry atomically
      const updatedDonation = await Donation.findOneAndUpdate(
        {
          _id: req.params.id,
          status: 'waiting',
          bestBeforeTime: { $gt: new Date() }
        },
        {
          $set: {
            status: 'accepted',
            assignedNgoId: req.user.id
          },
          $push: {
            timeline: {
              status: 'accepted',
              description: description || `Donation accepted by ${req.user.name}`,
              time: Date.now()
            }
          }
        },
        { new: true }
      ).populate('donorId', 'name phoneNumber');

      if (!updatedDonation) {
        const checkExisting = await Donation.findById(req.params.id);
        if (checkExisting && checkExisting.bestBeforeTime && new Date() >= new Date(checkExisting.bestBeforeTime)) {
          return res.status(400).json({
            success: false,
            message: 'This donation has expired and is no longer available'
          });
        }
        return res.status(400).json({
          success: false,
          message: 'Donation is no longer available or was already accepted'
        });
      }
      donation = updatedDonation;

      // Real-time notification to competing eligible NGOs that this donation has been claimed
      try {
        if (global.io) {
          const competingNgoIds = new Set();

          // 1. All NGOs who received notification for this donation
          const notifiedRecords = await Notification.find({
            category: 'DONATION',
            'data.donationId': donation._id.toString()
          }).select('userId').lean();

          notifiedRecords.forEach(n => {
            if (n.userId) competingNgoIds.add(n.userId.toString());
          });

          // 2. Also approved NGOs within 20 KM
          if (donation.latitude && donation.longitude) {
            try {
              const geoNgos = await User.aggregate([
                {
                  $geoNear: {
                    near: {
                      type: 'Point',
                      coordinates: [parseFloat(donation.longitude), parseFloat(donation.latitude)]
                    },
                    distanceField: 'distance',
                    maxDistance: 20000,
                    query: { role: 'ngo', status: 'approved' },
                    spherical: true
                  }
                }
              ]);
              geoNgos.forEach(ngo => competingNgoIds.add(ngo._id.toString()));
            } catch (geoErr) {
              const allApprovedNgos = await User.find({ role: 'ngo', status: 'approved' }).select('_id currentLatitude latitude currentLongitude longitude');
              allApprovedNgos.forEach(ngo => {
                const ngoLat = ngo.currentLatitude || ngo.latitude;
                const ngoLng = ngo.currentLongitude || ngo.longitude;
                if (!ngoLat || !ngoLng || (ngoLat === 0 && ngoLng === 0)) return;
                const dist = geolib.getDistance(
                  { latitude: donation.latitude, longitude: donation.longitude },
                  { latitude: ngoLat, longitude: ngoLng }
                );
                if (dist <= 20000) competingNgoIds.add(ngo._id.toString());
              });
            }
          }

          // Strictly exclude accepting NGO, donor, and admins (admins receive standard donation_status_update)
          competingNgoIds.delete(req.user.id.toString());
          if (donation.donorId) {
            const donorIdStr = (donation.donorId._id || donation.donorId).toString();
            competingNgoIds.delete(donorIdStr);
          }

          // Emit strictly to each competing NGO's private room with minimal non-sensitive payload
          const claimedPayload = { donationId: donation._id.toString() };
          for (const competingNgoId of competingNgoIds) {
            global.io.to(competingNgoId).emit('donation_claimed', claimedPayload);
          }
        }
      } catch (claimErr) {
        console.error('Error emitting donation_claimed to competing NGOs:', claimErr);
      }
    } else {
      // For any other status update, user must be either the donor, assigned NGO, or admin
      const isDonor = donation.donorId.toString() === req.user.id;
      const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
      const isVolunteer = donation.volunteerId && donation.volunteerId.toString() === req.user.id;

      if (!isDonor && !isAssignedNgo && !isVolunteer && req.user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Not authorized to update status for this donation' });
      }

      donation.status = status;
      donation.timeline.push({
        status,
        description: description || `Food Rescue: Status updated to ${status.toUpperCase().replace(/_/g, ' ')}`,
        time: Date.now(),
      });

      await donation.save();
      donation = await Donation.findById(donation._id).populate('donorId', 'name phoneNumber');
    }

    // Targeted Socket.IO update (no global leak)
    await emitTargetedStatusUpdate(donation);

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

    // Targeted Socket.IO update (no global leak)
    await emitTargetedStatusUpdate(donation);

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

    const isAssignedNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
    if (!isAssignedNgo && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to assign volunteer to this donation' });
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

    const updateFields = {
      currentLatitude: latitude,
      currentLongitude: longitude,
      lastLocationUpdate: Date.now(),
    };
    if (latitude && longitude) {
      updateFields.location = {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      };
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      updateFields,
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

    // Targeted Socket.IO update (no global leak)
    await emitTargetedStatusUpdate(donation);

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

    // Targeted Socket.IO update (no global leak)
    await emitTargetedStatusUpdate(donation);

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

    const donorIdStr = donation.donorId?._id ? donation.donorId._id.toString() : donation.donorId?.toString();
    const assignedNgoIdStr = donation.assignedNgoId?._id ? donation.assignedNgoId._id.toString() : donation.assignedNgoId?.toString();
    const volunteerIdStr = donation.volunteerId?._id ? donation.volunteerId._id.toString() : donation.volunteerId?.toString();

    // 1. Admin: full legitimate access
    if (req.user.role === 'admin') {
      return res.status(200).json({ success: true, data: donation });
    }

    // 2. Donor: must be the donation owner
    if (req.user.role === 'donor') {
      if (donorIdStr !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Not authorized to view another donor\'s donation' });
      }
      return res.status(200).json({ success: true, data: donation });
    }

    // 3. Volunteer: must be the assigned volunteer
    if (req.user.role === 'volunteer') {
      if (volunteerIdStr !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Not authorized to view this donation' });
      }
      return res.status(200).json({ success: true, data: donation });
    }

    // 4. NGO:
    if (req.user.role === 'ngo') {
      // If waiting: must be approved and <= 20 KM
      if (donation.status === 'waiting') {
        if (req.user.status !== 'approved') {
          return res.status(403).json({ success: false, message: 'Only approved NGOs can view available donations' });
        }

        const ngoLat = req.user.currentLatitude || req.user.latitude;
        const ngoLng = req.user.currentLongitude || req.user.longitude;
        if (!ngoLat || !ngoLng || (ngoLat === 0 && ngoLng === 0) || !donation.latitude || !donation.longitude) {
          return res.status(403).json({ success: false, message: 'Valid geographic location coordinates required to verify 20 KM operating distance' });
        }

        const distMeters = geolib.getDistance(
          { latitude: donation.latitude, longitude: donation.longitude },
          { latitude: ngoLat, longitude: ngoLng }
        );
        if (distMeters > 20000) {
          return res.status(403).json({
            success: false,
            message: `Donation is outside your 20 KM operating range (${(distMeters / 1000).toFixed(1)} KM away)`
          });
        }

        // Check if food has reached expiry
        if (donation.bestBeforeTime && new Date() >= new Date(donation.bestBeforeTime)) {
          donation.status = 'expired';
          await Donation.updateOne({ _id: donation._id }, { status: 'expired' });
          return res.status(200).json({
            success: true,
            data: donation,
            expired: true,
            message: 'This donation has expired and is no longer available'
          });
        }

        return res.status(200).json({ success: true, data: donation });
      }

      // If status is 'expired': allowed if within 20km or assigned, show expired state
      if (donation.status === 'expired') {
        return res.status(200).json({
          success: true,
          data: donation,
          expired: true,
          message: 'This donation has expired and is no longer available'
        });
      }

      // For any non-waiting status (accepted, on_the_way, arrived, picked_up, delivered, completed, etc.):
      // Must be the assigned NGO!
      if (assignedNgoIdStr !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to view details of a donation accepted by another NGO'
        });
      }

      return res.status(200).json({ success: true, data: donation });
    }

    // Default reject for unknown/unauthorized roles
    return res.status(403).json({ success: false, message: 'Not authorized to access this donation' });
  } catch (err) {
    next(err);
  }
};

// @desc    Verify QR Code and get details (Public/Protected)
// @route   GET /api/donations/verify/:qrCode
// @access  Public
exports.verifyQrDetails = async (req, res, next) => {
  try {
    const donation = await Donation.findOne({ qrCode: req.params.qrCode })
        .populate('donorId', 'name profileImage averageRating')
        .populate('assignedNgoId', 'name profileImage averageRating');

    if (!donation) {
        return res.status(404).json({ success: false, message: 'Invalid Verification Code' });
    }

    res.status(200).json({
      success: true,
      data: {
        id: donation._id,
        foodName: donation.foodName,
        donorName: donation.donorId?.name,
        ngoName: donation.assignedNgoId?.name,
        status: donation.status,
        completedAt: donation.deliveryDetails?.completedAt,
        impact: {
          meals: donation.deliveryDetails?.membersServed || donation.membersServed,
          weight: (donation.deliveryDetails?.membersServed || donation.membersServed) * 0.5
        },
        timeline: donation.timeline
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get road-aware route for donation tracking
// @route   GET /api/donations/:id/route
// @access  Private
exports.getDonationRoute = async (req, res, next) => {
  try {
    const donation = await Donation.findById(req.params.id);

    if (!donation) {
      return res.status(404).json({ success: false, message: 'Donation not found' });
    }

    // Authorization: Donor, Assigned NGO, Volunteer, or Admin
    const isDonor = donation.donorId.toString() === req.user.id;
    const isNgo = donation.assignedNgoId && donation.assignedNgoId.toString() === req.user.id;
    const isVolunteer = donation.volunteerId && donation.volunteerId.toString() === req.user.id;
    const isAdmin = req.user.role === 'admin';

    if (!isDonor && !isNgo && !isVolunteer && !isAdmin) {
      return res.status(403).json({ success: false, message: 'Not authorized to access this route' });
    }

    // Determine Origin (NGO/Volunteer Current Location)
    const activeUser = await User.findById(donation.assignedNgoId || donation.volunteerId || req.user.id);
    const origin = {
      latitude: activeUser.currentLatitude || activeUser.latitude,
      longitude: activeUser.currentLongitude || activeUser.longitude
    };

    // Determine Destination based on status
    let destination;
    if (['accepted', 'on_the_way', 'arrived'].includes(donation.status)) {
      // Heading to Pickup (Donor)
      destination = {
        latitude: donation.latitude,
        longitude: donation.longitude
      };
    } else if (donation.status === 'picked_up') {
      // Heading to Delivery (Distribution Point)
      destination = {
        latitude: donation.deliveryDetails?.location?.latitude || donation.latitude,
        longitude: donation.deliveryDetails?.location?.longitude || donation.longitude
      };
    } else {
      return res.status(400).json({ success: false, message: 'No active tracking for this donation status' });
    }

    const routeData = await osrmService.getRoute(origin, destination);

    res.status(200).json(routeData);
  } catch (err) {
    next(err);
  }
};
