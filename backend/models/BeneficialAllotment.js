const mongoose = require('mongoose');

const beneficialAllotmentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  userEmail: {
    type: String,
    required: true
  },
  beneficiaryName: {
    type: String,
    required: true
  },
  allotmentType: {
    type: String,
    required: true
  },
  sharePercentage: {
    type: Number,
    required: true
  },
  effectiveDate: {
    type: Date,
    required: true
  }
}, {
  timestamps: true
});

// Add index for sorting
beneficialAllotmentSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('BeneficialAllotment', beneficialAllotmentSchema);