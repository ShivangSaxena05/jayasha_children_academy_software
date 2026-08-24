import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateCertificate({
    required StudentAdmission student,
    required String type,
    Map<String, dynamic>? details,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'JAYASHA CHILDREN\'S ACADEMY',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Affiliated to CBSE, New Delhi', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 40),
                pw.Text(
                  type.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 60),
                pw.Paragraph(
                  text:
                      'This is to certify that Master/Miss ${student.name}, son/daughter of Mr. ${student.fatherName}, is/was a bonafide student of this school studying in section ${student.section ?? 'N/A'} during the session ${details?['session'] ?? '2023-24'}.',
                  style: pw.TextStyle(fontSize: 16, lineSpacing: 5),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 40),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'His/Her date of birth according to the school records is ${DateFormat('dd-MM-yyyy').format(DateTime.parse(student.dob))}.',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                        pw.Text('Place: School Office'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text('Principal Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<pw.Document> _buildFeeReceiptPdf({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('FEE RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                    pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(payment.date)}'),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('Student Name: ${student.name}'),
                pw.Text('Admission No: ${student.admissionNumber}'),
                pw.Text('Section: ${student.section ?? 'N/A'}'),
                pw.Text('Session: ${sessionName ?? 'N/A'}'),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Amount (Rs.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(payment.category.name.toUpperCase())),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(payment.amount.toStringAsFixed(2))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Total: Rs. ${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Payment Mode: ${payment.mode.name.toUpperCase()}'),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Cashier Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> generateFeeReceipt({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
  }) async {
    final pdf = await _buildFeeReceiptPdf(student: student, payment: payment, sessionName: sessionName);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> downloadFeeReceipt({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
  }) async {
    final pdf = await _buildFeeReceiptPdf(student: student, payment: payment, sessionName: sessionName);
    final bytes = await pdf.save();

    // Printing.sharePdf shows the native share/save sheet which handles "Downloading" locally
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Receipt_${student.admissionNumber}_${DateFormat('yyyyMMdd').format(payment.date)}.pdf'
    );
  }

  static Future<void> generateReportCard({
    required dynamic markRecord,
  }) async {
    final pdf = pw.Document();
    final student = markRecord['student'];
    final exam = markRecord['exam'];
    final className = markRecord['class']['name'];
    final marks = markRecord['subjectMarks'] as List;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
            child: pw.Column(
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('JAYASHA CHILDREN\'S ACADEMY', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('PROGRESS REPORT', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
                      pw.Text(exam['name'], style: pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Name: ${student['name']}'),
                        pw.Text('Admission No: ${student['admissionNumber']}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Class: $className'),
                        pw.Text('Roll No: ${student['rollNumber'] ?? 'N/A'}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Subject', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Max Marks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Marks Obtained', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...marks.map((m) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['subject'])),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['maxMarks'].toString())),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['totalMarks'].toString())),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Obtained: ${markRecord['totalObtained']}'),
                    pw.Text('Percentage: ${markRecord['percentage'].toStringAsFixed(2)}%'),
                    pw.Text('Result: ${markRecord['result']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Class Teacher'),
                    pw.Text('Principal'),
                    pw.Text('Parent'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
