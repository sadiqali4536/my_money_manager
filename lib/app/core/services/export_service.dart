import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction_model.dart';
import '../utils/currency_helper.dart';

class ExportService {
  /// Generate and share / print a detailed PDF financial report
  static Future<void> exportMonthlyReportPdf({
    required String monthTitle,
    required int salaryPaise,
    required int additionalIncomePaise,
    required int expensesPaise,
    required int savingsPaise,
    required int investmentsPaise,
    required int netCashPaise,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('My Money Manager',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Personal Finance & Salary Report',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(monthTitle,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 16),

            // Summary Grid
            pw.Text('Monthly Executive Summary',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Financial Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount (INR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                _buildTableRow('Take-Home Salary', CurrencyHelper.formatPaiseForPdf(salaryPaise)),
                _buildTableRow('Additional Income', CurrencyHelper.formatPaiseForPdf(additionalIncomePaise)),
                _buildTableRow('Total Actual Expenses', CurrencyHelper.formatPaiseForPdf(expensesPaise)),
                _buildTableRow('Savings Deposits', CurrencyHelper.formatPaiseForPdf(savingsPaise)),
                _buildTableRow('Investment Contributions', CurrencyHelper.formatPaiseForPdf(investmentsPaise)),
                _buildTableRow('Net Available Cash', CurrencyHelper.formatPaiseForPdf(netCashPaise), isHighlight: true),
              ],
            ),

            pw.SizedBox(height: 24),
            pw.Text('Transaction Ledger (${transactions.length} items)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  ],
                ),
                ...transactions.map((t) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateHelper.formatDate(t.transactionDate), style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t.type.nameString, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t.title, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyHelper.formatPaiseForPdf(t.amountPaise), style: const pw.TextStyle(fontSize: 9))),
                      ],
                    )),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MoneyManager_Report_$monthTitle.pdf',
    );
  }

  static pw.TableRow _buildTableRow(String title, String value, {bool isHighlight = false}) {
    return pw.TableRow(
      decoration: isHighlight ? const pw.BoxDecoration(color: PdfColors.teal50) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(title, style: pw.TextStyle(fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }

  /// Generate and share CSV Excel-compatible spreadsheet
  static Future<void> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Date,Type,Title,Amount (Paise),Amount (INR),Payment Method,Description');

    for (var t in transactions) {
      final safeTitle = '"${t.title.replaceAll('"', '""')}"';
      final safeDesc = '"${(t.description ?? '').replaceAll('"', '""')}"';
      final safeMethod = '"${(t.paymentMethod ?? '').replaceAll('"', '""')}"';
      buffer.writeln(
        '${t.id},${t.transactionDate.toIso8601String()},${t.type.nameString},$safeTitle,${t.amountPaise},${CurrencyHelper.paiseToRupees(t.amountPaise)},$safeMethod,$safeDesc',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/my_money_manager_transactions.csv');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My Money Manager Transaction Export (CSV)',
      ),
    );
  }
}
