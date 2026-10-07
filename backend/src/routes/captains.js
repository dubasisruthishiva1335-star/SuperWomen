const express = require('express');
const router = express.Router();

let captainState = {
  id: 'cap_priya',
  name: 'Priya Sharma',
  isOnline: true,
  walletBalance: 2450.0,
  dailyEarnings: 1240.0,
  completedTripsToday: 8,
  rating: 4.94,
  kyc: {
    license: 'DL-042019003829',
    rc: 'TN09 AB 4521',
    status: 'VERIFIED'
  }
};

// Toggle Online / Offline
router.post('/toggle-online', (req, res) => {
  captainState.isOnline = !captainState.isOnline;
  return res.json({
    success: true,
    isOnline: captainState.isOnline,
    message: captainState.isOnline ? 'Captain is now ONLINE' : 'Captain is now OFFLINE'
  });
});

// Get Dashboard & Earnings Data
router.get('/dashboard', (req, res) => {
  return res.json({
    success: true,
    data: captainState
  });
});

// Request Wallet Withdrawal
router.post('/withdraw', (req, res) => {
  const { amount, upiId } = req.body;
  const withdrawAmount = amount || captainState.walletBalance;

  console.log(`[PAYOUT] Dispatched ₹${withdrawAmount} to UPI ID: ${upiId || 'priya@okaxis'}`);
  captainState.walletBalance = Math.max(0, captainState.walletBalance - withdrawAmount);

  return res.json({
    success: true,
    message: `Withdrawal of ₹${withdrawAmount} processed successfully.`,
    remainingBalance: captainState.walletBalance
  });
});

module.exports = router;
