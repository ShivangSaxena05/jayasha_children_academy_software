class Student {
  final String id;
  final String rollNumber;
  final String name;
  final String className;
  final String parentName;
  final String age;
  final String contact;
  final double pendingAmount;
  final String status;

  Student({
    required this.id,
    required this.rollNumber,
    required this.name,
    required this.className,
    required this.parentName,
    required this.age,
    required this.contact,
    required this.pendingAmount,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      rollNumber: json['rollNumber'] as String,
      name: json['name'] as String,
      className: json['className'] as String,
      parentName: json['parentName'] as String,
      age: json['age'] as String,
      contact: json['contact'] as String,
      pendingAmount: double.tryParse(json['pendingAmount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rollNumber': rollNumber,
      'name': name,
      'className': className,
      'parentName': parentName,
      'age': age,
      'contact': contact,
      'pendingAmount': pendingAmount,
      'status': status,
    };
  }

  Student copyWith({
    String? id,
    String? rollNumber,
    String? name,
    String? className,
    String? parentName,
    String? age,
    String? contact,
    double? pendingAmount,
    String? status,
  }) {
    return Student(
      id: id ?? this.id,
      rollNumber: rollNumber ?? this.rollNumber,
      name: name ?? this.name,
      className: className ?? this.className,
      parentName: parentName ?? this.parentName,
      age: age ?? this.age,
      contact: contact ?? this.contact,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      status: status ?? this.status,
    );
  }
}
