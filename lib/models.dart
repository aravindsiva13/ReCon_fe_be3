// import 'package:flutter/material.dart';

// // Reconciliation Status Enum
// enum ReconciliationStatus {
//   perfect,
//   investigate,
//   manualRefund,
//   missing;

//   String get label {
//     switch (this) {
//       case ReconciliationStatus.perfect:
//         return 'Perfect';
//       case ReconciliationStatus.investigate:
//         return 'Investigate';
//       case ReconciliationStatus.manualRefund:
//         return 'Manual Refund';
//       case ReconciliationStatus.missing:
//         return 'Missing';
//     }
//   }

//   Color get color {
//     switch (this) {
//       case ReconciliationStatus.perfect:
//         return Colors.green;
//       case ReconciliationStatus.investigate:
//         return Colors.orange;
//       case ReconciliationStatus.manualRefund:
//         return Colors.blue;
//       case ReconciliationStatus.missing:
//         return Colors.red;
//     }
//   }

//   IconData get icon {
//     switch (this) {
//       case ReconciliationStatus.perfect:
//         return Icons.check_circle;
//       case ReconciliationStatus.investigate:
//         return Icons.warning;
//       case ReconciliationStatus.manualRefund:
//         return Icons.build;
//       case ReconciliationStatus.missing:
//         return Icons.error;
//     }
//   }
// }

// // Transaction Type Enum
// enum TransactionType {
//   payment,
//   refund,
//   mixed;

//   String get label {
//     switch (this) {
//       case TransactionType.payment:
//         return 'Payment';
//       case TransactionType.refund:
//         return 'Refund';
//       case TransactionType.mixed:
//         return 'Mixed';
//     }
//   }

//   Color get color {
//     switch (this) {
//       case TransactionType.payment:
//         return Colors.green;
//       case TransactionType.refund:
//         return Colors.red;
//       case TransactionType.mixed:
//         return Colors.blue;
//     }
//   }
// }

// // Transaction Model
// class TransactionModel {
//   final String txnRefNo;
//   final String txnMachine;
//   final String txnMid;
//   final double ptppPayment;
//   final double ptppRefund;
//   final double ptppNetAmount;
//   final double cloudPayment;
//   final double cloudRefund;
//   final double cloudMRefund;
//   final double cloudNetAmount;
//   final double systemDifference;
//   final bool hasDiscrepancy;
//   final double discrepancyAmount;
//   final String remarks;
//   final ReconciliationStatus status;
//   final TransactionType transactionType;
//   final String? additionalRemarks;

//   final String txnSource;
//   final String txnType;
//   final String txnDate;
//   final double txnAmount;

//   // Computed properties for backward compatibility
//   double get netAmount => ptppNetAmount; // Alias for ptppNetAmount
//   TransactionType? get txnType => transactionType; // Alias

//   TransactionModel({
//     required this.txnRefNo,
//     required this.txnMachine,
//     required this.txnMid,
//     required this.ptppPayment,
//     required this.ptppRefund,
//     required this.ptppNetAmount,
//     required this.cloudPayment,
//     required this.cloudRefund,
//     required this.cloudMRefund,
//     required this.cloudNetAmount,
//     required this.systemDifference,
//     required this.hasDiscrepancy,
//     required this.discrepancyAmount,
//     required this.remarks,
//     required this.status,
//     required this.transactionType,
//     this.additionalRemarks,
//   });

//   // Factory constructor for creating TransactionModel from Excel row (existing functionality)
//   factory TransactionModel.fromExcelRow(
//     List<dynamic> row,
//     ReconciliationStatus status, {
//     String? additionalRemarks,
//   }) {
//     try {
//       // Safely parse numeric values
//       double parseDouble(dynamic value, {double defaultValue = 0.0}) {
//         if (value == null) return defaultValue;
//         if (value is double) return value;
//         if (value is int) return value.toDouble();
//         if (value is String) {
//           final cleanValue = value.replaceAll(',', '').trim();
//           return double.tryParse(cleanValue) ?? defaultValue;
//         }
//         return defaultValue;
//       }

//       // Extract values from Excel row
//       String txnRefNo = row.isNotEmpty ? (row[0]?.toString() ?? '') : '';
//       String txnMachine = row.length > 1 ? (row[1]?.toString() ?? '') : '';
//       String txnMid = row.length > 2 ? (row[2]?.toString() ?? '') : '';

//       double ptppPayment = row.length > 3 ? parseDouble(row[3]) : 0.0;
//       double ptppRefund = row.length > 4 ? parseDouble(row[4]) : 0.0;
//       double cloudPayment = row.length > 5 ? parseDouble(row[5]) : 0.0;
//       double cloudRefund = row.length > 6 ? parseDouble(row[6]) : 0.0;
//       double cloudMRefund = row.length > 7 ? parseDouble(row[7]) : 0.0;

