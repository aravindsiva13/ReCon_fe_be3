import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'providers.dart';
import 'widgets.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _sortColumn = 'refno';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<TransactionProvider, FilterProvider>(
      builder: (context, transactionProvider, filterProvider, child) {
        if (!transactionProvider.hasData) {
          return const NoDataWidget(
            message: 'No transaction data loaded',
            actionText: 'Go to Dashboard',
          );
        }

        return Column(
          children: [
            // Toolbar
            _buildToolbar(context, transactionProvider, filterProvider),

            // Data table
            Expanded(
              child: _buildDataTable(context, transactionProvider),
            ),

            // Pagination
            _buildPagination(context, transactionProvider),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    TransactionProvider provider,
    FilterProvider filterProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.searchTransactions('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => provider.searchTransactions(value),
                ),
              ),

              const SizedBox(width: 16),

              // Filter toggle
              OutlinedButton.icon(
                onPressed: () => filterProvider.toggleFilterPanel(),
                icon: Icon(
                  filterProvider.isFilterPanelOpen
                      ? Icons.filter_alt_off
                      : Icons.filter_alt,
                ),
                label: Text(
                  filterProvider.isFilterPanelOpen
                      ? 'Hide Filters'
                      : 'Show Filters',
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: filterProvider.hasActiveFilters
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
              ),

              const SizedBox(width: 8),

              // Sort dropdown
              PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort),
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                  ],
                ),
                tooltip: 'Sort by',
                onSelected: (value) => _handleSort(provider, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refno',
                    child: Text('Reference Number'),
                  ),
                  const PopupMenuItem(value: 'mid', child: Text('MID')),
                  const PopupMenuItem(
                    value: 'machine',
                    child: Text('Machine'),
                  ),
                  const PopupMenuItem(
                    value: 'amount',
                    child: Text('Amount'),
                  ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Text('Status'),
                  ),
                  const PopupMenuItem(
                    value: 'discrepancy',
                    child: Text('Discrepancy'),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Export button
              ExportButton(transactions: provider.filteredTransactions),

              const SizedBox(width: 8),

              // Items per page
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  value: provider.itemsPerPage,
                  decoration: const InputDecoration(
                    labelText: 'Per page',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [25, 50, 100, 200].map((count) {
                    return DropdownMenuItem(
                      value: count,
                      child: Text(count.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setItemsPerPage(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status filter chips
          _buildStatusFilterChips(provider, filterProvider),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips(
    TransactionProvider provider,
    FilterProvider filterProvider,
  ) {
    final stats = provider.summaryStats!;

    return Row(
      children: [
        Text(
          'Quick Filters:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                'All (${stats.totalTransactions})',
                null,
                filterProvider.currentFilter.status == null,
                () {
                  filterProvider.updateStatus(null);
                  provider.applyFilters(filterProvider.currentFilter);
                },
              ),
              _buildFilterChip(
                'Perfect (${stats.perfectCount})',
                ReconciliationStatus.perfect,
                filterProvider.currentFilter.status ==
                    ReconciliationStatus.perfect,
                () {
                  filterProvider.updateStatus(ReconciliationStatus.perfect);
                  provider.applyFilters(filterProvider.currentFilter);
                },
              ),
              _buildFilterChip(
                'Investigate (${stats.investigateCount})',
                ReconciliationStatus.investigate,
                filterProvider.currentFilter.status ==
                    ReconciliationStatus.investigate,
                () {
                  filterProvider.updateStatus(ReconciliationStatus.investigate);
                  provider.applyFilters(filterProvider.currentFilter);
                },
              ),
              _buildFilterChip(
                'Manual Refund (${stats.manualRefundCount})',
                ReconciliationStatus.manualRefund,
                filterProvider.currentFilter.status ==
                    ReconciliationStatus.manualRefund,
                () {
                  filterProvider
                      .updateStatus(ReconciliationStatus.manualRefund);
                  provider.applyFilters(filterProvider.currentFilter);
                },
              ),
            ],
          ),
        ),

        // Clear filters
        if (filterProvider.hasActiveFilters)
          TextButton.icon(
            onPressed: () {
              filterProvider.clearAllFilters();
              provider.applyFilters(FilterModel());
              _searchController.clear();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All'),
          ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    ReconciliationStatus? status,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: status?.color.withOpacity(0.1),
      selectedColor: status?.color.withOpacity(0.2) ??
          Theme.of(context).colorScheme.primary.withOpacity(0.2),
      side: status != null
          ? BorderSide(color: status.color.withOpacity(0.5))
          : null,
    );
  }

  Widget _buildDataTable(BuildContext context, TransactionProvider provider) {
    final transactions = provider.currentPageTransactions;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    if (transactions.isEmpty) {
      return const Center(
        child: NoDataWidget(
          message: 'No transactions match your filters',
          actionText: 'Clear Filters',
        ),
      );
    }

    return Row(
      children: [
        // Main data table
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              constraints: BoxConstraints(
                minHeight: 400,
                maxHeight: MediaQuery.of(context).size.height - 300,
              ),
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 1200,
                headingRowHeight: 56,
                dataRowHeight: 72,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                columns: [
                  const DataColumn2(
                    label: Text('Status'),
                    size: ColumnSize.S,
                    fixedWidth: 120,
                  ),
                  const DataColumn2(
                    label: Text('Reference No'),
                    size: ColumnSize.L,
                  ),
                  const DataColumn2(
                    label: Text('MID'),
                    size: ColumnSize.M,
                  ),
                  const DataColumn2(
                    label: Text('Machine'),
                    size: ColumnSize.M,
                  ),
                  const DataColumn2(
                    label: Text('PTPP Payment'),
                    size: ColumnSize.S,
                    numeric: true,
                  ),
                  const DataColumn2(
                    label: Text('Cloud Payment'),
                    size: ColumnSize.S,
                    numeric: true,
                  ),
                  const DataColumn2(
                    label: Text('Net Amount'),
                    size: ColumnSize.S,
                    numeric: true,
                  ),
                  const DataColumn2(
                    label: Text('Discrepancy'),
                    size: ColumnSize.S,
                    fixedWidth: 100,
                  ),
                  const DataColumn2(
                    label: Text('Actions'),
                    size: ColumnSize.S,
                    fixedWidth: 80,
                  ),
                ],
                rows: transactions.map((transaction) {
                  return DataRow2(
                    onTap: () => _showTransactionDetails(context, transaction),
                    cells: [
                      DataCell(
                        StatusChip(status: transaction.status, fontSize: 12),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              transaction.txnRefNo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (transaction.txnType != null)
                              Text(
                                transaction.txnType!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(transaction.txnMid,
                            overflow: TextOverflow.ellipsis),
                      ),
                      DataCell(
                        Text(
                          transaction.txnMachine,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(transaction.ptppPayment),
                          style: TextStyle(
                            color: transaction.ptppPayment > 0
                                ? Colors.green
                                : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(transaction.cloudPayment),
                          style: TextStyle(
                            color: transaction.cloudPayment > 0
                                ? Colors.green
                                : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(transaction.netAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: transaction.netAmount >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                      DataCell(
                        transaction.hasDiscrepancy
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  currencyFormat.format(
                                    transaction.discrepancyAmount.abs(),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const Text('-'),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) =>
                              _handleRowAction(context, transaction, value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('Copy Ref No'),
                                ],
                              ),
                            ),
                            if (transaction.hasDiscrepancy)
                              const PopupMenuItem(
                                value: 'analyze',
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics),
                                    SizedBox(width: 8),
                                    Text('Analyze Issue'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Filter sidebar
        Consumer<FilterProvider>(
          builder: (context, filterProvider, child) {
            if (filterProvider.isFilterPanelOpen) {
              return FilterSidebar(
                isVisible: filterProvider.isFilterPanelOpen,
                onClose: () => filterProvider.setFilterPanelOpen(false),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, TransactionProvider provider) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Results info
          Text(
            'Showing ${(provider.currentPage * provider.itemsPerPage) + 1}-'
            '${((provider.currentPage + 1) * provider.itemsPerPage).clamp(0, provider.filteredTransactions.length)} '
            'of ${provider.filteredTransactions.length} transactions',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          // Pagination controls
          Row(
            children: [
              // First page
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(0)
                    : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'First page',
              ),

              // Previous page
              IconButton(
                onPressed:
                    provider.currentPage > 0 ? provider.previousPage : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),

              // Page numbers
              ...List.generate(
                _getVisiblePageCount(provider.totalPages, provider.currentPage),
                (index) {
                  final pageIndex = _getPageIndex(
                    provider.totalPages,
                    provider.currentPage,
                    index,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                      onPressed: () => provider.goToPage(pageIndex),
                      style: TextButton.styleFrom(
                        backgroundColor: pageIndex == provider.currentPage
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor: pageIndex == provider.currentPage
                            ? Colors.white
                            : null,
                        minimumSize: const Size(40, 40),
                      ),
                      child: Text('${pageIndex + 1}'),
                    ),
                  );
                },
              ),

              // Next page
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? provider.nextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),

              // Last page
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.totalPages - 1)
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Last page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for pagination
  int _getVisiblePageCount(int totalPages, int currentPage) {
    return (totalPages > 7) ? 7 : totalPages;
  }

  int _getPageIndex(int totalPages, int currentPage, int index) {
    if (totalPages <= 7) return index;

    if (currentPage < 3) return index;
    if (currentPage > totalPages - 4) return totalPages - 7 + index;

    return currentPage - 3 + index;
  }

  void _handleSort(TransactionProvider provider, String sortBy) {
    if (_sortColumn == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = sortBy;
      _sortAscending = true;
    }

    provider.sortTransactions(_sortColumn, _sortAscending);
    setState(() {});
  }

  void _handleRowAction(
    BuildContext context,
    TransactionModel transaction,
    String action,
  ) {
    switch (action) {
      case 'view':
        _showTransactionDetails(context, transaction);
        break;
      case 'copy':
        _copyToClipboard(context, transaction.txnRefNo);
        break;
      case 'analyze':
        _showDiscrepancyAnalysis(context, transaction);
        break;
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionModel transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          transaction.txnRefNo,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        StatusChip(status: transaction.status),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: TransactionCard(
                    transaction: transaction,
                    showDetails: true,
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (transaction.hasDiscrepancy)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDiscrepancyAnalysis(context, transaction);
                        },
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze Discrepancy'),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copyToClipboard(context, transaction.txnRefNo),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Ref No'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscrepancyAnalysis(
    BuildContext context,
    TransactionModel transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discrepancy Analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Transaction info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reference: ${transaction.txnRefNo}'),
                    Text('MID: ${transaction.txnMid}'),
                    Text('Status: ${transaction.status.label}'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Discrepancy details
              Text(
                'Payment Comparison:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              _buildComparisonRow(
                'PTPP Payment',
                transaction.ptppPayment,
                transaction.cloudPayment,
                'Cloud Payment',
              ),
              _buildComparisonRow(
                'PTPP Refund',
                transaction.ptppRefund,
                transaction.cloudRefund,
                'Cloud Refund',
              ),

              if (transaction.cloudMRefund != 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Manual Refund: ₹${transaction.cloudMRefund.toStringAsFixed(2)}',
                ),
              ],

              const SizedBox(height: 16),

              // Total discrepancy
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Discrepancy:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${transaction.discrepancyAmount.abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              if (transaction.remarks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Remarks:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(transaction.remarks),
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _copyToClipboard(context, transaction.txnRefNo),
                    child: const Text('Copy Ref No'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label1,
    double value1,
    double value2,
    String label2,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final difference = value1 - value2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('$label1: ${currencyFormat.format(value1)}')),
          const Icon(Icons.compare_arrows, size: 16),
          Expanded(child: Text('$label2: ${currencyFormat.format(value2)}')),
          if (difference != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${difference > 0 ? '+' : ''}${currencyFormat.format(difference)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text" to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
