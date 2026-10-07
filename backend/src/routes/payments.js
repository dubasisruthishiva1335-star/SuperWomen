const express = require('express');
const router = express.Router();
const paymentService = require('../services/paymentService');

// 1. Create Order for a Trip
router.post('/create-order', async (req, res) => {
  const { tripId, fareAmount, riderPhone } = req.body;
  if (!tripId || !fareAmount) {
    return res.status(400).json({ error: 'tripId and fareAmount are required' });
  }

  const order = await paymentService.createRideOrder(tripId, fareAmount, riderPhone);
  return res.status(201).json(order);
});

// 2. Verify Payment Webhook / Callback
router.post('/verify', (req, res) => {
  const { orderId, paymentId, signature, tripId } = req.body;

  const isValid = paymentService.verifyPaymentSignature(orderId, paymentId, signature);
  if (isValid) {
    console.log(`[PAYMENT VERIFIED] Payment ${paymentId} verified for Trip ${tripId}`);
    return res.json({ success: true, message: 'Payment verified and settled' });
  }

  return res.status(400).json({ success: false, error: 'Invalid payment signature' });
});

// 3. Captain Instant Payout
router.post('/captain-payout', async (req, res) => {
  const { captainId, amount, upiId, bankAccount } = req.body;
  if (!captainId || !amount) {
    return res.status(400).json({ error: 'captainId and amount are required' });
  }

  const payout = await paymentService.processCaptainInstantPayout(captainId, amount, upiId, bankAccount);
  return res.json(payout);
});

module.exports = router;