//       String remarks = row.length > 8 ? (row[8]?.toString() ?? '') : '';

//       // Calculate net amounts
//       double ptppNetAmount = ptppPayment + ptppRefund;
//       double cloudNetAmount = cloudPayment + cloudRefund + cloudMRefund;
//       double systemDifference = ptppNetAmount - cloudNetAmount;
//       bool hasDiscrepancy = systemDifference.abs() > 0.01;
//       double discrepancyAmount = hasDiscrepancy ? systemDifference.abs() : 0.0;

//       // Determine transaction type
//       TransactionType transactionType = TransactionType.payment;
//       if (ptppRefund != 0 || cloudRefund != 0 || cloudMRefund != 0) {
//         if (ptppPayment != 0 || cloudPayment != 0) {
//           transactionType = TransactionType.mixed;
//         } else {
//           transactionType = TransactionType.refund;
//         }
//       }

//       return TransactionModel(
//         txnRefNo: txnRefNo,
//         txnMachine: txnMachine,
//         txnMid: txnMid,
//         ptppPayment: ptppPayment,
//         ptppRefund: ptppRefund,
//         ptppNetAmount: ptppNetAmount,
//         cloudPayment: cloudPayment,
//         cloudRefund: cloudRefund,
//         cloudMRefund: cloudMRefund,
//         cloudNetAmount: cloudNetAmount,
//         systemDifference: systemDifference,
//         hasDiscrepancy: hasDiscrepancy,
//         discrepancyAmount: discrepancyAmount,
//         remarks: remarks.isNotEmpty ? remarks : additionalRemarks ?? '',
//         status: status,
//         transactionType: transactionType,
//         additionalRemarks: additionalRemarks,
//       );
//     } catch (e) {
//       print('Error creating TransactionModel from Excel row: $e');

//       // Return a minimal error transaction
//       return TransactionModel(
//         txnRefNo: 'ERROR',
//         txnMachine: 'ERROR',
//         txnMid: 'ERROR',
//         ptppPayment: 0.0,
//         ptppRefund: 0.0,
//         ptppNetAmount: 0.0,
//         cloudPayment: 0.0,
//         cloudRefund: 0.0,
//         cloudMRefund: 0.0,
//         cloudNetAmount: 0.0,
//         systemDifference: 0.0,
//         hasDiscrepancy: false,
//         discrepancyAmount: 0.0,
//         remarks: 'Error parsing row: $e',
//         status: ReconciliationStatus.missing,
//         transactionType: TransactionType.payment,
//         additionalRemarks: null,
//       );
//     }
//   }

//   // Factory constructor for creating TransactionModel from database row
//   factory TransactionModel.fromDatabaseRow(
//     Map<String, dynamic> row,
//     ReconciliationStatus status, {
//     String? additionalRemarks,
//   }) {
//     try {
//       // Safely parse numeric values with null checks
//       double parseDouble(dynamic value) {
//         if (value == null) return 0.0;
//         if (value is double) return value;
//         if (value is int) return value.toDouble();
//         if (value is String) {
//           final cleanValue = value.replaceAll(',', '').trim();
//           return double.tryParse(cleanValue) ?? 0.0;
//         }
//         return 0.0;
//       }

//       // Extract values from database row
//       String txnRefNo =
//           row['Txn_RefNo']?.toString() ?? row['txn_refno']?.toString() ?? '';
//       String txnMachine = row['Txn_Machine']?.toString() ??
//           row['txn_machine']?.toString() ??
//           '';
//       String txnMid =
//           row['Txn_MID']?.toString() ?? row['txn_mid']?.toString() ?? '';

//       double ptppPayment =
//           parseDouble(row['PTPP_Payment'] ?? row['ptpp_payment']);
//       double ptppRefund = parseDouble(row['PTPP_Refund'] ?? row['ptpp_refund']);
//       double cloudPayment =
//           parseDouble(row['Cloud_Payment'] ?? row['cloud_payment']);
//       double cloudRefund =
//           parseDouble(row['Cloud_Refund'] ?? row['cloud_refund']);
//       double cloudMRefund =
//           parseDouble(row['Cloud_MRefund'] ?? row['cloud_mrefund']);

//       String remarks = row['Remarks']?.toString() ??
//           row['remarks']?.toString() ??
//           additionalRemarks ??
//           '';

//       // Calculate net amounts
//       double ptppNetAmount = ptppPayment + ptppRefund;
//       double cloudNetAmount = cloudPayment + cloudRefund + cloudMRefund;
//       double systemDifference = ptppNetAmount - cloudNetAmount;
//       bool hasDiscrepancy = systemDifference.abs() >
//           0.01; // Consider amounts within 1 paisa as equal
//       double discrepancyAmount = hasDiscrepancy ? systemDifference.abs() : 0.0;

