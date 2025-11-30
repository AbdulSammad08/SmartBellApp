const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const mongoose = require('mongoose');
const { sendOTPEmail, sendPasswordResetOTP } = require('../utils/emailService');
const { generateOTP, hashOTP, getOTPExpiry } = require('../utils/otpGenerator');
const { validateRegister, validateLogin, validateOTP } = require('../middleware/validation');
const { otpLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

// Register endpoint
router.post('/register', validateRegister, async (req, res) => {
  let normalizedEmail;
  try {
    const { email, password, name } = req.body;
    
    // Normalize email to lowercase for consistent checking
    normalizedEmail = email.toLowerCase().trim();
    console.log(`Registration attempt for email: ${normalizedEmail}`);

    // Check if user already exists (case-insensitive)
    const existingUser = await User.findOne({ email: normalizedEmail });
    console.log(`Existing user found: ${existingUser ? 'YES' : 'NO'}`);
    
    if (existingUser) {
      if (!existingUser.isVerified) {
        // User exists but not verified, resend OTP
        if (!existingUser.canRequestOTP()) {
          return res.status(429).json({
            success: false,
            message: 'Too many OTP requests. Please try again later.'
          });
        }

        // Generate new OTP
        const otp = generateOTP();
        const otpHash = await hashOTP(otp);
        const otpExpires = getOTPExpiry();

        existingUser.otpHash = otpHash;
        existingUser.otpExpires = otpExpires;
        existingUser.lastOtpRequest = new Date();
        existingUser.otpAttempts = (existingUser.otpAttempts || 0) + 1;
        await existingUser.save();

        // Send OTP email
        const emailSent = await sendOTPEmail(normalizedEmail, otp, name);
        if (!emailSent) {
          return res.status(500).json({
            success: false,
            message: 'Failed to send verification email'
          });
        }

        return res.status(202).json({
          success: true,
          message: 'OTP sent to your email'
        });
      } else {
        return res.status(400).json({
          success: false,
          message: 'User already exists with this email'
        });
      }
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Generate and hash OTP
    const otp = generateOTP();
    const otpHash = await hashOTP(otp);
    const otpExpires = getOTPExpiry();

    // Create user using Mongoose with a workaround for stuck indexes
    const userData = {
      email: normalizedEmail,
      passwordHash,
      name,
      otpHash,
      otpExpires,
      lastOtpRequest: new Date(),
      otpAttempts: 1,
      subscriptionStatus: 'none',
      subscriptionPlan: null,
      subscriptionStartDate: null,
      subscriptionEndDate: null
    };
    
    console.log(`Creating new user with email: ${normalizedEmail}`);
    
    // Use new collection to bypass corrupted indexes
    const db = mongoose.connection.db;
    const newCollectionName = 'users_v2';
    
    try {
      // First ensure the new collection has proper indexes
      await db.collection(newCollectionName).createIndex({ email: 1 }, { unique: true });
    } catch (indexError) {
      // Index might already exist, ignore error
    }
    
    try {
      const result = await db.collection(newCollectionName).insertOne({
        ...userData,
        isVerified: false,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      var user = { _id: result.insertedId, ...userData };
      
      // Migrate existing users to new collection if this is the first insert
      const oldUsers = await db.collection('users').find({}).toArray();
      if (oldUsers.length > 0) {
        for (const oldUser of oldUsers) {
          try {
            await db.collection(newCollectionName).insertOne(oldUser);
          } catch (migrateError) {
            if (migrateError.code !== 11000) {
              console.log('Migration error for user:', oldUser.email, migrateError.message);
            }
          }
        }
        console.log(`Migrated ${oldUsers.length} users to new collection`);
      }
      
    } catch (dbError) {
      if (dbError.code === 11000 && dbError.message.includes('email')) {
        return res.status(400).json({
          success: false,
          message: 'User already exists with this email'
        });
      }
      throw dbError;
    }

    // Send OTP email
    const emailSent = await sendOTPEmail(normalizedEmail, otp, name);
    if (!emailSent) {
      await db.collection('users_v2').deleteOne({ _id: user._id });
      return res.status(500).json({
        success: false,
        message: 'Failed to send verification email'
      });
    }

    res.status(202).json({
      success: true,
      message: 'OTP sent to your email'
    });

  } catch (error) {
    console.error('Registration error:', error);
    
    // Handle network/database connection errors
    if (error.name === 'MongoNetworkError' || error.code === 'EAI_AGAIN') {
      return res.status(503).json({
        success: false,
        message: 'Database connection error. Please try again later.'
      });
    }
    
    // Handle duplicate key error specifically
    if (error.code === 11000) {
      console.log('Duplicate key error for email:', normalizedEmail);
      // Check if it's an email duplicate or _id duplicate
      if (error.message.includes('email')) {
        return res.status(400).json({
          success: false,
          message: 'User already exists with this email'
        });
      } else {
        // _id duplicate - retry with new ObjectId
        console.log('ObjectId collision detected, this is very rare');
        return res.status(500).json({
          success: false,
          message: 'Registration failed due to system conflict. Please try again.'
        });
      }
    }
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: `Validation error: ${validationErrors.join(', ')}`
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Server error during registration'
    });
  }
});

// Verify OTP endpoint
router.post('/verify-otp', validateOTP, async (req, res) => {
  try {
    const { email, otp } = req.body;
    const normalizedEmail = email.toLowerCase().trim();

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Account already verified'
      });
    }

    if (user.isOTPExpired()) {
      return res.status(400).json({
        success: false,
        message: 'OTP has expired'
      });
    }

    const isValidOTP = await user.compareOTP(otp);
    if (!isValidOTP) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // Verify user and clear OTP fields
    user.isVerified = true;
    user.otpHash = null;
    user.otpExpires = null;
    user.otpAttempts = 0;
    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({
      success: true,
      message: 'Account verified successfully',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name
      },
      subscription: {
        status: user.subscriptionStatus || 'none',
        plan: user.subscriptionPlan || null,
        startDate: user.subscriptionStartDate || null,
        endDate: user.subscriptionEndDate || null,
        features: {
          liveStream: false,
          motionDetection: false,
          facialRecognition: false,
          visitorProfile: false
        }
      }
    });

  } catch (error) {
    console.error('OTP verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during verification'
    });
  }
});

