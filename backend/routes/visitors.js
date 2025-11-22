const express = require('express');
const router = express.Router();
const Visitor = require('../models/Visitor');
const auth = require('../middleware/auth');

// Get user's visitors
router.get('/user', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    console.log('Fetching visitors for user:', userId);
    const visitors = await Visitor.find({ userId }).sort({ createdAt: -1 });
    console.log('Found visitors:', visitors.length);
    
    res.json({
      success: true,
      data: visitors
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
    const { name, email, phone, address, purpose, relationship } = req.body;
    const userId = req.user.id || req.user._id;
    
    console.log('Creating visitor for user:', userId);
    console.log('Visitor data:', { name, email, phone, address, purpose, relationship });

    const visitor = new Visitor({
      userId,
      name,
      email,
      phone,
      address,
      purpose,
      relationship
    });

    const savedVisitor = await visitor.save();
    console.log('Visitor created successfully:', savedVisitor._id);
    
    res.json({
      success: true,
      message: 'Visitor profile created successfully',
      data: savedVisitor
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
    const { name, email, phone, address, purpose, relationship } = req.body;
    const userId = req.user.id || req.user._id;

    console.log('Updating visitor:', visitorId, 'for user:', userId);

    const updatedVisitor = await Visitor.findOneAndUpdate(
      { _id: visitorId, userId },
      { name, email, phone, address, purpose, relationship },
      { new: true }
    );

    if (!updatedVisitor) {
      return res.status(404).json({
        success: false,
        message: 'Visitor not found or you do not have permission to update it'
      });
    }

    console.log('Visitor updated successfully:', updatedVisitor._id);

    res.json({
      success: true,
      message: 'Visitor profile updated successfully',
      data: updatedVisitor
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
    const userId = req.user.id || req.user._id;

    console.log('Deleting visitor:', visitorId, 'for user:', userId);

    const deletedVisitor = await Visitor.findOneAndDelete({ _id: visitorId, userId });

    if (!deletedVisitor) {
      return res.status(404).json({
        success: false,
        message: 'Visitor not found or you do not have permission to delete it'
      });
    }

    console.log('Visitor deleted successfully:', deletedVisitor._id);

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