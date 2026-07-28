const express = require('express');
const { createEmergencyRequest, getEmergencyRequests, updateEmergencyRequest } = require('../controllers/emergencyController');
const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.route('/')
  .post(authorize('ngo'), createEmergencyRequest)
  .get(getEmergencyRequests);

router.put('/:id', authorize('ngo', 'admin'), updateEmergencyRequest);

module.exports = router;