// Login endpoint
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.toLowerCase().trim();

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    if (!user.isVerified) {
      return res.status(401).json({
        success: false,
        message: 'Please verify your email first'
      });
    }

    const isValidPassword = await user.comparePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    // Get subscription details
    const UserSubscription = require('../models/UserSubscription');
    const subscription = await UserSubscription.findOne({
      userId: user._id,
      status: 'active'
    });

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name
      },
      subscription: {
        status: user.subscriptionStatus || 'none',
        plan: user.subscriptionPlan || null,
        startDate: user.subscriptionStartDate || null,
        endDate: user.subscriptionEndDate || null,
        features: subscription ? subscription.features : {
          liveStream: false,
          motionDetection: false,
          facialRecognition: false,
          visitorProfile: false
        }
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// Resend OTP endpoint
router.post('/resend-otp', otpLimiter, async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Account already verified'
      });
    }

    if (!user.canRequestOTP()) {
      return res.status(429).json({
        success: false,
        message: 'Too many OTP requests. Please try again later.'
      });
    }

    // Generate new OTP
    const otp = generateOTP();
    const otpHash = await hashOTP(otp);
    const otpExpires = getOTPExpiry();

    user.otpHash = otpHash;
    user.otpExpires = otpExpires;
    user.lastOtpRequest = new Date();
    user.otpAttempts = (user.otpAttempts || 0) + 1;
    await user.save();

    // Send OTP email
    const emailSent = await sendOTPEmail(email, otp, user.name);
    if (!emailSent) {
      return res.status(500).json({
        success: false,
        message: 'Failed to send verification email'
      });
    }

    res.json({
      success: true,
      message: 'New OTP sent to your email'
    });

  } catch (error) {
    console.error('Resend OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Forgot Password - Send OTP
router.post('/forgot-password', otpLimiter, async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // Check if user exists and is verified
    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !user.isVerified) {
      return res.status(404).json({
        success: false,
        message: 'Invalid credentials or user not found'
      });
    }

    if (!user.canRequestOTP()) {
      return res.status(429).json({
        success: false,
        message: 'Too many OTP requests. Please try again later.'
      });
    }

    // Generate and hash OTP
    const otp = generateOTP();
    const otpHash = await hashOTP(otp);
    const otpExpires = getOTPExpiry();

    user.resetOtpHash = otpHash;
    user.resetOtpExpires = otpExpires;
    user.lastOtpRequest = new Date();
    user.otpAttempts = (user.otpAttempts || 0) + 1;
    await user.save();

    // Send password reset OTP email
    const emailSent = await sendPasswordResetOTP(email, otp, user.name);
    if (!emailSent) {
      return res.status(500).json({
        success: false,
        message: 'Failed to send reset email'
      });
    }

    res.json({
      success: true,
      message: 'Password reset OTP sent to your email'
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Verify Password Reset OTP
router.post('/verify-reset-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Email and OTP are required'
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !user.isVerified) {
      return res.status(404).json({
        success: false,
        message: 'Invalid request'
      });
    }

    if (!user.resetOtpHash || !user.resetOtpExpires) {
      return res.status(400).json({
        success: false,
        message: 'No password reset request found'
      });
    }

    if (new Date() > user.resetOtpExpires) {
      return res.status(400).json({
        success: false,
        message: 'OTP has expired'
      });
    }

    const isValidOTP = await bcrypt.compare(otp, user.resetOtpHash);
    if (!isValidOTP) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // Generate reset token
    const resetToken = jwt.sign(
      { userId: user._id, email: user.email, type: 'password-reset' },
      process.env.JWT_SECRET,
      { expiresIn: '15m' } // Short-lived token
    );

    // Clear reset OTP
    user.resetOtpHash = null;
    user.resetOtpExpires = null;
    user.otpAttempts = 0;
    await user.save();

    res.json({
      success: true,
      message: 'OTP verified successfully',
      resetToken
    });

  } catch (error) {
    console.error('Reset OTP verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Reset Password with Token
router.post('/reset-password', async (req, res) => {
  try {
    const { resetToken, newPassword } = req.body;

    if (!resetToken || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Reset token and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    // Verify reset token
    let decoded;
    try {
      decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
      if (decoded.type !== 'password-reset') {
        throw new Error('Invalid token type');
      }
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired reset token'
      });
    }

    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    user.passwordHash = passwordHash;
    user.resetOtpHash = null;
    user.resetOtpExpires = null;
    user.otpAttempts = 0;
    await user.save();

    res.json({
      success: true,
      message: 'Password reset successfully'
    });

  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Verify Token endpoint for debugging
router.get('/verify-token', async (req, res) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      message: 'Token is valid',
      user: {
        id: user._id,
        email: user.email,
        name: user.name
      }
    });

  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ success: false, message: 'Invalid token' });
  }
});

// Resend Password Reset OTP
router.post('/resend-reset-otp', otpLimiter, async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !user.isVerified) {
      return res.status(404).json({
        success: false,
        message: 'Invalid credentials or user not found'
      });
    }

    if (!user.canRequestOTP()) {
      return res.status(429).json({
        success: false,
        message: 'Too many OTP requests. Please try again later.'
      });
    }

    // Generate new OTP
    const otp = generateOTP();
    const otpHash = await hashOTP(otp);
    const otpExpires = getOTPExpiry();

    user.resetOtpHash = otpHash;
    user.resetOtpExpires = otpExpires;
    user.lastOtpRequest = new Date();
    user.otpAttempts = (user.otpAttempts || 0) + 1;
    await user.save();

    // Send OTP email
    const emailSent = await sendPasswordResetOTP(email, otp, user.name);
    if (!emailSent) {
      return res.status(500).json({
        success: false,
        message: 'Failed to send reset email'
      });
    }

    res.json({
      success: true,
      message: 'New OTP sent to your email'
    });

  } catch (error) {
    console.error('Resend reset OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Check email availability
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }
    
    const normalizedEmail = email.toLowerCase().trim();
    const existingUser = await User.findOne({ email: normalizedEmail });
    
    if (existingUser) {
      return res.json({
        success: false,
        available: false,
        message: existingUser.isVerified ? 'Email is already registered and verified' : 'Email is registered but not verified',
        isVerified: existingUser.isVerified
      });
    }
    
    res.json({
      success: true,
      available: true,
      message: 'Email is available'
    });
    
  } catch (error) {
    console.error('Email check error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Delete user (for testing purposes)
router.delete('/delete-user/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const normalizedEmail = email.toLowerCase().trim();
    
    const result = await User.deleteOne({ email: normalizedEmail });
    
    if (result.deletedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      message: 'User deleted successfully'
    });
    
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;