const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const SubscriptionPlan = require('../models/SubscriptionPlan');
const Payment = require('../models/Payment');
const User = require('../models/User');
const authenticateToken = require('../middleware/auth');
const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/receipts';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'receipt-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// GET /api/subscription/plans - Get all active subscription plans
router.get('/plans', async (req, res) => {
  try {
    const plans = await SubscriptionPlan.find({});
    
    res.json({
      success: true,
      data: plans
    });
  } catch (error) {
    console.error('Error fetching subscription plans:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch subscription plans'
    });
  }
});

// Submit payment proof
router.post('/submit-payment', authenticateToken, upload.single('receiptFile'), async (req, res) => {
  try {
    const { userName, contactNumber, planSelected, billingCycle, finalAmount, deviceId } = req.body;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Receipt file is required'
      });
    }
  
    if (!userName || !contactNumber || !planSelected || !billingCycle || !finalAmount || !deviceId) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    if (!/^[A-Za-z0-9]{12}$/.test(deviceId)) {
      return res.status(400).json({
        success: false,
        message: 'Device ID must be exactly 12 alphanumeric characters'
      });
    }

    // Get user info from database
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
  
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const receiptUrl = `${baseUrl}/${req.file.path.replace(/\\/g, '/')}`;
    
    const payment = new Payment({
      userName,
      contactNumber,
      receiptFile: receiptUrl,
      planSelected,
      billingCycle,
      finalAmount: parseFloat(finalAmount),
      userId: user._id,
      name: user.name,
      email: user.email,
      deviceId
    });
  
    await payment.save();
  
    res.json({
      success: true,
      message: 'Payment proof submitted successfully',
      paymentId: payment._id
    });
  
  } catch (error) {
    console.error('Payment submission error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit payment proof'
    });
  }
});

module.exports = router;