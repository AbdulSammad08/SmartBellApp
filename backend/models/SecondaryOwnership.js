const mongoose = require('mongoose');

const secondaryOwnershipSchema = new mongoose.Schema({
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
  secondaryOwnerName: {
    type: String,
    required: true
  },
  ownershipPercentage: {
    type: Number,
    required: true
  },
  relationshipType: {
    type: String,
    required: true
  },
  documentNumber: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Add index for sorting
secondaryOwnershipSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('SecondaryOwnership', secondaryOwnershipSchema);