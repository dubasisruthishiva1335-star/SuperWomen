const express = require('express');
const router = express.Router();

// Generate & Send 6-Digit Phone OTP
router.post('/send-otp', (req, res) => {
  const { phone, role } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone number is required' });

  // In production: dispatch SMS via Twilio / Msg91 / Kaleyra
  console.log(`[AUTH] Sent 6-digit OTP 497280 to ${phone} for role: ${role || 'CAPTAIN'}`);

  return res.json({
    success: true,
    message: 'OTP sent successfully to ' + phone,
    sampleOtp: '497280' // Mock for testing
  });
});

// Verify Phone OTP
router.post('/verify-otp', (req, res) => {
  const { phone, otp, role } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'Phone and OTP are required' });

  if (otp === '497280' || otp === '123456') {
    return res.json({
      success: true,
      token: 'jwt_mock_token_superwomen_' + Date.now(),
      user: {
        id: 'usr_' + Date.now(),
        phone,
        role: role || 'CAPTAIN',
        name: role === 'RIDER' ? 'Meera Kumar' : 'Priya Sharma',
        gender: 'FEMALE',
        isVerified: true
      }
    });
  }

  return res.status(401).json({ error: 'Invalid OTP entered. Please try again.' });
});

module.exports = router;
