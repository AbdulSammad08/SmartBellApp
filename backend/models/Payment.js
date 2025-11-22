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
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Payment', paymentSchema);