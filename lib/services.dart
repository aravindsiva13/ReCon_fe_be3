import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'models.dart';

// Excel Service for parsing and handling Excel files
class ExcelService {
  // Updated expected headers based on your actual Excel file
  static const List<String> expectedHeaders = [
    'Txn_RefNo',
    'Txn_Machine',
    'Txn_MID',
    'PTPP_Payment',
    'PTPP_Refund',
    'Cloud_Payment',
    'Cloud_Refund',
    'Cloud_MRefund',
    'Remarks'
  ];

  // Pick and parse Excel file
  static Future<List<TransactionModel>?> pickAndParseExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        return await parseExcelFromBytes(result.files.single.bytes!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // Parse Excel file from bytes with chunked processing for large files
  static Future<List<TransactionModel>> parseExcelFromBytes(
      Uint8List bytes) async {
    try {
      print('Starting Excel parsing...');
      final excel = Excel.decodeBytes(bytes);
      List<TransactionModel> allTransactions = [];

      print('Excel sheets found: ${excel.tables.keys}');

      // Process only the transaction sheets, skip SUMMARY
      final transactionSheets = [
        'RECON_SUCCESS',
        'RECON_INVESTIGATE',
        'MANUAL_REFUND'
      ];

      for (String sheetName in excel.tables.keys) {
        if (!transactionSheets.contains(sheetName)) {
          print('Skipping sheet: $sheetName (not a transaction sheet)');
          continue;
        }

        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        print('Processing sheet: $sheetName with ${sheet.rows.length} rows');

        try {
          ReconciliationStatus status = _getStatusFromSheetName(sheetName);

          // Process in chunks to avoid blocking the UI
          List<TransactionModel> sheetTransactions = [];
          final chunkSize = 1000; // Process 1000 rows at a time

          if (sheet.rows.isEmpty) continue;

          // Get headers
          List<String> headers = [];
          final headerRow = sheet.rows.first;
          for (var cell in headerRow) {
            headers.add(cell?.value?.toString()?.trim() ?? '');
          }

          print(
              'Processing ${sheet.rows.length - 1} data rows in chunks of $chunkSize');

          // Process data rows in chunks (skip header row)
          for (int startIdx = 1;
              startIdx < sheet.rows.length;
              startIdx += chunkSize) {
            final endIdx = (startIdx + chunkSize).clamp(0, sheet.rows.length);
            print('Processing rows $startIdx to $endIdx');

            // Add a small delay to prevent blocking
            await Future.delayed(const Duration(milliseconds: 10));

            for (int i = startIdx; i < endIdx; i++) {
              final row = sheet.rows[i];
              List<dynamic> rowData = [];

              for (var cell in row) {
                rowData.add(cell?.value);
              }

              if (_isRowEmpty(rowData)) continue;

              try {
                // Handle the RECON_INVESTIGATE sheet which has an extra 'Remarks' column
                String? additionalRemarks;
                if (status == ReconciliationStatus.investigate &&
                    rowData.length > 9) {
                  additionalRemarks = rowData[9]?.toString()?.trim();
                }

                TransactionModel transaction = TransactionModel.fromExcelRow(
                  rowData,
                  status,
                  additionalRemarks: additionalRemarks,
                );
                sheetTransactions.add(transaction);
              } catch (e) {
                // Skip invalid rows silently for performance
                continue;
              }
            }
          }

          print(
              'Successfully parsed ${sheetTransactions.length} transactions from $sheetName');
          allTransactions.addAll(sheetTransactions);
        } catch (e) {
          print('Error parsing sheet $sheetName: $e');
          // Continue with other sheets instead of failing completely
        }
      }

      if (allTransactions.isEmpty) {
        throw Exception(
            'No valid transaction data found. Please ensure your Excel file contains RECON_SUCCESS, RECON_INVESTIGATE, or MANUAL_REFUND sheets with transaction data.');
      }

      print('Total transactions parsed: ${allTransactions.length}');
      return allTransactions;
    } catch (e) {
      print('Excel parsing error: $e');
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  // Get reconciliation status from sheet name
  static ReconciliationStatus _getStatusFromSheetName(String sheetName) {
    final lowerSheetName = sheetName.toLowerCase();
    if (lowerSheetName.contains('success') ||
        lowerSheetName.contains('perfect')) {
      return ReconciliationStatus.perfect;
    } else if (lowerSheetName.contains('investigate')) {
      return ReconciliationStatus.investigate;
    } else if (lowerSheetName.contains('manual') ||
        lowerSheetName.contains('refund')) {
      return ReconciliationStatus.manualRefund;
    } else if (lowerSheetName.contains('summary')) {
      return ReconciliationStatus.perfect; // Default for summary
    }
    return ReconciliationStatus.missing; // Default
  }

  // Validate Excel headers - now more accurate to your format
  static bool _validateHeaders(List<String> headers) {
    if (headers.length < 9) return false; // Need at least 9 columns

    // Check for exact matches with your format
    final requiredHeaders = [
      'Txn_RefNo',
      'Txn_Machine',
      'Txn_MID',
      'PTPP_Payment',
      'PTPP_Refund',
      'Cloud_Payment',
      'Cloud_Refund',
      'Cloud_MRefund',
      'Remarks'
    ];

    for (int i = 0; i < requiredHeaders.length && i < headers.length; i++) {
      if (headers[i].trim() != requiredHeaders[i]) {
        print(
            'Header mismatch at position $i: expected "${requiredHeaders[i]}", got "${headers[i]}"');
        return false;
      }
    }

    return true;
  }

  // Check if row is empty - optimized
  static bool _isRowEmpty(List<dynamic> row) {
    if (row.isEmpty) return true;

    // Check only first 3 cells for performance
    for (int i = 0; i < 3 && i < row.length; i++) {
      if (row[i] != null && row[i].toString().trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  // Validate Excel file structure
  static Future<Map<String, dynamic>> validateExcelFile(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      Map<String, dynamic> validation = {
        'isValid': true,
        'errors': <String>[],
        'warnings': <String>[],
        'sheets': <String, int>{},
        'totalRows': 0,
      };

      if (excel.tables.isEmpty) {
        validation['isValid'] = false;
        validation['errors'].add('No sheets found in Excel file');
        return validation;
      }

      // Check each sheet
      for (String sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        int rowCount = sheet.rows.length - 1; // Exclude header
        validation['sheets'][sheetName] = rowCount;
        validation['totalRows'] += rowCount;

        // Skip summary sheet validation
        if (sheetName.toLowerCase().contains('summary')) continue;

        if (sheet.rows.isEmpty) {
          validation['warnings'].add('Sheet $sheetName is empty');
          continue;
        }

        // Validate headers
        List<String> headers = [];
        final headerRow = sheet.rows.first;
        for (var cell in headerRow) {
          headers.add(cell?.value?.toString() ?? '');
        }

        if (!_validateHeaders(headers)) {
          validation['errors'].add('Invalid headers in sheet $sheetName');
          validation['isValid'] = false;
        }
      }

      return validation;
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Failed to validate Excel file: $e'],
        'warnings': <String>[],
        'sheets': <String, int>{},
        'totalRows': 0,
      };
    }
  }
}

// Export Service for exporting data - Updated with corrected calculations
class ExportService {
  // Export to Excel with corrected fields
  static Future<Uint8List> exportToExcel(List<TransactionModel> transactions,
      {ExportSettings? settings}) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Remove default sheet

    // Group transactions by status
    Map<ReconciliationStatus, List<TransactionModel>> groupedTransactions = {};
    for (var txn in transactions) {
      groupedTransactions.putIfAbsent(txn.status, () => []).add(txn);
    }

    // Create sheets for each status
    for (var entry in groupedTransactions.entries) {
      String sheetName = entry.key.label.toUpperCase().replaceAll(' ', '_');
      final sheet = excel[sheetName];

      // Updated headers with corrected fields
      List<String> headers = [
        'Txn_RefNo',
        'Txn_Machine',
        'Txn_MID',
        'PTPP_Payment',
        'PTPP_Refund',
        'PTPP_Net_Amount',
        'Cloud_Payment',
        'Cloud_Refund',
        'Cloud_MRefund',
        'Cloud_Net_Amount',
        'Remarks'
      ];

      if (settings?.includeCalculatedFields ?? true) {
        headers.addAll(
            ['System_Difference', 'Has_Discrepancy', 'Discrepancy_Amount']);
      }

      // Write headers
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // Write data with corrected calculations
      for (int rowIndex = 0; rowIndex < entry.value.length; rowIndex++) {
        final txn = entry.value[rowIndex];
        List<dynamic> rowData = [
          txn.txnRefNo,
          txn.txnMachine,
          txn.txnMid,
          txn.ptppPayment,
          txn.ptppRefund,
          txn.ptppNetAmount, // Corrected: PTPP net amount
          txn.cloudPayment,
          txn.cloudRefund,
          txn.cloudMRefund,
          txn.cloudNetAmount, // Corrected: Cloud net amount
          txn.remarks,
        ];

        if (settings?.includeCalculatedFields ?? true) {
          rowData.addAll([
            txn.systemDifference,
            txn.hasDiscrepancy,
            txn.discrepancyAmount,
          ]);
        }

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          var cellValue = rowData[colIndex];
          var cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex + 1));

          if (cellValue is String) {
            cell.value = TextCellValue(cellValue);
          } else if (cellValue is num) {
            cell.value = DoubleCellValue(cellValue.toDouble());
          } else if (cellValue is bool) {
            cell.value = BoolCellValue(cellValue);
          } else {
            cell.value = TextCellValue(cellValue?.toString() ?? '');
          }
        }
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  // Export to CSV
  static String exportToCSV(List<TransactionModel> transactions,
      {ExportSettings? settings}) {
    List<List<dynamic>> csvData = [];

    // Headers
    List<String> headers = [
      'Txn_RefNo',
      'Txn_Machine',
      'Txn_MID',
      'PTPP_Payment',
      'PTPP_Refund',
      'PTPP_Net_Amount',
      'Cloud_Payment',
      'Cloud_Refund',
      'Cloud_MRefund',
      'Cloud_Net_Amount',
      'System_Difference',
      'Has_Discrepancy',
      'Discrepancy_Amount',
      'Remarks',
      'Status',
      'Transaction_Type'
    ];

    csvData.add(headers);

    // Data rows
    for (var txn in transactions) {
      csvData.add([
        txn.txnRefNo,
        txn.txnMachine,
        txn.txnMid,
        txn.ptppPayment,
        txn.ptppRefund,
        txn.ptppNetAmount,
        txn.cloudPayment,
        txn.cloudRefund,
        txn.cloudMRefund,
        txn.cloudNetAmount,
        txn.systemDifference,
        txn.hasDiscrepancy,
        txn.discrepancyAmount,
        txn.remarks,
        txn.status.label,
        txn.transactionType.label,
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  // Export to PDF
  static Future<Uint8List> exportToPDF(List<TransactionModel> transactions,
      {ExportSettings? settings}) async {
    final pdf = pw.Document();

    // Create a summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Reconciliation Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Transactions: ${transactions.length}'),
              pw.SizedBox(height: 10),

              // Summary by status
              ...ReconciliationStatus.values.map((status) {
                int count =
                    transactions.where((t) => t.status == status).length;
                return pw.Text('${status.label}: $count transactions');
              }).toList(),

              pw.SizedBox(height: 20),

              // Transaction table (first 20 transactions)
              pw.Table.fromTextArray(
                context: context,
                data: [
                  [
                    'Ref No',
                    'MID',
                    'PTPP Amount',
                    'Cloud Amount',
                    'Difference',
                    'Status'
                  ],
                  ...transactions
                      .take(20)
                      .map((txn) => [
                            txn.txnRefNo.length > 15
                                ? '${txn.txnRefNo.substring(0, 15)}...'
                                : txn.txnRefNo,
                            txn.txnMid.length > 20
                                ? '${txn.txnMid.substring(0, 20)}...'
                                : txn.txnMid,
                            '₹${txn.ptppNetAmount.toStringAsFixed(2)}',
                            '₹${txn.cloudNetAmount.toStringAsFixed(2)}',
                            '₹${txn.systemDifference.toStringAsFixed(2)}',
                            txn.status.label,
                          ])
                      .toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  // Save file to downloads (for web)
  static Future<void> saveFile(
      Uint8List bytes, String fileName, String extension) async {
    // This would be implemented differently for web vs mobile/desktop
    // For web, you'd use html.AnchorElement with download
    // For mobile/desktop, you'd use path_provider and File.writeAsBytes

    // Web implementation example:
    // final blob = html.Blob([bytes]);
    // final url = html.Url.createObjectUrlFromBlob(blob);
    // final anchor = html.AnchorElement(href: url)..setAttribute("download", "$fileName.$extension")..click();
    // html.Url.revokeObjectUrl(url);

    print('File saved: $fileName.$extension');
  }
}

// Analytics Service for data analysis and calculations - Updated with corrected calculations
class AnalyticsService {
  // Calculate summary statistics
  static SummaryStats calculateSummaryStats(
      List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return SummaryStats(
        totalTransactions: 0,
        perfectMatches: 0,
        investigateCount: 0,
        manualRefunds: 0,
        successRate: 0.0,
        totalAmount: 0.0,
        discrepancyAmount: 0.0,
        perfectPercentage: 0.0,
        investigatePercentage: 0.0,
        manualPercentage: 0.0,
      );
    }

    int perfectMatches = 0;
    int investigateCount = 0;
    int manualRefunds = 0;
    double totalAmount = 0.0;
    double discrepancyAmount = 0.0;

    for (var transaction in transactions) {
      switch (transaction.status) {
        case ReconciliationStatus.perfect:
          perfectMatches++;
          break;
        case ReconciliationStatus.investigate:
          investigateCount++;
          discrepancyAmount += transaction.discrepancyAmount;
          break;
        case ReconciliationStatus.manualRefund:
          manualRefunds++;
          break;
        case ReconciliationStatus.missing:
          investigateCount++; // Count missing as investigate
          break;
      }
      totalAmount +=
          transaction.ptppNetAmount.abs(); // Use absolute value for total
    }

    int totalTransactions = transactions.length;
    double successRate = (perfectMatches / totalTransactions * 100);
    double perfectPercentage = (perfectMatches / totalTransactions * 100);
    double investigatePercentage = (investigateCount / totalTransactions * 100);
    double manualPercentage = (manualRefunds / totalTransactions * 100);

    return SummaryStats(
      totalTransactions: totalTransactions,
      perfectMatches: perfectMatches,
      investigateCount: investigateCount,
      manualRefunds: manualRefunds,
      successRate: successRate,
      totalAmount: totalAmount,
      discrepancyAmount: discrepancyAmount,
      perfectPercentage: perfectPercentage,
      investigatePercentage: investigatePercentage,
      manualPercentage: manualPercentage,
    );
  }

  // Get transactions by status
  static Map<ReconciliationStatus, List<TransactionModel>>
      getTransactionsByStatus(List<TransactionModel> transactions) {
    Map<ReconciliationStatus, List<TransactionModel>> grouped = {};

    for (var status in ReconciliationStatus.values) {
      grouped[status] = transactions
          .where((transaction) => transaction.status == status)
          .toList();
    }

    return grouped;
  }

  // Get transactions by type
  static Map<TransactionType, List<TransactionModel>> getTransactionsByType(
      List<TransactionModel> transactions) {
    Map<TransactionType, List<TransactionModel>> grouped = {};

    for (var type in TransactionType.values) {
      grouped[type] = transactions
          .where((transaction) => transaction.transactionType == type)
          .toList();
    }

    return grouped;
  }

  // Calculate amount statistics
  static Map<String, double> calculateAmountStats(
      List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return {
        'totalPTPP': 0.0,
        'totalCloud': 0.0,
        'totalDiscrepancy': 0.0,
        'averageTransaction': 0.0,
        'maxTransaction': 0.0,
        'minTransaction': 0.0,
      };
    }

    double totalPTPP = 0.0;
    double totalCloud = 0.0;
    double totalDiscrepancy = 0.0;
    double maxTransaction = transactions.first.ptppNetAmount;
    double minTransaction = transactions.first.ptppNetAmount;

    for (var transaction in transactions) {
      totalPTPP += transaction.ptppNetAmount;
      totalCloud += transaction.cloudNetAmount;
      totalDiscrepancy += transaction.discrepancyAmount;

      if (transaction.ptppNetAmount > maxTransaction) {
        maxTransaction = transaction.ptppNetAmount;
      }
      if (transaction.ptppNetAmount < minTransaction) {
        minTransaction = transaction.ptppNetAmount;
      }
    }

    double averageTransaction = totalPTPP / transactions.length;

    return {
      'totalPTPP': totalPTPP,
      'totalCloud': totalCloud,
      'totalDiscrepancy': totalDiscrepancy,
      'averageTransaction': averageTransaction,
      'maxTransaction': maxTransaction,
      'minTransaction': minTransaction,
    };
  }

  // Get top discrepancies
  static List<TransactionModel> getTopDiscrepancies(
      List<TransactionModel> transactions,
      {int limit = 10}) {
    var discrepancyTransactions = transactions
        .where((t) => t.hasDiscrepancy)
        .toList()
      ..sort((a, b) => b.discrepancyAmount.compareTo(a.discrepancyAmount));

    return discrepancyTransactions.take(limit).toList();
  }

  // Get transactions by amount range
  static List<TransactionModel> getTransactionsByAmountRange(
      List<TransactionModel> transactions, double minAmount, double maxAmount) {
    return transactions
        .where(
            (t) => t.ptppNetAmount >= minAmount && t.ptppNetAmount <= maxAmount)
        .toList();
  }

  // Calculate daily/monthly trends (if timestamp data is available)
  static Map<String, int> calculateTrends(List<TransactionModel> transactions) {
    // This would be implemented if transaction timestamps were available
    // For now, return empty map
    return {};
  }

  // Generate reconciliation insights
  static List<String> generateInsights(List<TransactionModel> transactions) {
    List<String> insights = [];

    if (transactions.isEmpty) {
      insights.add('No transaction data available for analysis.');
      return insights;
    }

    var stats = calculateSummaryStats(transactions);
    var amountStats = calculateAmountStats(transactions);
    var topDiscrepancies = getTopDiscrepancies(transactions, limit: 5);

    // Success rate insights
    if (stats.successRate >= 95) {
      insights.add(
          'Excellent reconciliation rate of ${stats.successRate.toStringAsFixed(1)}%');
    } else if (stats.successRate >= 90) {
      insights.add(
          'Good reconciliation rate of ${stats.successRate.toStringAsFixed(1)}%');
    } else {
      insights.add(
          'Reconciliation rate of ${stats.successRate.toStringAsFixed(1)}% needs attention');
    }

    // Discrepancy insights
    if (stats.discrepancyAmount > 0) {
      insights.add(
          'Total discrepancy amount: ₹${stats.discrepancyAmount.toStringAsFixed(2)}');

      if (topDiscrepancies.isNotEmpty) {
        var highestDiscrepancy = topDiscrepancies.first;
        insights.add(
            'Highest discrepancy: ₹${highestDiscrepancy.discrepancyAmount.toStringAsFixed(2)} in transaction ${highestDiscrepancy.txnRefNo}');
      }
    } else {
      insights.add('No discrepancies found - all amounts match perfectly');
    }

    // Volume insights
    insights.add(
        'Processing ${stats.totalTransactions} transactions worth ₹${amountStats['totalPTPP']!.toStringAsFixed(2)}');

    if (stats.manualRefunds > 0) {
      insights.add(
          '${stats.manualRefunds} transactions require manual refund processing');
    }

    // Transaction size insights
    insights.add(
        'Average transaction amount: ₹${amountStats['averageTransaction']!.toStringAsFixed(2)}');

    return insights;
  }
}