//       // Determine transaction type based on amounts
//       TransactionType transactionType = TransactionType.payment; // Default
//       if (ptppRefund != 0 || cloudRefund != 0 || cloudMRefund != 0) {
//         if (ptppPayment != 0 || cloudPayment != 0) {
//           transactionType = TransactionType.mixed;
//         } else {
//           transactionType = TransactionType.refund;
//         }
//       }

//       return TransactionModel(
//         txnRefNo: txnRefNo,
//         txnMachine: txnMachine,
//         txnMid: txnMid,
//         ptppPayment: ptppPayment,
//         ptppRefund: ptppRefund,
//         ptppNetAmount: ptppNetAmount,
//         cloudPayment: cloudPayment,
//         cloudRefund: cloudRefund,
//         cloudMRefund: cloudMRefund,
//         cloudNetAmount: cloudNetAmount,
//         systemDifference: systemDifference,
//         hasDiscrepancy: hasDiscrepancy,
//         discrepancyAmount: discrepancyAmount,
//         remarks: remarks,
//         status: status,
//         transactionType: transactionType,
//         additionalRemarks: additionalRemarks,
//       );
//     } catch (e) {
//       print('Error creating TransactionModel from database row: $e');
//       print('Row data: $row');

//       // Return a minimal transaction model with error indication
//       return TransactionModel(
//         txnRefNo: row['Txn_RefNo']?.toString() ??
//             row['txn_refno']?.toString() ??
//             'ERROR',
//         txnMachine: 'ERROR',
//         txnMid: 'ERROR',
//         ptppPayment: 0.0,
//         ptppRefund: 0.0,
//         ptppNetAmount: 0.0,
//         cloudPayment: 0.0,
//         cloudRefund: 0.0,
//         cloudMRefund: 0.0,
//         cloudNetAmount: 0.0,
//         systemDifference: 0.0,
//         hasDiscrepancy: false,
//         discrepancyAmount: 0.0,
//         remarks: 'Error parsing row: $e',
//         status: ReconciliationStatus.missing,
//         transactionType: TransactionType.payment,
//         additionalRemarks: null,
//       );
//     }
//   }

//   // Convert to Map for export
//   Map<String, dynamic> toMap() {
//     return {
//       'Txn_RefNo': txnRefNo,
//       'Txn_Machine': txnMachine,
//       'Txn_MID': txnMid,
//       'PTPP_Payment': ptppPayment,
//       'PTPP_Refund': ptppRefund,
//       'PTPP_Net_Amount': ptppNetAmount,
//       'Cloud_Payment': cloudPayment,
//       'Cloud_Refund': cloudRefund,
//       'Cloud_MRefund': cloudMRefund,
//       'Cloud_Net_Amount': cloudNetAmount,
//       'System_Difference': systemDifference,
//       'Has_Discrepancy': hasDiscrepancy,
//       'Discrepancy_Amount': discrepancyAmount,
//       'Remarks': remarks,
//       'Status': status.label,
//       'Transaction_Type': transactionType.label,
//       'Additional_Remarks': additionalRemarks,
//     };
//   }

//   @override
//   String toString() {
//     return 'TransactionModel(txnRefNo: $txnRefNo, status: ${status.label}, ptppNet: $ptppNetAmount, cloudNet: $cloudNetAmount, difference: $systemDifference)';
//   }
// }

// // Summary Statistics Model
// class SummaryStats {
//   final int totalTransactions;
//   final int perfectMatches;
//   final int investigateCount;
//   final int manualRefunds;
//   final double successRate;
//   final double totalAmount;
//   final double discrepancyAmount;
//   final double perfectPercentage;
//   final double investigatePercentage;
//   final double manualPercentage;

//   // Additional computed properties for backward compatibility
//   int get perfectCount => perfectMatches;
//   int get manualRefundCount => manualRefunds;
//   double get manualRefundPercentage => manualPercentage;

//   // PTPP system totals
//   double get ptppTotalPayments => totalAmount; // Simplified for now
//   double get ptppTotalRefunds => 0.0; // Will be calculated if needed
//   double get ptppNetAmount => totalAmount;

//   // Cloud system totals
//   double get cloudTotalPayments => totalAmount; // Simplified for now
//   double get cloudTotalRefunds => 0.0; // Will be calculated if needed
//   double get cloudNetAmount => totalAmount;

//   // System comparison
//   double get systemDifference => discrepancyAmount;
//   double get totalDiscrepancy => discrepancyAmount;

//   SummaryStats({
//     required this.totalTransactions,
//     required this.perfectMatches,
//     required this.investigateCount,
//     required this.manualRefunds,
//     required this.successRate,
//     required this.totalAmount,
//     required this.discrepancyAmount,
//     required this.perfectPercentage,
//     required this.investigatePercentage,
//     required this.manualPercentage,
//   });

