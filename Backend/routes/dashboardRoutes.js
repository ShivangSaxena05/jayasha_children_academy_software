const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Class = require('../models/Class');
const FeeStructure = require('../models/FeeStructure');
const FeePayment = require('../models/FeePayment');
const Attendance = require('../models/Attendance');
const { protect } = require('../middlewares/authMiddleware');

router.get('/stats', protect, async (req, res) => {
  try {
    const studentCount = await Student.countDocuments({ status: 'active' });
    const teacherCount = await Teacher.countDocuments({ status: 'active' });
    const classCount = await Class.countDocuments();

    // 1. Calculate Total Collection (Actual Payments)
    const payments = await FeePayment.find();
    const totalCollection = payments.reduce((sum, p) => sum + p.amount, 0);

    // Get recent students for both cases
    const recentStudents = await Student.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('currentClass', 'name');

    // 2. Calculate Expected Collection based on ACTIVE Session
    const activeSession = await mongoose.model('AcademicSession').findOne({ isActive: true });

    if (activeSession) {
      const activeStudents = await Student.find({
        status: 'active',
        academicSession: activeSession._id
      });

      const feeStructures = await FeeStructure.find({
        academicSession: activeSession._id
      });

      // Map fee structures by classId for faster lookup
      const feeMap = {};
      feeStructures.forEach(fs => {
        feeMap[fs.class.toString()] = fs.components;
      });

      let expectedCollection = 0;
      activeStudents.forEach(student => {
        const components = feeMap[student.currentClass.toString()];
        if (components) {
          components.forEach(comp => {
            if (comp.frequency === 'monthly') {
              expectedCollection += (comp.amount * 12);
            } else {
              expectedCollection += comp.amount;
            }
          });
        }
      });

      // 3. Pending Fees Calculation
      const studentsWithPayments = await FeePayment.distinct('student', {
        academicSession: activeSession._id
      });
      const pendingFeesCount = activeStudents.length - studentsWithPayments.length;

      // 4. Attendance Stats
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todayAttendance = await Attendance.find({
        date: { $gte: today, $lt: tomorrow },
        session: activeSession._id
      });

      let attendancePercentage = 0;
      if (todayAttendance.length > 0) {
        const presentCount = todayAttendance.filter(a => a.status === 'Present' || a.status === 'Late').length;
        attendancePercentage = (presentCount / todayAttendance.length) * 100;
      }

      res.json({
        success: true,
        data: {
          counts: {
            students: studentCount,
            teachers: teacherCount,
            classes: classCount,
            totalCollection: totalCollection,
            expectedCollection: expectedCollection,
            pendingFeesCount: pendingFeesCount,
            attendancePercentage: Math.round(attendancePercentage)
          },
          recentStudents,
        }
      });
    } else {
      res.json({
        success: true,
        data: {
          counts: {
            students: studentCount,
            teachers: teacherCount,
            classes: classCount,
            totalCollection: totalCollection,
            expectedCollection: 0,
            pendingFeesCount: 0,
            attendancePercentage: 0
          },
          recentStudents,
        }
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server Error',
      error: error.message
    });
  }
});

module.exports = router;
