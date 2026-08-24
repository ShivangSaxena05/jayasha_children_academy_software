class SalaryRecord {
  final String? id;
  final String teacherId;
  final int month;
  final int year;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double netSalary;
  final DateTime paymentDate;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? remarks;

  SalaryRecord({
    this.id,
    required this.teacherId,
    required this.month,
    required this.year,
    required this.baseSalary,
    this.allowances = 0,
    this.deductions = 0,
    required this.netSalary,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.remarks,
  });

  factory SalaryRecord.fromJson(Map<String, dynamic> json) {
    return SalaryRecord(
      id: json['_id'] ?? json['id'],
      teacherId: json['teacher'],
      month: json['month'],
      year: json['year'],
      baseSalary: (json['baseSalary'] ?? 0).toDouble(),
      allowances: (json['allowances'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentMethod: json['paymentMethod'],
      status: json['status'],
      transactionId: json['transactionId'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacher': teacherId,
      'month': month,
      'year': year,
      'baseSalary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': netSalary,
      'paymentMethod': paymentMethod,
      'remarks': remarks,
    };
  }
}