//   // Factory constructor from list of transactions (existing functionality)
//   factory SummaryStats.fromTransactions(List<TransactionModel> transactions) {
//     int perfectMatches = 0;
//     int investigateCount = 0;
//     int manualRefunds = 0;
//     double totalAmount = 0.0;
//     double discrepancyAmount = 0.0;

//     for (var transaction in transactions) {
//       switch (transaction.status) {
//         case ReconciliationStatus.perfect:
//           perfectMatches++;
//           break;
//         case ReconciliationStatus.investigate:
//           investigateCount++;
//           discrepancyAmount += transaction.discrepancyAmount;
//           break;
//         case ReconciliationStatus.manualRefund:
//           manualRefunds++;
//           break;
//         case ReconciliationStatus.missing:
//           // Count as investigate for calculation purposes
//           investigateCount++;
//           break;
//       }
//       totalAmount += transaction.ptppNetAmount;
//     }

//     int totalTransactions = transactions.length;
//     double successRate = totalTransactions > 0
//         ? (perfectMatches / totalTransactions * 100)
//         : 0.0;
//     double perfectPercentage = totalTransactions > 0
//         ? (perfectMatches / totalTransactions * 100)
//         : 0.0;
//     double investigatePercentage = totalTransactions > 0
//         ? (investigateCount / totalTransactions * 100)
//         : 0.0;
//     double manualPercentage =
//         totalTransactions > 0 ? (manualRefunds / totalTransactions * 100) : 0.0;

//     return SummaryStats(
//       totalTransactions: totalTransactions,
//       perfectMatches: perfectMatches,
//       investigateCount: investigateCount,
//       manualRefunds: manualRefunds,
//       successRate: successRate,
//       totalAmount: totalAmount,
//       discrepancyAmount: discrepancyAmount,
//       perfectPercentage: perfectPercentage,
//       investigatePercentage: investigatePercentage,
//       manualPercentage: manualPercentage,
//     );
//   }

//   // Factory constructor from API response
//   factory SummaryStats.fromApiResponse(Map<String, dynamic> apiData) {
//     try {
//       final summary = apiData['summary'] ?? {};

//       return SummaryStats(
//         totalTransactions: (summary['total_transactions'] ?? 0).toInt(),
//         perfectMatches: (summary['perfect_matches'] ?? 0).toInt(),
//         investigateCount: (summary['investigate_count'] ?? 0).toInt(),
//         manualRefunds: (summary['manual_refunds'] ?? 0).toInt(),
//         successRate: (summary['success_rate'] ?? 0.0).toDouble(),
//         totalAmount: (summary['total_amount'] ?? 0.0).toDouble(),
//         discrepancyAmount: (summary['discrepancy_amount'] ?? 0.0).toDouble(),
//         perfectPercentage: (summary['perfect_percentage'] ?? 0.0).toDouble(),
//         investigatePercentage:
//             (summary['investigate_percentage'] ?? 0.0).toDouble(),
//         manualPercentage: (summary['manual_percentage'] ?? 0.0).toDouble(),
//       );
//     } catch (e) {
//       print('Error creating SummaryStats from API response: $e');
//       return SummaryStats(
//         totalTransactions: 0,
//         perfectMatches: 0,
//         investigateCount: 0,
//         manualRefunds: 0,
//         successRate: 0.0,
//         totalAmount: 0.0,
//         discrepancyAmount: 0.0,
//         perfectPercentage: 0.0,
//         investigatePercentage: 0.0,
//         manualPercentage: 0.0,
//       );
//     }
//   }

//   @override
//   String toString() {
//     return 'SummaryStats(total: $totalTransactions, perfect: $perfectMatches, investigate: $investigateCount, manual: $manualRefunds, successRate: ${successRate.toStringAsFixed(1)}%)';
//   }
// }

// // Filter Model
// class FilterModel {
//   final ReconciliationStatus? status;
//   final TransactionType? transactionType;
//   final String? searchQuery;
//   final double? minAmount;
//   final double? maxAmount;
//   final DateTime? startDate;
//   final DateTime? endDate;
//   final bool showDiscrepanciesOnly;

//   // Computed property for backward compatibility
//   bool? get hasDiscrepancy => showDiscrepanciesOnly ? true : null;

//   FilterModel({
//     this.status,
//     this.transactionType,
//     this.searchQuery,
//     this.minAmount,
//     this.maxAmount,
//     this.startDate,
//     this.endDate,
//     this.showDiscrepanciesOnly = false,
//   });

