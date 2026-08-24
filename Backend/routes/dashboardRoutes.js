const express = require('express');
const router = express.Router();
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Class = require('../models/Class');
const FeeStructure = require('../models/FeeStructure');
const FeePayment = require('../models/FeePayment');
const { protect } = require('../middlewares/authMiddleware');

router.get('/stats', protect, async (req, res) => {
  try {
    const studentCount = await Student.countDocuments({ status: 'active' });
    const teacherCount = await Teacher.countDocuments({ status: 'active' });
    const classCount = await Class.countDocuments();

    // 1. Calculate Total Collection (Actual Payments)
    const payments = await FeePayment.find();
    const totalCollection = payments.reduce((sum, p) => sum + p.amount, 0);

    // 2. Calculate Expected Collection
    // Get all active students and their classes
    const activeStudents = await Student.find({ status: 'active' }).populate('currentClass');
    const feeStructures = await FeeStructure.find();

    let expectedCollection = 0;
    activeStudents.forEach(student => {
      const structure = feeStructures.find(fs => String(fs.class) === String(student.currentClass._id));
      if (structure && structure.components) {
        structure.components.forEach(comp => {
          if (comp.frequency === 'monthly') {
            expectedCollection += (comp.amount * 12); // Annual expectation
          } else {
            expectedCollection += comp.amount;
          }
        });
      }
    });

    const pendingFeesCount = Math.max(0, studentCount - payments.length); // Very simple heuristic

    const recentStudents = await Student.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('currentClass', 'name');

    res.json({
      success: true,
      data: {
        counts: {
          students: studentCount,
          teachers: teacherCount,
          classes: classCount,
          totalCollection: totalCollection,
          expectedCollection: expectedCollection,
          pendingFeesCount: pendingFeesCount
        },
        recentStudents,
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
