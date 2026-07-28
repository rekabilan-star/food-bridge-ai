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
} = require('../controllers/donationController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../utils/fileUpload');

const router = express.Router();

router.use(protect);

router
  .route('/')
  .post(authorize('donor'), createDonation)
  .get(authorize('ngo', 'admin'), getAvailableDonations);

router.get('/donor', authorize('donor'), getDonorDonations);
router.get('/ngo/assigned', authorize('ngo'), getNgoAssignedDonations);
router.get('/volunteer/route', authorize('volunteer', 'ngo'), getVolunteerRoute);

router.post('/upload', upload.single('image'), (req, res) => {
    if (!req.file) { return res.status(400).json({ success: false, message: 'Please upload a file' }); }
    res.status(200).json({ success: true, data: req.file.filename });
});

router.put('/location', authorize('ngo'), updateLocation);

router.get('/:id', getDonation);
router.get('/:id/recommendations', getDonationRecommendations);
router.put('/:id/status', updateDonationStatus);
router.put('/:id/cancel', cancelDonation);
router.put('/:id/assign-volunteer', authorize('ngo', 'admin'), assignVolunteer);
router.post('/:id/verify-pickup', authorize('ngo'), verifyPickup);
router.post('/:id/confirm-delivery', authorize('ngo'), confirmDelivery);

module.exports = router;