//   FilterModel copyWith({
//     ReconciliationStatus? status,
//     TransactionType? transactionType,
//     String? searchQuery,
//     double? minAmount,
//     double? maxAmount,
//     DateTime? startDate,
//     DateTime? endDate,
//     bool? showDiscrepanciesOnly,
//   }) {
//     return FilterModel(
//       status: status ?? this.status,
//       transactionType: transactionType ?? this.transactionType,
//       searchQuery: searchQuery ?? this.searchQuery,
//       minAmount: minAmount ?? this.minAmount,
//       maxAmount: maxAmount ?? this.maxAmount,
//       startDate: startDate ?? this.startDate,
//       endDate: endDate ?? this.endDate,
//       showDiscrepanciesOnly:
//           showDiscrepanciesOnly ?? this.showDiscrepanciesOnly,
//     );
//   }

//   bool get hasActiveFilters {
//     return status != null ||
//         transactionType != null ||
//         (searchQuery != null && searchQuery!.isNotEmpty) ||
//         minAmount != null ||
//         maxAmount != null ||
//         startDate != null ||
//         endDate != null ||
//         showDiscrepanciesOnly;
//   }
// }

// // Export Settings Model
// class ExportSettings {
//   final bool includeCalculatedFields;
//   final bool includeSummary;
//   final List<ReconciliationStatus> statusFilter;
//   final String fileName;

//   ExportSettings({
//     this.includeCalculatedFields = true,
//     this.includeSummary = true,
//     this.statusFilter = const [],
//     this.fileName = 'reconciliation_export',
//   });
// }

//2

import 'package:flutter/material.dart';

// Reconciliation Status Enum
enum ReconciliationStatus {
  perfect,
  investigate,
  manualRefund,
  missing;

  String get label {
    switch (this) {
      case ReconciliationStatus.perfect:
        return 'Perfect';
      case ReconciliationStatus.investigate:
        return 'Investigate';
      case ReconciliationStatus.manualRefund:
        return 'Manual Refund';
      case ReconciliationStatus.missing:
        return 'Missing';
    }
  }

  Color get color {
    switch (this) {
      case ReconciliationStatus.perfect:
        return Colors.green;
      case ReconciliationStatus.investigate:
        return Colors.orange;
      case ReconciliationStatus.manualRefund:
        return Colors.blue;
      case ReconciliationStatus.missing:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ReconciliationStatus.perfect:
        return Icons.check_circle;
      case ReconciliationStatus.investigate:
        return Icons.warning;
      case ReconciliationStatus.manualRefund:
        return Icons.build;
      case ReconciliationStatus.missing:
        return Icons.error;
    }
  }
}

// Transaction Type Enum
enum TransactionType {
  payment,
  refund,
  mixed;

  String get label {
    switch (this) {
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.mixed:
        return 'Mixed';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.payment:
        return Colors.green;
      case TransactionType.refund:
        return Colors.red;
      case TransactionType.mixed:
        return Colors.blue;
    }
  }
}

// Transaction Model
class TransactionModel {
  final String txnRefNo;
  final String txnMachine;
  final String txnMid;
  final double ptppPayment;
  final double ptppRefund;
  final double ptppNetAmount;
  final double cloudPayment;
  final double cloudRefund;
  final double cloudMRefund;
  final double cloudNetAmount;
  final double systemDifference;
  final bool hasDiscrepancy;
  final double discrepancyAmount;
  final String remarks;
  final ReconciliationStatus status;
  final TransactionType transactionType;
  final String? additionalRemarks;

  // Additional fields for database support
  final String txnSource;
  final String txnType;
  final String txnDate;
  final double txnAmount;

  // Computed properties for backward compatibility
  double get netAmount => ptppNetAmount;

  TransactionModel({
    required this.txnRefNo,
    required this.txnMachine,
    required this.txnMid,
    required this.ptppPayment,
    required this.ptppRefund,
    required this.ptppNetAmount,
    required this.cloudPayment,
    required this.cloudRefund,
    required this.cloudMRefund,
    required this.cloudNetAmount,
    required this.systemDifference,
    required this.hasDiscrepancy,
    required this.discrepancyAmount,
    required this.remarks,
    required this.status,
    required this.transactionType,
    this.additionalRemarks,
    // Database fields with defaults
    this.txnSource = '',
    this.txnType = '',
    this.txnDate = '',
    this.txnAmount = 0.0,
  });

  // Factory constructor for creating TransactionModel from Excel row
  factory TransactionModel.fromExcelRow(
    List<dynamic> row,
    ReconciliationStatus status, {
    String? additionalRemarks,
  }) {
    try {
      // Safely parse numeric values
      double parseDouble(dynamic value, {double defaultValue = 0.0}) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final cleanValue = value.replaceAll(',', '').trim();
          return double.tryParse(cleanValue) ?? defaultValue;
        }
        return defaultValue;
      }

