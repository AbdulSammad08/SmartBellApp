const mongoose = require('mongoose');

const ownershipTransferSchema = new mongoose.Schema({
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
  currentOwner: {
    type: String,
    required: true
  },
  newOwner: {
    type: String,
    required: true
  },
  propertyAddress: {
    type: String,
    required: true
  },
  reason: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Add index for sorting
ownershipTransferSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('OwnershipTransfer', ownershipTransferSchema);