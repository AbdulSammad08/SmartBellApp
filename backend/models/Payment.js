const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  userName: {
    type: String,
    required: true,
    trim: true
  },
  contactNumber: {
    type: String,
    required: true,
    trim: true
  },
  receiptFile: {
    type: String, // File path/URL
    required: true
  },
  receiptFileName: {
    type: String, // Azure blob file name
    required: false
  },
  planSelected: {
    type: String,
    required: true
  },
  billingCycle: {
    type: String,
    enum: ['monthly', 'yearly'],
    required: true
  },
  finalAmount: {
    type: Number,
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    trim: true
  },
  deviceId: {
    type: String,
    required: true,
    trim: true,
    validate: {
      validator: function(v) {
        return /^[A-Za-z0-9]{12}$/.test(v);
      },
      message: 'Device ID must be exactly 12 alphanumeric characters'
    }
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'confirmed'],
    default: 'pending'
  },
  approvedBy: {
    type: String,
    default: null
  },
  approvedAt: {
    type: Date,
    default: null
  },
  rejectionReason: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Payment', paymentSchema);