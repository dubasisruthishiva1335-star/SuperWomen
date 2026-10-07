const express = require('express');
const router = express.Router();
const rideController = require('../controllers/rideController');

router.post('/request', rideController.requestRide);
router.post('/:tripId/accept', rideController.acceptRide);
router.post('/:tripId/start', rideController.verifyOtpAndStart);
router.post('/:tripId/complete', rideController.completeRide);

module.exports = router;
