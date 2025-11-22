const express = require('express');
const router = express.Router();
const OwnershipTransfer = require('../models/OwnershipTransfer');
const BeneficialAllotment = require('../models/BeneficialAllotment');
const SecondaryOwnership = require('../models/SecondaryOwnership');
const auth = require('../middleware/auth');

// Get user's requests
router.get('/user', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    console.log('Fetching requests for user:', userId);
    
    // Fetch requests without sorting first (Cosmos DB issue)
    const [ownershipTransfers, beneficialAllotments, secondaryOwnerships] = await Promise.all([
      OwnershipTransfer.find({ userId }),
      BeneficialAllotment.find({ userId }),
      SecondaryOwnership.find({ userId })
    ]);

    console.log('Found requests:', {
      ownershipTransfers: ownershipTransfers.length,
      beneficialAllotments: beneficialAllotments.length,
      secondaryOwnerships: secondaryOwnerships.length
    });

    const allRequests = [
      ...ownershipTransfers.map(req => ({ ...req.toObject(), type: 'Ownership Transfer' })),
      ...beneficialAllotments.map(req => ({ ...req.toObject(), type: 'Beneficial Allotment' })),
      ...secondaryOwnerships.map(req => ({ ...req.toObject(), type: 'Secondary Ownership' }))
    ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({
      success: true,
      data: allRequests
    });
  } catch (error) {
    console.error('Error fetching requests:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

// Submit new request
router.post('/submit', auth, async (req, res) => {
  try {
    console.log('Request received:', req.body);
    console.log('User:', req.user);
    
    const { requestType, requestData } = req.body;
    const userId = req.user.id;
    const userName = req.user.name;
    const userEmail = req.user.email;

    const baseData = { userId, userName, userEmail, ...requestData };
    console.log('Base data:', baseData);

    let savedRequest;
    switch (requestType) {
      case 'Ownership Transfer':
        savedRequest = await new OwnershipTransfer(baseData).save();
        break;
      case 'Beneficial Allotment':
        savedRequest = await new BeneficialAllotment(baseData).save();
        break;
      case 'Secondary Ownership':
        savedRequest = await new SecondaryOwnership(baseData).save();
        break;
      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid request type'
        });
    }

    console.log('Saved request:', savedRequest);
    res.json({
      success: true,
      message: 'Request submitted successfully',
      data: savedRequest
    });
  } catch (error) {
    console.error('Error submitting request:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

// Update existing request
router.put('/update/:requestId', auth, async (req, res) => {
  try {
    console.log('Update request received:', req.body);
    console.log('Request ID:', req.params.requestId);
    
    const { requestType, requestData } = req.body;
    const { requestId } = req.params;
    const userId = req.user.id;

    let updatedRequest;
    const updateData = { ...requestData };

    switch (requestType) {
      case 'Ownership Transfer':
        updatedRequest = await OwnershipTransfer.findOneAndUpdate(
          { _id: requestId, userId },
          updateData,
          { new: true }
        );
        break;
      case 'Beneficial Allotment':
        updatedRequest = await BeneficialAllotment.findOneAndUpdate(
          { _id: requestId, userId },
          updateData,
          { new: true }
        );
        break;
      case 'Secondary Ownership':
        updatedRequest = await SecondaryOwnership.findOneAndUpdate(
          { _id: requestId, userId },
          updateData,
          { new: true }
        );
        break;
      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid request type'
        });
    }

    if (!updatedRequest) {
      return res.status(404).json({
        success: false,
        message: 'Request not found or you do not have permission to update it'
      });
    }

    console.log('Updated request:', updatedRequest);
    res.json({
      success: true,
      message: 'Request updated successfully',
      data: updatedRequest
    });
  } catch (error) {
    console.error('Error updating request:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

// Cancel/Delete request
router.delete('/cancel/:requestId', auth, async (req, res) => {
  try {
    console.log('Cancel request received for ID:', req.params.requestId);
    
    const { requestId } = req.params;
    const userId = req.user.id;

    // Try to find and delete from all request types
    const [ownershipResult, beneficialResult, secondaryResult] = await Promise.all([
      OwnershipTransfer.findOneAndDelete({ _id: requestId, userId }),
      BeneficialAllotment.findOneAndDelete({ _id: requestId, userId }),
      SecondaryOwnership.findOneAndDelete({ _id: requestId, userId })
    ]);

    const deletedRequest = ownershipResult || beneficialResult || secondaryResult;

    if (!deletedRequest) {
      return res.status(404).json({
        success: false,
        message: 'Request not found or you do not have permission to cancel it'
      });
    }

    console.log('Cancelled request:', deletedRequest);
    res.json({
      success: true,
      message: 'Request cancelled successfully',
      data: deletedRequest
    });
  } catch (error) {
    console.error('Error cancelling request:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

module.exports = router;