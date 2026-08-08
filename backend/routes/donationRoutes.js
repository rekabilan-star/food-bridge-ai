const express = require('express');
const {
  createDonation,
  getDonorDonations,
  getAvailableDonations,
  updateDonationStatus,
  updateLocation,
  verifyPickup,
  confirmDelivery,
  getNgoAssignedDonations,
  getDonation,
  cancelDonation,
  assignVolunteer,
  getDonationRecommendations,
  getVolunteerRoute,
  updateDonation,
  deleteDonation,
} = require('../controllers/donationController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { check } = require('express-validator');
const { validate } = require('../middleware/validationMiddleware');
const { cloudinary, storage: cloudinaryStorage } = require('../utils/cloudinary');
const multer = require('multer');
const uploadCloudinary = multer({ storage: cloudinaryStorage });

const router = express.Router();

router.use(protect);

router
  .route('/')
  .post(authorize('donor'), [
    check('items', 'Food items are required').isArray({ min: 1 }),
    check('pickupAddress', 'Pickup address is required').not().isEmpty(),
    check('latitude', 'Latitude is required').isFloat(),
    check('longitude', 'Longitude is required').isFloat(),
    check('preparedTime', 'Prepared time is required').isISO8601(),
    check('bestBeforeTime', 'Expiry time is required').isISO8601(),
    validate
  ], createDonation)
  .get(authorize('ngo', 'admin'), getAvailableDonations);

router.get('/donor', authorize('donor'), getDonorDonations);
router.get('/ngo/assigned', authorize('ngo'), getNgoAssignedDonations);
router.get('/volunteer/route', authorize('volunteer', 'ngo'), getVolunteerRoute);

router.post('/upload', uploadCloudinary.single('image'), (req, res) => {
    if (!req.file) { return res.status(400).json({ success: false, message: 'Please upload a file' }); }
    res.status(200).json({ success: true, data: req.file.path });
});

router.put('/location', authorize('ngo'), updateLocation);

router.get('/:id', getDonation);
router.get('/:id/recommendations', getDonationRecommendations);
router.put('/:id/status', updateDonationStatus);
router.put('/:id/cancel', cancelDonation);
router.put('/:id/assign-volunteer', authorize('ngo', 'admin'), assignVolunteer);
router.post('/:id/verify-pickup', authorize('ngo'), verifyPickup);
router.post('/:id/confirm-delivery', authorize('ngo'), confirmDelivery);

router
  .route('/:id')
  .put(authorize('donor'), updateDonation)
  .delete(authorize('donor'), deleteDonation);

module.exports = router;
