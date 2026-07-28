const EmergencyRequest = require('../models/EmergencyRequest');

// @desc    Create emergency food request
// @route   POST /api/emergency
// @access  Private (NGO)
exports.createEmergencyRequest = async (req, res, next) => {
  try {
    req.body.ngoId = req.user.id;
    const request = await EmergencyRequest.create(req.body);

    res.status(201).json({
      success: true,
      data: request,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all active emergency requests
// @route   GET /api/emergency
// @access  Private
exports.getEmergencyRequests = async (req, res, next) => {
  try {
    const requests = await EmergencyRequest.find({ status: 'active' })
      .populate('ngoId', 'name phoneNumber averageRating')
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: requests.length,
      data: requests,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Update emergency request status
// @route   PUT /api/emergency/:id
// @access  Private (NGO)
exports.updateEmergencyRequest = async (req, res, next) => {
  try {
    let request = await EmergencyRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }

    if (request.ngoId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Not authorized' });
    }

    request = await EmergencyRequest.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({
      success: true,
      data: request,
    });
  } catch (err) {
    next(err);
  }
};
