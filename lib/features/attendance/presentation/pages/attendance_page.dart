import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/attendance/data/repositories/attendance_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();
  dynamic _selectedClass;
  List<dynamic> _classes = [];
  List<StudentAdmission> _students = [];
  Map<String, String> _attendanceStatus = {}; // studentId -> status
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final classRepo = Provider.of<ClassRepository>(context, listen: false);
      final classes = await classRepo.getClasses();
      setState(() {
        _classes = classes;
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);
    try {
      final studentRepo = Provider.of<StudentRepository>(context, listen: false);
      final attRepo = Provider.of<AttendanceRepository>(context, listen: false);

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Get all students of the class
      final students = await studentRepo.getStudents();
      final classStudents = students.where((s) => s.currentClassId == _selectedClass['_id']).toList();

      // Get existing attendance if any
      final attResponse = await attRepo.getAttendanceByClass(_selectedClass['_id'], dateStr);

      final Map<String, String> existingAtt = {};
      if (attResponse['success'] == true) {
        for (var record in attResponse['data']) {
          existingAtt[record['student']['_id']] = record['status'];
        }
      }

      setState(() {
        _students = classStudents;
        _attendanceStatus = { for (var s in classStudents) s.id! : existingAtt[s.id!] ?? 'Present' };
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null || _students.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final attRepo = Provider.of<AttendanceRepository>(context, listen: false);
      final dashRepo = Provider.of<DashboardRepository>(context, listen: false);
      final session = await dashRepo.getCurrentSession();

      if (session == null) throw Exception('Active academic session not found');

      final records = _attendanceStatus.entries.map((e) => {
        'studentId': e.key,
        'classId': _selectedClass['_id'],
        'status': e.value,
        'remarks': ''
      }).toList();

      final response = await attRepo.markAttendance(
        attendanceRecords: records,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        sessionId: session.id!,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                ? _buildEmptyState()
                : _buildAttendanceList(),
          ),
          if (_students.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Mark and track daily student attendance', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _students.isEmpty || _isSaving ? null : _saveAttendance,
          icon: _isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
          label: const Text('Save Attendance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<dynamic>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text('${c['name']} - ${c['section']}'))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedClass = val;
                      _students = [];
                    });
                    _loadStudents();
                  },
                  hint: const Text('Choose Class'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadStudents();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMM, yyyy').format(_selectedDate)),
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedClass == null ? 'Please select a class to mark attendance' : 'No students found in this class',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.grey.shade50,
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('Roll', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _students.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = _students[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text(student.rollNumber ?? 'N/A')),
                      Expanded(flex: 3, child: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusButton(student.id!, 'Present', Colors.green),
                            const SizedBox(width: 8),
                            _buildStatusButton(student.id!, 'Absent', Colors.red),
                            const SizedBox(width: 8),
                            _buildStatusButton(student.id!, 'Late', Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String studentId, String status, Color color) {
    final isSelected = _attendanceStatus[studentId] == status;
    return InkWell(
      onTap: () => setState(() => _attendanceStatus[studentId] = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final present = _attendanceStatus.values.where((v) => v == 'Present').length;
    final absent = _attendanceStatus.values.where((v) => v == 'Absent').length;
    final late = _attendanceStatus.values.where((v) => v == 'Late').length;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('Total: ${_students.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Present: $present', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          Text('Absent: $absent', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Text('Late: $late', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
