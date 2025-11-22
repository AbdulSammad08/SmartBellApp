const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendOTPEmail, sendPasswordResetOTP } = require('../utils/emailService');
const { generateOTP, hashOTP, getOTPExpiry } = require('../utils/otpGenerator');
const { validateRegister, validateLogin, validateOTP } = require('../middleware/validation');
const { otpLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

// Register endpoint
router.post('/register', validateRegister, async (req, res) => {
  try {
    const { email, password, name } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
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
        const emailSent = await sendOTPEmail(email, otp, name);
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

    // Create user
    const user = new User({
      email,
      passwordHash,
      name,
      otpHash,
      otpExpires,
      lastOtpRequest: new Date(),
      otpAttempts: 1
    });

    await user.save();

    // Send OTP email
    const emailSent = await sendOTPEmail(email, otp, name);
    if (!emailSent) {
      await User.deleteOne({ _id: user._id });
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
    
    // Handle duplicate key error specifically
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email'
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

    const user = await User.findOne({ email });
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

    const user = await User.findOne({ email });
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

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name
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

    const user = await User.findOne({ email });
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
    const user = await User.findOne({ email });
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

    const user = await User.findOne({ email });
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

    const user = await User.findOne({ email });
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

module.exports = router;