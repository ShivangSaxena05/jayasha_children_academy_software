import 'package:flutter/foundation.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/fee_payment.dart';

class FeeRepository extends ChangeNotifier {
  // Mock data for now, will be replaced with real persistence later
  final List<Student> _students = [
    Student(id: '1', rollNumber: '101', name: 'Aryan Sharma', className: 'Class 5', parentName: 'Deepak Sharma', age: '10', contact: '9876543210', pendingAmount: 2500, status: 'Pending'),
    Student(id: '2', rollNumber: '102', name: 'Sneha Gupta', className: 'Class 2', parentName: 'Amit Gupta', age: '7', contact: '9876543211', pendingAmount: 0, status: 'Paid'),
    Student(id: '3', rollNumber: '103', name: 'Rahul Verma', className: 'Class 8', parentName: 'Sanjay Verma', age: '13', contact: '9876543212', pendingAmount: 4200, status: 'Overdue'),
    Student(id: '4', rollNumber: '104', name: 'Priya Singh', className: 'Class 5', parentName: 'Rajesh Singh', age: '10', contact: '9876543213', pendingAmount: 1800, status: 'Pending'),
  ];

  final List<FeePayment> _payments = [];

  List<Student> get students => List.unmodifiable(_students);
  List<FeePayment> get payments => List.unmodifiable(_payments);

  Student? findStudentByRoll(String roll) {
    try {
      return _students.firstWhere((s) => s.rollNumber == roll);
    } catch (e) {
      return null;
    }
  }

  void addPayment(FeePayment payment) {
    _payments.add(payment);

    // Update student pending amount
    final index = _students.indexWhere((s) => s.id == payment.studentId);
    if (index != -1) {
      final student = _students[index];
      double newPending = student.pendingAmount - payment.amount;
      String newStatus = newPending <= 0 ? 'Paid' : 'Pending';

      _students[index] = student.copyWith(
        pendingAmount: newPending < 0 ? 0 : newPending,
        status: newStatus,
      );
    }

    notifyListeners();
  }

  void addStudent(Student student) {
    _students.add(student);
    notifyListeners();
  }

  List<FeePayment> getStudentPayments(String studentId) {
    return _payments.where((p) => p.studentId == studentId).toList();
  }
}