      // Extract values from Excel row
      String txnRefNo = row.isNotEmpty ? (row[0]?.toString() ?? '') : '';
      String txnMachine = row.length > 1 ? (row[1]?.toString() ?? '') : '';
      String txnMid = row.length > 2 ? (row[2]?.toString() ?? '') : '';

      double ptppPayment = row.length > 3 ? parseDouble(row[3]) : 0.0;
      double ptppRefund = row.length > 4 ? parseDouble(row[4]) : 0.0;
      double cloudPayment = row.length > 5 ? parseDouble(row[5]) : 0.0;
      double cloudRefund = row.length > 6 ? parseDouble(row[6]) : 0.0;
      double cloudMRefund = row.length > 7 ? parseDouble(row[7]) : 0.0;

      String remarks = row.length > 8 ? (row[8]?.toString() ?? '') : '';

      // Calculate net amounts
      double ptppNetAmount = ptppPayment + ptppRefund;
      double cloudNetAmount = cloudPayment + cloudRefund + cloudMRefund;
      double systemDifference = ptppNetAmount - cloudNetAmount;
      bool hasDiscrepancy = systemDifference.abs() > 0.01;
      double discrepancyAmount = hasDiscrepancy ? systemDifference.abs() : 0.0;

      // Determine transaction type
      TransactionType transactionType = TransactionType.payment;
      if (ptppRefund != 0 || cloudRefund != 0 || cloudMRefund != 0) {
        if (ptppPayment != 0 || cloudPayment != 0) {
          transactionType = TransactionType.mixed;
        } else {
          transactionType = TransactionType.refund;
        }
      }

