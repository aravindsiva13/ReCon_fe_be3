// widgets.dart - Reusable Widgets
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:reconciliation_app/providers.dart';
import 'models.dart';
import 'providers.dart';

// Status Chip Widget
class StatusChip extends StatelessWidget {
  final ReconciliationStatus status;
  final bool showIcon;
  final double? fontSize;

  const StatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: fontSize ?? 14, color: status.color),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

// File Drop Zone Widget
class FileDropZone extends StatefulWidget {
  final VoidCallback? onTap;
  final Function(List<int> bytes, String fileName)? onFileDropped;
  final bool enabled;
  final String? helpText;

  const FileDropZone({
    super.key,
    this.onTap,
    this.onFileDropped,
    this.enabled = true,
    this.helpText,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<UploadStateProvider>(
      builder: (context, uploadProvider, child) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: widget.enabled ? widget.onTap : null,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isDragOver || uploadProvider.isDragOver
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: (_isDragOver || uploadProvider.isDragOver)
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.cardColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (uploadProvider.isUploading) ...[
                        CircularProgressIndicator(
                          value: uploadProvider.uploadProgress,
                        ),
                        const SizedBox(height: 16),
                        Text('Uploading ${uploadProvider.uploadedFileName}...'),
                        Text(
                          '${(uploadProvider.uploadProgress * 100).toInt()}%',
                        ),
                      ] else ...[
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop Excel file here or click to browse',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.helpText ??
                              'Supports .xlsx and .xls files (Max 50MB)',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (uploadProvider.uploadError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            uploadProvider.uploadError!,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _setDragOver(bool isDragOver) {
    setState(() {
      _isDragOver = isDragOver;
    });

    if (isDragOver) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}

// Filter Sidebar Widget
class FilterSidebar extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const FilterSidebar({super.key, required this.isVisible, this.onClose});

  @override
  State<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<FilterSidebar> {
  final TextEditingController _midController = TextEditingController();
  final TextEditingController _machineController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void dispose() {
    _midController.dispose();
    _machineController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Consumer2<FilterProvider, TransactionProvider>(
      builder: (context, filterProvider, transactionProvider, child) {
        final uniqueValues = transactionProvider.hasData
            ? transactionProvider.getUniqueValues()
            : <String, List<String>>{};

        return Container(
          width: 300,
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const Divider(),

              Expanded(
                child: ListView(
                  children: [
                    // Status Filter
                    _buildFilterSection(
                      'Status',
                      DropdownButtonFormField<ReconciliationStatus>(
                        value: filterProvider.currentFilter.status,
                        decoration: const InputDecoration(
                          hintText: 'Select status',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: ReconciliationStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: StatusChip(status: status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          filterProvider.updateStatus(value);
                          _applyFilters(filterProvider, transactionProvider);
                        },
                      ),
                    ),

                    // Transaction Type Filter
                    _buildFilterSection(
                      'Transaction Type',
                      DropdownButtonFormField<TransactionType>(
                        value: filterProvider.currentFilter.transactionType,
                        decoration: const InputDecoration(
                          hintText: 'Select type',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: TransactionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          filterProvider.updateTransactionType(value);
                          _applyFilters(filterProvider, transactionProvider);
                        },
                      ),
                    ),

                    // MID Filter
                    _buildFilterSection(
                      'MID',
                      TextFormField(
                        controller: _midController,
                        decoration: const InputDecoration(
                          hintText: 'Search MID',
                          prefixIcon: Icon(Icons.business),
                        ),
                        onChanged: (value) {
                          filterProvider.updateMIDFilter(
                            value.isEmpty ? null : value,
                          );
                          _applyFilters(filterProvider, transactionProvider);
                        },
                      ),
                    ),

                    // Machine Filter
                    _buildFilterSection(
                      'Machine',
                      TextFormField(
                        controller: _machineController,
                        decoration: const InputDecoration(
                          hintText: 'Search machine',
                          prefixIcon: Icon(Icons.computer),
                        ),
                        onChanged: (value) {
                          filterProvider.updateMachineFilter(
                            value.isEmpty ? null : value,
                          );
                          _applyFilters(filterProvider, transactionProvider);
                        },
                      ),
                    ),

                    // Amount Range Filter
                    _buildFilterSection(
                      'Amount Range',
                      Column(
                        children: [
                          TextFormField(
                            controller: _minAmountController,
                            decoration: const InputDecoration(
                              hintText: 'Min amount',
                              prefixIcon: Icon(Icons.arrow_upward),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              final minAmount = double.tryParse(value);
                              final maxAmount = double.tryParse(
                                _maxAmountController.text,
                              );
                              filterProvider.updateAmountRange(
                                minAmount,
                                maxAmount,
                              );
                              _applyFilters(
                                filterProvider,
                                transactionProvider,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _maxAmountController,
                            decoration: const InputDecoration(
                              hintText: 'Max amount',
                              prefixIcon: Icon(Icons.arrow_downward),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              final minAmount = double.tryParse(
                                _minAmountController.text,
                              );
                              final maxAmount = double.tryParse(value);
                              filterProvider.updateAmountRange(
                                minAmount,
                                maxAmount,
                              );
                              _applyFilters(
                                filterProvider,
                                transactionProvider,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Discrepancy Filter
                    _buildFilterSection(
                      'Discrepancies',
                      CheckboxListTile(
                        title: const Text('Show only discrepancies'),
                        value: filterProvider.currentFilter.hasDiscrepancy ??
                            false,
                        onChanged: (value) {
                          filterProvider.updateDiscrepancyFilter(value);
                          _applyFilters(filterProvider, transactionProvider);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),

                    // Quick Filters
                    _buildFilterSection(
                      'Quick Filters',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickFilterChip(
                            'Perfect',
                            Icons.check_circle,
                            Colors.green,
                            () => filterProvider.applyQuickFilter('perfect'),
                            filterProvider,
                            transactionProvider,
                          ),
                          _buildQuickFilterChip(
                            'Investigate',
                            Icons.warning,
                            Colors.orange,
                            () =>
                                filterProvider.applyQuickFilter('investigate'),
                            filterProvider,
                            transactionProvider,
                          ),
                          _buildQuickFilterChip(
                            'Manual Refund',
                            Icons.error,
                            Colors.red,
                            () => filterProvider.applyQuickFilter(
                              'manual_refund',
                            ),
                            filterProvider,
                            transactionProvider,
                          ),
                          _buildQuickFilterChip(
                            'High Amount',
                            Icons.attach_money,
                            Colors.blue,
                            () =>
                                filterProvider.applyQuickFilter('high_amount'),
                            filterProvider,
                            transactionProvider,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearAllControllers();
                        filterProvider.clearAllFilters();
                        transactionProvider.applyFilters(FilterModel());
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _applyFilters(
                        filterProvider,
                        transactionProvider,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    FilterProvider filterProvider,
    TransactionProvider transactionProvider,
  ) {
    return GestureDetector(
      onTap: () {
        onTap();
        _applyFilters(filterProvider, transactionProvider);
      },
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        backgroundColor: color.withOpacity(0.1),
      ),
    );
  }

  void _applyFilters(
    FilterProvider filterProvider,
    TransactionProvider transactionProvider,
  ) {
    transactionProvider.applyFilters(filterProvider.currentFilter);
  }

  void _clearAllControllers() {
    _midController.clear();
    _machineController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
  }
}

// Transaction Card Widget
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDetails;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.txnRefNo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(status: transaction.status),
                ],
              ),
              const SizedBox(height: 8),

              // MID and Machine
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      transaction.txnMid,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.computer,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      transaction.txnMachine,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (showDetails) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Payment details
                _buildAmountRow(
                  'PTPP Payment:',
                  transaction.ptppPayment,
                  currencyFormat,
                ),
                _buildAmountRow(
                  'PTPP Refund:',
                  transaction.ptppRefund,
                  currencyFormat,
                ),
                _buildAmountRow(
                  'Cloud Payment:',
                  transaction.cloudPayment,
                  currencyFormat,
                ),
                _buildAmountRow(
                  'Cloud Refund:',
                  transaction.cloudRefund,
                  currencyFormat,
                ),
                if (transaction.cloudMRefund != 0)
                  _buildAmountRow(
                    'Manual Refund:',
                    transaction.cloudMRefund,
                    currencyFormat,
                  ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Amount:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(transaction.netAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: transaction.netAmount >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),

                if (transaction.hasDiscrepancy) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discrepancy:',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currencyFormat.format(
                          transaction.discrepancyAmount.abs(),
                        ),
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const SizedBox(height: 8),

                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net: ${currencyFormat.format(transaction.netAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: transaction.netAmount >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (transaction.hasDiscrepancy)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Discrepancy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // Remarks
              if (transaction.remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          transaction.remarks,
                          style: theme.textTheme.bodySmall,
                          maxLines: showDetails ? null : 1,
                          overflow: showDetails ? null : TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color:
                  amount > 0 ? Colors.green : (amount < 0 ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}

// Chart Card Widget
class ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final String? subtitle;
  final List<Widget>? actions;
  final double? height;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.actions,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: height ?? 300, child: chart),
          ],
        ),
      ),
    );
  }
}

// Loading Widget
class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// Custom Error Widget
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ],
      ),
    );
  }
}

// Export Button Widget - Fixed
class ExportButton extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String? fileName;

  const ExportButton({super.key, required this.transactions, this.fileName});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Export Data',
      onSelected: (value) => _handleExport(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart),
              SizedBox(width: 8),
              Text('Export as CSV'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.file_present),
              SizedBox(width: 8),
              Text('Export as Excel'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: 8),
              Text('Export as PDF'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleExport(BuildContext context, String format) {
    // Since export methods are not implemented in TransactionProvider,
    // we'll show a message for now or implement basic functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Export to $format functionality will be implemented soon'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // TODO: Implement export functionality
    // You can implement the export logic here directly or
    // add the export methods to TransactionProvider

    /* When export methods are implemented in TransactionProvider, use:
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    final settings = ExportSettings(
      fileName: fileName ??
          'reconciliation_export_${DateTime.now().millisecondsSinceEpoch}',
      includeCalculatedFields: true,
    );

    switch (format) {
      case 'csv':
        transactionProvider.exportToCSV(settings: settings);
        break;
      case 'excel':
        transactionProvider.exportToExcel(settings: settings);
        break;
      case 'pdf':
        transactionProvider.exportToPDF(settings: settings);
        break;
    }
    */
  }
}

// Summary Stats Widget - Fixed
class SummaryStatsWidget extends StatelessWidget {
  final SummaryStats stats;

  const SummaryStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final percentFormat = NumberFormat.percentPattern();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildStatCard(
                  'Total Transactions',
                  stats.totalTransactions.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Perfect Matches',
                  '${stats.perfectCount} (${stats.perfectPercentage.toStringAsFixed(1)}%)',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Need Investigation',
                  '${stats.investigateCount} (${stats.investigatePercentage.toStringAsFixed(1)}%)',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Manual Refunds',
                  '${stats.manualRefundCount} (${stats.manualRefundPercentage.toStringAsFixed(1)}%)',
                  Icons.error,
                  Colors.red,
                ),
                // Fixed: Using available fields from SummaryStats
                _buildStatCard(
                  'PTPP Payments',
                  currencyFormat.format(stats.ptppTotalPayments),
                  Icons.payment,
                  Colors.green,
                ),
                _buildStatCard(
                  'PTPP Refunds',
                  currencyFormat.format(stats.ptppTotalRefunds),
                  Icons.money_off,
                  Colors.red,
                ),
                _buildStatCard(
                  'PTPP Net Amount',
                  currencyFormat.format(stats.ptppNetAmount),
                  Icons.account_balance,
                  stats.ptppNetAmount >= 0 ? Colors.green : Colors.red,
                ),
                _buildStatCard(
                  'Total Discrepancy',
                  currencyFormat.format(stats.totalDiscrepancy),
                  Icons.error_outline,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// No Data Widget
class NoDataWidget extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const NoDataWidget({
    super.key,
    this.message = 'No data available',
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}
