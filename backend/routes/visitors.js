const express = require('express');
const router = express.Router();
const Visitor = require('../models/Visitor');
const auth = require('../middleware/auth');
const { requireSubscription, requireFeature } = require('../middleware/subscriptionAuth');
const blobService = require('../services/blobService');
const { v4: uuidv4 } = require('uuid');

// Get user's visitors
router.get('/user', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    console.log('Fetching visitors for user:', userId);
    const visitors = await Visitor.find({ userId }).sort({ createdAt: -1 });
    console.log('Found visitors:', visitors.length);
    
    // Convert Azure URLs to proxy URLs
    const processedVisitors = visitors.map(visitor => {
      const visitorObj = visitor.toObject();
      if (visitorObj.imageUrl && visitorObj.imageFileName) {
        // Convert Azure URL to proxy URL
        visitorObj.imageUrl = `${process.env.SERVER_BASE_URL || 'http://192.168.100.183:8080'}/api/images/${visitorObj.imageFileName}`;
      }
      return visitorObj;
    });
    
    res.json({
      success: true,
      data: processedVisitors
    });
  } catch (error) {
    console.error('Error fetching visitors:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

// Create new visitor
router.post('/create', auth, async (req, res) => {
  try {
    const { name, email, phone, address, purpose, relationship, profileImage } = req.body;
    const userId = req.user.userId;
    
    let imageUrl = null;
    let imageFileName = null;
    
    // Upload image to Azure Blob Storage if provided
    if (profileImage) {
      try {
        const imageBuffer = Buffer.from(profileImage.split(',')[1], 'base64');
        imageFileName = `${uuidv4()}.jpg`;
        imageUrl = await blobService.uploadImage(imageBuffer, imageFileName);
      } catch (imageError) {
        return res.status(400).json({
          success: false,
          message: 'Failed to upload image: ' + imageError.message
        });
      }
    }

    const visitor = new Visitor({
      userId,
      name,
      email,
      phone,
      address,
      purpose,
      relationship,
      imageUrl,
      imageFileName
    });

    const savedVisitor = await visitor.save();
    
    // Convert response to use proxy URL
    const responseData = savedVisitor.toObject();
    if (responseData.imageUrl && responseData.imageFileName) {
      responseData.imageUrl = `${process.env.SERVER_BASE_URL || 'http://192.168.100.183:8080'}/api/images/${responseData.imageFileName}`;
    }
    
    res.json({
      success: true,
      message: 'Visitor profile created successfully',
      data: responseData
    });
  } catch (error) {
    console.error('Error creating visitor:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

// Update visitor
router.put('/update/:visitorId', auth, async (req, res) => {
  try {
    const { visitorId } = req.params;
    const { name, email, phone, address, purpose, relationship, profileImage } = req.body;
    const userId = req.user.userId;

    const visitor = await Visitor.findOne({ _id: visitorId, userId });
    if (!visitor) {
      return res.status(404).json({
        success: false,
        message: 'Visitor not found'
      });
    }

    const updateData = { name, email, phone, address, purpose, relationship };
    
    // Handle new image upload
    if (profileImage) {
      try {
        // Delete old image if exists
        if (visitor.imageFileName) {
          await blobService.deleteImage(visitor.imageFileName);
        }
        
        // Upload new image
        const imageBuffer = Buffer.from(profileImage.split(',')[1], 'base64');
        const imageFileName = `${uuidv4()}.jpg`;
        const imageUrl = await blobService.uploadImage(imageBuffer, imageFileName);
        
        updateData.imageUrl = imageUrl;
        updateData.imageFileName = imageFileName;
      } catch (imageError) {
        return res.status(400).json({
          success: false,
          message: 'Failed to upload image: ' + imageError.message
        });
      }
    }

    const updatedVisitor = await Visitor.findOneAndUpdate(
      { _id: visitorId, userId },
      updateData,
      { new: true }
    );

    if (!updatedVisitor) {
      return res.status(404).json({
        success: false,
        message: 'Visitor not found or you do not have permission to update it'
      });
    }

    // Convert response to use proxy URL
    const responseData = updatedVisitor.toObject();
    if (responseData.imageUrl && responseData.imageFileName) {
      responseData.imageUrl = `${process.env.SERVER_BASE_URL || 'http://192.168.100.183:8080'}/api/images/${responseData.imageFileName}`;
    }
    
    res.json({
      success: true,
      message: 'Visitor profile updated successfully',
      data: responseData
    });
  } catch (error) {
    console.error('Error updating visitor:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

// Delete visitor
router.delete('/delete/:visitorId', auth, async (req, res) => {
  try {
    const { visitorId } = req.params;
    const userId = req.user.userId;

    console.log('Deleting visitor:', visitorId, 'for user:', userId);

    const deletedVisitor = await Visitor.findOneAndDelete({ _id: visitorId, userId });

    if (!deletedVisitor) {
      return res.status(404).json({
        success: false,
        message: 'Visitor not found'
      });
    }

    // Delete image from blob storage if exists
    if (deletedVisitor.imageFileName) {
      await blobService.deleteImage(deletedVisitor.imageFileName);
    }

    res.json({
      success: true,
      message: 'Visitor profile deleted successfully',
      data: deletedVisitor
    });
  } catch (error) {
    console.error('Error deleting visitor:', error);
    res.status(500).json({
      success: false,
      message: 'Server error: ' + error.message
    });
  }
});

module.exports = router;