      return TransactionModel(
        txnRefNo: txnRefNo,
        txnMachine: txnMachine,
        txnMid: txnMid,
        ptppPayment: ptppPayment,
        ptppRefund: ptppRefund,
        ptppNetAmount: ptppNetAmount,
        cloudPayment: cloudPayment,
        cloudRefund: cloudRefund,
        cloudMRefund: cloudMRefund,
        cloudNetAmount: cloudNetAmount,
        systemDifference: systemDifference,
        hasDiscrepancy: hasDiscrepancy,
        discrepancyAmount: discrepancyAmount,
        remarks: remarks.isNotEmpty ? remarks : additionalRemarks ?? '',
        status: status,
        transactionType: transactionType,
        additionalRemarks: additionalRemarks,
        txnSource: 'Excel',
        txnType: transactionType.label,
        txnDate: DateTime.now().toString().split(' ')[0],
        txnAmount: ptppNetAmount,
      );
    } catch (e) {
      print('Error creating TransactionModel from Excel row: $e');

      // Return a minimal error transaction
      return TransactionModel(
        txnRefNo: 'ERROR',
        txnMachine: 'ERROR',
        txnMid: 'ERROR',
        ptppPayment: 0.0,
        ptppRefund: 0.0,
        ptppNetAmount: 0.0,
        cloudPayment: 0.0,
        cloudRefund: 0.0,
        cloudMRefund: 0.0,
        cloudNetAmount: 0.0,
        systemDifference: 0.0,
        hasDiscrepancy: false,
        discrepancyAmount: 0.0,
        remarks: 'Error parsing row: $e',
        status: ReconciliationStatus.missing,
        transactionType: TransactionType.payment,
        additionalRemarks: null,
        txnSource: 'Excel',
        txnType: 'Error',
        txnDate: DateTime.now().toString(),
        txnAmount: 0.0,
      );
    }
  }

  // Factory constructor for creating TransactionModel from database row
  factory TransactionModel.fromDatabaseRow(
    Map<String, dynamic> row,
    ReconciliationStatus status, {
    String? additionalRemarks,
  }) {
    try {
      // Safely parse numeric values with null checks
      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final cleanValue = value.replaceAll(',', '').trim();
          return double.tryParse(cleanValue) ?? 0.0;
        }
        return 0.0;
      }

      // Extract values from database row
      String txnRefNo =
          row['Txn_RefNo']?.toString() ?? row['txn_refno']?.toString() ?? '';
      String txnMachine = row['Txn_Machine']?.toString() ??
          row['txn_machine']?.toString() ??
          '';
      String txnMid =
          row['Txn_MID']?.toString() ?? row['txn_mid']?.toString() ?? '';

      double ptppPayment =
          parseDouble(row['PTPP_Payment'] ?? row['ptpp_payment']);
      double ptppRefund = parseDouble(row['PTPP_Refund'] ?? row['ptpp_refund']);
      double cloudPayment =
          parseDouble(row['Cloud_Payment'] ?? row['cloud_payment']);
      double cloudRefund =
          parseDouble(row['Cloud_Refund'] ?? row['cloud_refund']);
      double cloudMRefund =
          parseDouble(row['Cloud_MRefund'] ?? row['cloud_mrefund']);

      // Extract database-specific fields
      String txnSource =
          row['Txn_Source']?.toString() ?? row['txn_source']?.toString() ?? '';
      String txnType =
          row['Txn_Type']?.toString() ?? row['txn_type']?.toString() ?? '';
      String txnDate =
          row['Txn_Date']?.toString() ?? row['txn_date']?.toString() ?? '';
      double txnAmount = parseDouble(row['Txn_Amount'] ?? row['txn_amount']);

      String remarks = row['Remarks']?.toString() ??
          row['remarks']?.toString() ??
          additionalRemarks ??
          '';

      // Calculate net amounts
      double ptppNetAmount = ptppPayment + ptppRefund;
      double cloudNetAmount = cloudPayment + cloudRefund + cloudMRefund;

      // If reconciliation data is missing, use txnAmount
      if (ptppNetAmount == 0.0 && cloudNetAmount == 0.0 && txnAmount != 0.0) {
        ptppNetAmount = txnAmount;
        cloudNetAmount = txnAmount;
        if (txnAmount > 0) {
          ptppPayment = txnAmount;
          cloudPayment = txnAmount;
        } else {
          ptppRefund = txnAmount.abs();
          cloudRefund = txnAmount.abs();
        }
      }

      double systemDifference = ptppNetAmount - cloudNetAmount;
      bool hasDiscrepancy = systemDifference.abs() > 0.01;
      double discrepancyAmount = hasDiscrepancy ? systemDifference.abs() : 0.0;

      // Determine transaction type based on amounts or txnType
      TransactionType transactionType = TransactionType.payment;
      if (txnType.toLowerCase().contains('refund')) {
        transactionType = TransactionType.refund;
      } else if (ptppRefund != 0 || cloudRefund != 0 || cloudMRefund != 0) {
        if (ptppPayment != 0 || cloudPayment != 0) {
          transactionType = TransactionType.mixed;
        } else {
          transactionType = TransactionType.refund;
        }
      }

      return TransactionModel(
        txnRefNo: txnRefNo,
        txnMachine: txnMachine,
        txnMid: txnMid,
        ptppPayment: ptppPayment,
        ptppRefund: ptppRefund,
        ptppNetAmount: ptppNetAmount,
        cloudPayment: cloudPayment,
        cloudRefund: cloudRefund,
        cloudMRefund: cloudMRefund,
        cloudNetAmount: cloudNetAmount,
        systemDifference: systemDifference,
        hasDiscrepancy: hasDiscrepancy,
        discrepancyAmount: discrepancyAmount,
        remarks: remarks,
        status: status,
        transactionType: transactionType,
        additionalRemarks: additionalRemarks,
        txnSource: txnSource,
        txnType: txnType,
        txnDate: txnDate,
        txnAmount: txnAmount,
      );
    } catch (e) {
      print('Error creating TransactionModel from database row: $e');
      print('Row data: $row');

      // Return a minimal transaction model with error indication
      return TransactionModel(
        txnRefNo: row['Txn_RefNo']?.toString() ??
            row['txn_refno']?.toString() ??
            'ERROR',
        txnMachine: 'ERROR',
        txnMid: 'ERROR',
        ptppPayment: 0.0,
        ptppRefund: 0.0,
        ptppNetAmount: 0.0,
        cloudPayment: 0.0,
        cloudRefund: 0.0,
        cloudMRefund: 0.0,
        cloudNetAmount: 0.0,
        systemDifference: 0.0,
        hasDiscrepancy: false,
        discrepancyAmount: 0.0,
        remarks: 'Error parsing row: $e',
        status: ReconciliationStatus.missing,
        transactionType: TransactionType.payment,
        additionalRemarks: null,
        txnSource: 'Database',
        txnType: 'Error',
        txnDate: DateTime.now().toString(),
        txnAmount: 0.0,
      );
    }
  }

  // Convert to Map for export
  Map<String, dynamic> toMap() {
    return {
      'Txn_RefNo': txnRefNo,
      'Txn_Machine': txnMachine,
      'Txn_MID': txnMid,
      'PTPP_Payment': ptppPayment,
      'PTPP_Refund': ptppRefund,
      'PTPP_Net_Amount': ptppNetAmount,
      'Cloud_Payment': cloudPayment,
      'Cloud_Refund': cloudRefund,
      'Cloud_MRefund': cloudMRefund,
      'Cloud_Net_Amount': cloudNetAmount,
      'System_Difference': systemDifference,
      'Has_Discrepancy': hasDiscrepancy,
      'Discrepancy_Amount': discrepancyAmount,
      'Remarks': remarks,
      'Status': status.label,
      'Transaction_Type': transactionType.label,
      'Additional_Remarks': additionalRemarks,
    };
  }

  @override
  String toString() {
    return 'TransactionModel(txnRefNo: $txnRefNo, status: ${status.label}, ptppNet: $ptppNetAmount, cloudNet: $cloudNetAmount, difference: $systemDifference)';
  }
}

