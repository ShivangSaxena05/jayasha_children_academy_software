const express = require('express');
const router = express.Router();
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Class = require('../models/Class');
const FeeStructure = require('../models/FeeStructure');

router.get('/stats', async (req, res) => {
  try {
    const studentCount = await Student.countDocuments({ status: 'active' });
    const teacherCount = await Teacher.countDocuments({ status: 'active' });
    const classCount = await Class.countDocuments();

    // You can add more complex logic here for fee collection stats, etc.
    const recentStudents = await Student.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('currentClass', 'name');

    const recentTeachers = await Teacher.find()
      .sort({ createdAt: -1 })
      .limit(5);

    res.json({
      success: true,
      data: {
        counts: {
          students: studentCount,
          teachers: teacherCount,
          classes: classCount,
        },
        recentStudents,
        recentTeachers
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server Error',
      error: error.message
    });
  }
});

module.exports = router;
