const mongoose = require('mongoose');

const subscriptionPlanSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  price: {
    type: mongoose.Schema.Types.Mixed,
    required: true,
    get: function(value) {
      return typeof value === 'string' ? parseFloat(value) : value;
    }
  },
  duration: {
    type: String,
    required: true,
    enum: ['monthly', 'yearly']
  },
  features: [{
    type: String,
    required: true
  }],
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  toJSON: { getters: true },
  toObject: { getters: true }
});

module.exports = mongoose.model('SubscriptionPlan', subscriptionPlanSchema, 'subscriptions');