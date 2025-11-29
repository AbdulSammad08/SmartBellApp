const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const SubscriptionPlan = require('../models/SubscriptionPlan');
const Payment = require('../models/Payment');
const User = require('../models/User');
const UserSubscription = require('../models/UserSubscription');
const authenticateToken = require('../middleware/auth');
const { requireSubscription, getSubscriptionDetails } = require('../middleware/subscriptionAuth');
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

    // Check if user already has a pending payment
    const existingPayment = await Payment.findOne({
      userId: user._id,
      status: 'pending'
    });

    if (existingPayment) {
      return res.status(400).json({
        success: false,
        message: 'You already have a pending payment. Please wait for approval.'
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
      deviceId,
      status: 'pending'
    });
  
    await payment.save();

    // Update user subscription status to pending
    user.subscriptionStatus = 'pending';
    await user.save();
  
    res.json({
      success: true,
      message: 'Payment proof submitted successfully. Please wait for admin approval.',
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

// Get user subscription status
router.get('/status', authenticateToken, getSubscriptionDetails, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    
    // Check for payments with different status values (pending, confirmed, approved)
    const pendingPayment = await Payment.findOne({
      userId: req.user.userId,
      status: { $in: ['pending', 'confirmed'] }
    });

    // If payment is confirmed but user subscription is not active, activate it
    if (pendingPayment && pendingPayment.status === 'confirmed' && user.subscriptionStatus !== 'active') {
      console.log(`Activating subscription for user ${user.email} with confirmed payment`);
      
      // Update payment status to approved
      pendingPayment.status = 'approved';
      pendingPayment.approvedBy = 'Admin Portal';
      pendingPayment.approvedAt = new Date();
      await pendingPayment.save();

      // Update user subscription
      const startDate = new Date();
      const endDate = new Date();
      
      if (pendingPayment.billingCycle === 'monthly') {
        endDate.setMonth(endDate.getMonth() + 1);
      } else {
        endDate.setFullYear(endDate.getFullYear() + 1);
      }

      user.subscriptionStatus = 'active';
      user.subscriptionPlan = pendingPayment.planSelected.toLowerCase();
      user.subscriptionStartDate = startDate;
      user.subscriptionEndDate = endDate;
      await user.save();

      // Create or update user subscription record
      let userSubscription = await UserSubscription.findOne({ userId: user._id });
      if (!userSubscription) {
        userSubscription = new UserSubscription({
          userId: user._id,
          paymentId: pendingPayment._id,
          planType: pendingPayment.planSelected,
          billingCycle: pendingPayment.billingCycle,
          amount: pendingPayment.finalAmount,
          status: 'active',
          startDate,
          endDate,
          approvedBy: 'Admin Portal',
          approvedAt: new Date()
        });
        await userSubscription.save();
      }
      
      // Refresh subscription details
      req.user.subscription.status = 'active';
      req.user.subscription.plan = pendingPayment.planSelected;
    }

    // Only show pending payment if status is actually pending
    const actualPendingPayment = await Payment.findOne({
      userId: req.user.userId,
      status: 'pending'
    });

    res.json({
      success: true,
      subscription: req.user.subscription,
      pendingPayment: actualPendingPayment ? {
        id: actualPendingPayment._id,
        planSelected: actualPendingPayment.planSelected,
        billingCycle: actualPendingPayment.billingCycle,
        finalAmount: actualPendingPayment.finalAmount,
        submittedAt: actualPendingPayment.createdAt
      } : null
    });
  } catch (error) {
    console.error('Get subscription status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get subscription status'
    });
  }
});

// Admin: Approve payment and activate subscription
router.post('/approve-payment/:paymentId', authenticateToken, async (req, res) => {
  try {
    const { paymentId } = req.params;
    const { approvedBy } = req.body;

    const payment = await Payment.findById(paymentId);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    if (payment.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Payment is not in pending status'
      });
    }

    // Update payment status
    payment.status = 'approved';
    payment.approvedBy = approvedBy || 'Admin';
    payment.approvedAt = new Date();
    await payment.save();

    // Update user subscription
    const user = await User.findById(payment.userId);
    const startDate = new Date();
    const endDate = new Date();
    
    if (payment.billingCycle === 'monthly') {
      endDate.setMonth(endDate.getMonth() + 1);
    } else {
      endDate.setFullYear(endDate.getFullYear() + 1);
    }

    user.subscriptionStatus = 'active';
    user.subscriptionPlan = payment.planSelected.toLowerCase();
    user.subscriptionStartDate = startDate;
    user.subscriptionEndDate = endDate;
    await user.save();

    // Create user subscription record
    const userSubscription = new UserSubscription({
      userId: payment.userId,
      paymentId: payment._id,
      planType: payment.planSelected,
      billingCycle: payment.billingCycle,
      amount: payment.finalAmount,
      status: 'active',
      startDate,
      endDate,
      approvedBy: payment.approvedBy,
      approvedAt: payment.approvedAt
    });
    await userSubscription.save();

    res.json({
      success: true,
      message: 'Payment approved and subscription activated successfully'
    });
  } catch (error) {
    console.error('Approve payment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve payment'
    });
  }
});

// Admin: Reject payment
router.post('/reject-payment/:paymentId', authenticateToken, async (req, res) => {
  try {
    const { paymentId } = req.params;
    const { rejectionReason, rejectedBy } = req.body;

    const payment = await Payment.findById(paymentId);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    if (payment.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Payment is not in pending status'
      });
    }

    // Update payment status
    payment.status = 'rejected';
    payment.rejectionReason = rejectionReason;
    payment.approvedBy = rejectedBy || 'Admin';
    payment.approvedAt = new Date();
    await payment.save();

    // Update user subscription status
    const user = await User.findById(payment.userId);
    user.subscriptionStatus = 'none';
    await user.save();

    res.json({
      success: true,
      message: 'Payment rejected successfully'
    });
  } catch (error) {
    console.error('Reject payment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject payment'
    });
  }
});

module.exports = router;