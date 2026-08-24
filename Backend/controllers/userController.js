const User = require('../models/User');
const Principal = require('../models/Principal');
const Teacher = require('../models/Teacher');
const AcademicSession = require('../models/AcademicSession');
const Class = require('../models/Class');
const Student = require('../models/Student');
const FeePayment = require('../models/FeePayment');
const FeeStructure = require('../models/FeeStructure');
const generateToken = require('../utils/generateToken');

// @desc    Reset all data (Dev only)
// @route   POST /api/users/reset-setup
// @access  Public
const resetSetup = async (req, res) => {
  try {
    // Clear all collections
    await Promise.all([
      User.deleteMany({}),
      Principal.deleteMany({}),
      Teacher.deleteMany({}),
      AcademicSession.deleteMany({}),
      Class.deleteMany({}),
      Student.deleteMany({}),
      FeePayment.deleteMany({}),
      FeeStructure.deleteMany({}),
    ]);
    res.json({ message: 'All data cleared successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server Error' });
  }
};

// @desc    Check if the school has been set up (any user exists)
// @route   GET /api/users/check-setup
// @access  Public
const checkSetup = async (req, res) => {
  try {
    const userCount = await User.countDocuments({});
    res.json({ isSetup: userCount > 0 });
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Initial Setup for Principal
// @route   POST /api/users/setup
// @access  Public
const setupPrincipal = async (req, res) => {
  const { name, securityPin, principalDetails } = req.body;

  try {
    const userExists = await User.findOne({ role: 'principal' });
    if (userExists) {
      return res.status(400).json({ message: 'Principal already setup. Please login.' });
    }

    // Create the User (Login Credentials - PIN only)
    const user = await User.create({
      name,
      securityPin,
      role: 'principal',
    });

    if (user) {
      // Create the Principal profile linked to the user
      await Principal.create({
        user: user._id,
        ...principalDetails,
        name: name,
      });

      res.status(201).json({
        _id: user._id,
        name: user.name,
        token: generateToken(user._id),
      });
    } else {
      res.status(400).json({ message: 'Invalid principal data' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server Error' });
  }
};

// @desc    Login with Security PIN (Subsequent logins)
// @route   POST /api/users/pin-login
// @access  Public
const loginWithPin = async (req, res) => {
  const { securityPin } = req.body;

  try {
    // Since there's only one Principal, we find the first one
    const user = await User.findOne({ role: 'principal' });

    if (user && (await user.matchPin(securityPin))) {
      res.json({
        _id: user._id,
        name: user.name,
        role: user.role,
        token: generateToken(user._id),
      });
    } else {
      res.status(401).json({ message: 'Invalid Security PIN' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get Current User Profile (Principal)
// @route   GET /api/users/profile
// @access  Private
const getProfile = async (req, res) => {
  try {
    const principal = await Principal.findOne({ user: req.user._id });
    if (principal) {
      res.json(principal);
    } else {
      res.status(404).json({ message: 'Principal profile not found' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Update Principal Profile
// @route   PUT /api/users/profile
// @access  Private
const updateProfile = async (req, res) => {
  try {
    const principal = await Principal.findOne({ user: req.user._id });
    if (principal) {
      Object.assign(principal, req.body);
      const updatedPrincipal = await principal.save();
      res.json(updatedPrincipal);
    } else {
      res.status(404).json({ message: 'Principal profile not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message || 'Server Error' });
  }
};

module.exports = {
  checkSetup,
  setupPrincipal,
  loginWithPin,
  getProfile,
  updateProfile,
  resetSetup,
};
