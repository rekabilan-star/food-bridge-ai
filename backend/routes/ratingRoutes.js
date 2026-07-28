const express = require('express');
const { createRating } = require('../controllers/ratingController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.post('/', createRating);

module.exports = router;