// Summary Statistics Model
class SummaryStats {
  final int totalTransactions;
  final int perfectMatches;
  final int investigateCount;
  final int manualRefunds;
  final double successRate;
  final double totalAmount;
  final double discrepancyAmount;
  final double perfectPercentage;
  final double investigatePercentage;
  final double manualPercentage;

  // Additional computed properties for backward compatibility
  int get perfectCount => perfectMatches;
  int get manualRefundCount => manualRefunds;
  double get manualRefundPercentage => manualPercentage;

  // PTPP system totals
  double get ptppTotalPayments => totalAmount;
  double get ptppTotalRefunds => 0.0;
  double get ptppNetAmount => totalAmount;

  // Cloud system totals
  double get cloudTotalPayments => totalAmount;
  double get cloudTotalRefunds => 0.0;
  double get cloudNetAmount => totalAmount;

  // System comparison
  double get systemDifference => discrepancyAmount;
  double get totalDiscrepancy => discrepancyAmount;

  SummaryStats({
    required this.totalTransactions,
    required this.perfectMatches,
    required this.investigateCount,
    required this.manualRefunds,
    required this.successRate,
    required this.totalAmount,
    required this.discrepancyAmount,
    required this.perfectPercentage,
    required this.investigatePercentage,
    required this.manualPercentage,
  });

  // Factory constructor from list of transactions
  factory SummaryStats.fromTransactions(List<TransactionModel> transactions) {
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
          investigateCount++;
          break;
      }
      totalAmount += transaction.ptppNetAmount;
    }

    int totalTransactions = transactions.length;
    double successRate = totalTransactions > 0
        ? (perfectMatches / totalTransactions * 100)
        : 0.0;
    double perfectPercentage = totalTransactions > 0
        ? (perfectMatches / totalTransactions * 100)
        : 0.0;
    double investigatePercentage = totalTransactions > 0
        ? (investigateCount / totalTransactions * 100)
        : 0.0;
    double manualPercentage =
        totalTransactions > 0 ? (manualRefunds / totalTransactions * 100) : 0.0;

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

  // Factory constructor from API response
  factory SummaryStats.fromApiResponse(Map<String, dynamic> apiData) {
    try {
      final summary = apiData['summary'] ?? {};

      return SummaryStats(
        totalTransactions: (summary['total_transactions'] ?? 0).toInt(),
        perfectMatches: (summary['perfect_matches'] ?? 0).toInt(),
        investigateCount: (summary['investigate_count'] ?? 0).toInt(),
        manualRefunds: (summary['manual_refunds'] ?? 0).toInt(),
        successRate: (summary['success_rate'] ?? 0.0).toDouble(),
        totalAmount: (summary['total_amount'] ?? 0.0).toDouble(),
        discrepancyAmount: (summary['discrepancy_amount'] ?? 0.0).toDouble(),
        perfectPercentage: (summary['perfect_percentage'] ?? 0.0).toDouble(),
        investigatePercentage:
            (summary['investigate_percentage'] ?? 0.0).toDouble(),
        manualPercentage: (summary['manual_percentage'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      print('Error creating SummaryStats from API response: $e');
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
  }

  @override
  String toString() {
    return 'SummaryStats(total: $totalTransactions, perfect: $perfectMatches, investigate: $investigateCount, manual: $manualRefunds, successRate: ${successRate.toStringAsFixed(1)}%)';
  }
}

// Filter Model
class FilterModel {
  final ReconciliationStatus? status;
  final TransactionType? transactionType;
  final String? searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showDiscrepanciesOnly;

  // Computed property for backward compatibility
  bool? get hasDiscrepancy => showDiscrepanciesOnly ? true : null;

  FilterModel({
    this.status,
    this.transactionType,
    this.searchQuery,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.showDiscrepanciesOnly = false,
  });

  FilterModel copyWith({
    ReconciliationStatus? status,
    TransactionType? transactionType,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool? showDiscrepanciesOnly,
  }) {
    return FilterModel(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showDiscrepanciesOnly:
          showDiscrepanciesOnly ?? this.showDiscrepanciesOnly,
    );
  }

  bool get hasActiveFilters {
    return status != null ||
        transactionType != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        minAmount != null ||
        maxAmount != null ||
        startDate != null ||
        endDate != null ||
        showDiscrepanciesOnly;
  }
}

// Export Settings Model
class ExportSettings {
  final bool includeCalculatedFields;
  final bool includeSummary;
  final List<ReconciliationStatus> statusFilter;
  final String fileName;

  ExportSettings({
    this.includeCalculatedFields = true,
    this.includeSummary = true,
    this.statusFilter = const [],
    this.fileName = 'reconciliation_export',
  });
}
