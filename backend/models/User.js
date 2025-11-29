const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  passwordHash: {
    type: String,
    required: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  otpHash: {
    type: String,
    default: null
  },
  otpExpires: {
    type: Date,
    default: null
  },
  otpAttempts: {
    type: Number,
    default: 0
  },
  lastOtpRequest: {
    type: Date,
    default: null
  },
  resetOtpHash: {
    type: String,
    default: null
  },
  resetOtpExpires: {
    type: Date,
    default: null
  },
  subscriptionStatus: {
    type: String,
    enum: ['none', 'pending', 'active', 'expired'],
    default: 'none'
  },
  subscriptionPlan: {
    type: String,
    enum: ['basic', 'premium', 'business', null],
    default: null
  },
  subscriptionStartDate: {
    type: Date,
    default: null
  },
  subscriptionEndDate: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

userSchema.methods.comparePassword = async function(password) {
  return bcrypt.compare(password, this.passwordHash);
};

userSchema.methods.compareOTP = async function(otp) {
  if (!this.otpHash) return false;
  return bcrypt.compare(otp, this.otpHash);
};

userSchema.methods.isOTPExpired = function() {
  return !this.otpExpires || new Date() > this.otpExpires;
};

userSchema.methods.canRequestOTP = function() {
  if (!this.lastOtpRequest) return true;
  
  const hourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const recentRequests = this.otpAttempts || 0;
  
  if (this.lastOtpRequest < hourAgo) {
    return true;
  }
  
  return recentRequests < parseInt(process.env.MAX_OTP_REQUESTS_PER_HOUR || 3);
};

module.exports = mongoose.model('User', userSchema, 'users_v2');