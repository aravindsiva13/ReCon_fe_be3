// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'providers.dart';
// import 'models.dart';
// import 'widgets.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Consumer<TransactionProvider>(
//       builder: (context, provider, child) {
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Welcome Header
//               _buildWelcomeHeader(context),
//               const SizedBox(height: 24),

//               // Database Status
//               _buildDatabaseStatus(context, provider),
//               const SizedBox(height: 16),

//               // Data Source Selector
//               _buildDataSourceSelector(context, provider),
//               const SizedBox(height: 16),

//               // Refresh Button (only shows when data is loaded)
//               if (provider.hasData) ...[
//                 _buildRefreshButton(context, provider),
//                 const SizedBox(height: 24),
//               ],

//               // Loading Progress
//               if (provider.isLoading || provider.isProcessing) ...[
//                 _buildLoadingProgress(context, provider),
//                 const SizedBox(height: 24),
//               ],

//               // Summary Statistics
//               if (provider.hasData && provider.summaryStats != null) ...[
//                 _buildSummarySection(context, provider),
//                 const SizedBox(height: 24),
//               ],

//               // Recent Activity
//               if (provider.hasData) ...[
//                 _buildRecentActivity(context, provider),
//                 const SizedBox(height: 24),
//               ],

//               // Quick Actions
//               if (provider.hasData) ...[
//                 _buildQuickActions(context, provider),
//                 const SizedBox(height: 24),
//               ],

//               // Error Display
//               if (provider.hasError) ...[
//                 _buildErrorSection(context, provider),
//                 const SizedBox(height: 16),
//               ],

//               // Success Message
//               if (provider.successMessage != null) ...[
//                 _buildSuccessSection(context, provider),
//                 const SizedBox(height: 16),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildWelcomeHeader(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           children: [
//             Icon(
//               Icons.dashboard,
//               size: 32,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Reconciliation Dashboard',
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   Text(
//                     'Compare transaction records between iCloud and multiple bank sources',
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Theme.of(context).colorScheme.onSurfaceVariant,
//                         ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDatabaseStatus(
//       BuildContext context, TransactionProvider provider) {
//     return FutureBuilder<bool>(
//       future: provider.checkDatabaseConnection(),
//       builder: (context, snapshot) {
//         final isConnected = snapshot.data ?? false;
//         final isLoading = snapshot.connectionState == ConnectionState.waiting;

//         return Card(
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: isLoading
//                         ? Colors.grey.withOpacity(0.1)
//                         : isConnected
//                             ? Colors.green.withOpacity(0.1)
//                             : Colors.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: isLoading
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : Icon(
//                           isConnected ? Icons.check_circle : Icons.error,
//                           color: isConnected ? Colors.green : Colors.red,
//                           size: 20,
//                         ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         isLoading
//                             ? 'Checking Database Connection...'
//                             : isConnected
//                                 ? 'Database Connected'
//                                 : 'Database Disconnected',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: isLoading
//                               ? Colors.grey
//                               : isConnected
//                                   ? Colors.green
//                                   : Colors.red,
//                         ),
//                       ),
//                       Text(
//                         isLoading
//                             ? 'Verifying connection to MySQL server...'
//                             : isConnected
//                                 ? 'Ready to fetch live reconciliation data'
//                                 : 'Unable to connect to MySQL server',
//                         style: Theme.of(context).textTheme.bodySmall,
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (!isLoading && !isConnected)
//                   TextButton.icon(
//                     onPressed: () {
//                       setState(() {});
//                     },
//                     icon: const Icon(Icons.refresh, size: 16),
//                     label: const Text('Retry'),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDataSourceSelector(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.source,
//                   color: Theme.of(context).colorScheme.primary,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Data Source',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Database Option
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 leading: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(Icons.storage, color: Colors.green),
//                 ),
//                 title: const Text(
//                   'Load from Database',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 subtitle: const Text('Fetch live data from MySQL database'),
//                 trailing: provider.isLoading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Icon(Icons.arrow_forward_ios),
//                 onTap: provider.isLoading
//                     ? null
//                     : () => _loadFromDatabase(context, provider),
//               ),
//             ),

//             const SizedBox(height: 12),

//             // Excel File Option
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 leading: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(Icons.upload_file, color: Colors.blue),
//                 ),
//                 title: const Text(
//                   'Upload Excel File',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 subtitle: const Text('Load data from Excel file (legacy)'),
//                 trailing: const Icon(Icons.arrow_forward_ios),
//                 onTap: provider.isLoading
//                     ? null
//                     : () => _loadFromExcel(context, provider),
//               ),
//             ),

//             // Current Data Source Info
//             if (provider.hasData) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surfaceVariant,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       provider.dataSource.contains('Database')
//                           ? Icons.storage
//                           : Icons.file_present,
//                       size: 16,
//                       color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Current Source: ${provider.dataSource}',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                             fontWeight: FontWeight.w500,
//                           ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRefreshButton(
//       BuildContext context, TransactionProvider provider) {
//     // Only show refresh for database sources
//     if (!provider.dataSource.contains('Database')) {
//       return const SizedBox.shrink();
//     }

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.refresh,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Refresh Data',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   Text(
//                     'Update with latest database records',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//             ),
//             ElevatedButton.icon(
//               onPressed: provider.isLoading
//                   ? null
//                   : () => _refreshDatabaseData(context, provider),
//               icon: provider.isLoading
//                   ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.refresh, size: 16),
//               label: const Text('Refresh'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingProgress(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     provider.processingStatus.isNotEmpty
//                         ? provider.processingStatus
//                         : 'Processing...',
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             LinearProgressIndicator(
//               value: provider.processingProgress,
//               backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${(provider.processingProgress * 100).toInt()}% complete',
//               style: Theme.of(context).textTheme.bodySmall,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummarySection(
//       BuildContext context, TransactionProvider provider) {
//     final stats = provider.summaryStats!;
//     final numberFormat = NumberFormat('#,##0');
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(
//               Icons.analytics,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               'Summary Statistics',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Summary Cards Grid
//         _buildSummaryGrid(context, stats, numberFormat, currencyFormat),
//       ],
//     );
//   }

//   Widget _buildSummaryGrid(BuildContext context, SummaryStats stats,
//       NumberFormat numberFormat, NumberFormat currencyFormat) {
//     return Column(
//       children: [
//         // First row of cards
//         GridView.count(
//           crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 1.5,
//           children: [
//             _buildSummaryCard(
//               context,
//               'Total Transactions',
//               numberFormat.format(stats.totalTransactions),
//               Icons.receipt_long,
//               Colors.blue,
//             ),
//             _buildSummaryCard(
//               context,
//               'Perfect Matches',
//               numberFormat.format(stats.perfectMatches),
//               Icons.check_circle,
//               Colors.green,
//             ),
//             _buildSummaryCard(
//               context,
//               'Need Investigation',
//               numberFormat.format(stats.investigateCount),
//               Icons.warning,
//               Colors.orange,
//             ),
//             _buildSummaryCard(
//               context,
//               'Manual Refunds',
//               numberFormat.format(stats.manualRefunds),
//               Icons.build,
//               Colors.purple,
//             ),
//           ],
//         ),

//         const SizedBox(height: 16),

//         // Second row of cards
//         GridView.count(
//           crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 1,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: MediaQuery.of(context).size.width > 768 ? 2.5 : 1.8,
//           children: [
//             _buildSummaryCard(
//               context,
//               'Success Rate',
//               '${stats.successRate.toStringAsFixed(1)}%',
//               Icons.trending_up,
//               stats.successRate >= 90
//                   ? Colors.green
//                   : stats.successRate >= 70
//                       ? Colors.orange
//                       : Colors.red,
//             ),
//             _buildSummaryCard(
//               context,
//               'Total Amount',
//               currencyFormat.format(stats.totalAmount),
//               Icons.currency_rupee,
//               Colors.indigo,
//             ),
//             _buildSummaryCard(
//               context,
//               'Discrepancy Amount',
//               currencyFormat.format(stats.discrepancyAmount),
//               Icons.error_outline,
//               stats.discrepancyAmount > 0 ? Colors.red : Colors.green,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSummaryCard(
//     BuildContext context,
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Card(
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon, color: color, size: 24),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: Theme.of(context).textTheme.bodySmall,
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivity(
//       BuildContext context, TransactionProvider provider) {
//     final recentTransactions = provider.allTransactions.take(5).toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(
//               Icons.history,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               'Recent Transactions',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Card(
//           elevation: 2,
//           child: Column(
//             children: recentTransactions.map((transaction) {
//               return ListTile(
//                 leading: StatusChip(status: transaction.status, showIcon: true),
//                 title: Text(
//                   transaction.txnRefNo,
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 subtitle: Text(transaction.txnMid),
//                 trailing: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '₹${transaction.ptppNetAmount.toStringAsFixed(2)}',
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     if (transaction.hasDiscrepancy)
//                       Text(
//                         'Diff: ₹${transaction.systemDifference.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           color: Colors.red,
//                           fontSize: 12,
//                         ),
//                       ),
//                   ],
//                 ),
//                 onTap: () => _showTransactionDetails(context, transaction),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickActions(
//       BuildContext context, TransactionProvider provider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(
//               Icons.quick_contacts_dialer,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               'Quick Actions',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         GridView.count(
//           crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 1.2,
//           children: [
//             _buildActionCard(
//               context,
//               'View All Data',
//               Icons.table_view,
//               Colors.blue,
//               () => _navigateToDataScreen(context),
//             ),
//             _buildActionCard(
//               context,
//               'Analytics',
//               Icons.analytics,
//               Colors.green,
//               () => _navigateToAnalytics(context),
//             ),
//             _buildActionCard(
//               context,
//               'Export Data',
//               Icons.file_download,
//               Colors.orange,
//               () => _showExportDialog(context, provider),
//             ),
//             _buildActionCard(
//               context,
//               'Clear Data',
//               Icons.clear_all,
//               Colors.red,
//               () => _showClearDataDialog(context, provider),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActionCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       elevation: 2,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: color, size: 28),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 2,
//       color: Colors.red.shade50,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             const Icon(Icons.error, color: Colors.red),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Error',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red,
//                     ),
//                   ),
//                   Text(
//                     provider.error ?? 'An unknown error occurred',
//                     style: TextStyle(color: Colors.red.shade700),
//                   ),
//                 ],
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 provider.clearData();
//               },
//               child: const Text('Dismiss'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSuccessSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 2,
//       color: Colors.green.shade50,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.green),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Success',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                   ),
//                   Text(
//                     provider.successMessage!,
//                     style: TextStyle(color: Colors.green.shade700),
//                   ),
//                 ],
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 provider.clearData();
//               },
//               child: const Text('Dismiss'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Action Methods
//   Future<void> _loadFromDatabase(
//       BuildContext context, TransactionProvider provider) async {
//     bool? shouldProceed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
//             const SizedBox(width: 8),
//             const Text('Load from Database'),
//           ],
//         ),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//                 'This will fetch the latest reconciliation data from the MySQL database.'),
//             SizedBox(height: 8),
//             Text('Make sure the Flask API server is running.',
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//             SizedBox(height: 16),
//             Text('Do you want to continue?'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton.icon(
//             onPressed: () => Navigator.of(context).pop(true),
//             icon: const Icon(Icons.download),
//             label: const Text('Load Data'),
//           ),
//         ],
//       ),
//     );

//     if (shouldProceed == true) {
//       try {
//         await provider.loadTransactionsFromDatabase();

//         if (provider.hasData && context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.check_circle, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                         provider.successMessage ?? 'Data loaded successfully'),
//                   ),
//                 ],
//               ),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//         }
//       } catch (e) {
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.error, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Expanded(child: Text('Failed to load data: $e')),
//                 ],
//               ),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 5),
//             ),
//           );
//         }
//       }
//     }
//   }

//   Future<void> _loadFromExcel(
//       BuildContext context, TransactionProvider provider) async {
//     try {
//       await provider.loadTransactionsFromFile();

//       if (provider.hasData && context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.check_circle, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(
//                     child: Text(provider.successMessage ??
//                         'Excel file loaded successfully')),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(child: Text('Failed to load Excel file: $e')),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _refreshDatabaseData(
//       BuildContext context, TransactionProvider provider) async {
//     try {
//       await provider.refreshTransactionsFromDatabase();

//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.refresh, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(
//                     child: Text(provider.successMessage ??
//                         'Data refreshed successfully')),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(child: Text('Failed to refresh data: $e')),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//     }
//   }

//   void _showTransactionDetails(
//       BuildContext context, TransactionModel transaction) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Container(
//           width: 500,
//           constraints: const BoxConstraints(maxHeight: 600),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Header
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.receipt_long,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Transaction Details',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),
//                 const Divider(),
//                 const SizedBox(height: 8),

//                 // Transaction Card with full details
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: TransactionCard(
//                       transaction: transaction,
//                       showDetails: true,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Action buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     TextButton.icon(
//                       onPressed: () {
//                         // Copy transaction ID to clipboard
//                         Navigator.of(context).pop();
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                                 'Transaction ID ${transaction.txnRefNo} copied'),
//                             duration: const Duration(seconds: 2),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.copy),
//                       label: const Text('Copy ID'),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: () => Navigator.of(context).pop(),
//                       icon: const Icon(Icons.close),
//                       label: const Text('Close'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showExportDialog(BuildContext context, TransactionProvider provider) {
//     if (!provider.hasData) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No data to export'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Export Data'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Choose export format:'),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.table_chart, color: Colors.green),
//               title: const Text('Excel Format'),
//               subtitle: const Text('Export as .xlsx file'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 _exportData(context, provider, 'excel');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.description, color: Colors.blue),
//               title: const Text('CSV Format'),
//               subtitle: const Text('Export as .csv file'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 _exportData(context, provider, 'csv');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
//               title: const Text('PDF Format'),
//               subtitle: const Text('Export as .pdf file'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 _exportData(context, provider, 'pdf');
//               },
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _exportData(
//       BuildContext context, TransactionProvider provider, String format) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//             'Exporting ${provider.filteredTransactions.length} transactions as $format...'),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 2),
//       ),
//     );

//     // Here you would implement the actual export functionality
//     // For now, just show a completion message
//     Future.delayed(const Duration(seconds: 2), () {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Export completed: reconciliation_data.$format'),
//             backgroundColor: Colors.green,
//             action: SnackBarAction(
//               label: 'View',
//               onPressed: () {
//                 // Open file location or download
//               },
//             ),
//           ),
//         );
//       }
//     });
//   }

//   void _showClearDataDialog(
//       BuildContext context, TransactionProvider provider) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.warning, color: Colors.orange),
//             SizedBox(width: 8),
//             Text('Clear Data'),
//           ],
//         ),
//         content: const Text(
//           'Are you sure you want to clear all loaded data? This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               provider.clearData();
//               Navigator.of(context).pop();
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Data cleared successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Clear', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToDataScreen(BuildContext context) {
//     // Find the TabController from the parent widget
//     final tabController = DefaultTabController.of(context);
//     if (tabController != null) {
//       tabController.animateTo(1); // Navigate to Data tab (index 1)
//     }
//   }

//   void _navigateToAnalytics(BuildContext context) {
//     // Find the TabController from the parent widget
//     final tabController = DefaultTabController.of(context);
//     if (tabController != null) {
//       tabController.animateTo(2); // Navigate to Analytics tab (index 2)
//     }
//   }
// }

//2

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'dart:html' as html;
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:async';
// import 'package:http/http.dart' as http;
// import 'providers.dart';
// import 'widgets.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   bool _isDragOver = false;
//   Timer? _processingTimer;

//   @override
//   void dispose() {
//     _processingTimer?.cancel();
//     super.dispose();
//   }

//   // File upload handling using HTML input
//   Future<void> _handleFileUpload() async {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);
//     final uploadProvider =
//         Provider.of<UploadStateProvider>(context, listen: false);

//     try {
//       // Create file input element
//       final html.FileUploadInputElement uploadInput =
//           html.FileUploadInputElement();
//       uploadInput.accept = '.zip,.xlsx,.xls';
//       uploadInput.click();

//       uploadInput.onChange.listen((e) async {
//         final files = uploadInput.files;
//         if (files!.isEmpty) return;

//         final file = files[0];
//         uploadProvider.startUpload(file.name);

//         // Read file as bytes
//         final reader = html.FileReader();
//         reader.readAsArrayBuffer(file);

//         reader.onLoadEnd.listen((e) async {
//           try {
//             final bytes = reader.result as List<int>;
//             final uint8Bytes = Uint8List.fromList(bytes);

//             // Simulate upload progress
//             for (int i = 0; i <= 100; i += 20) {
//               await Future.delayed(const Duration(milliseconds: 50));
//               uploadProvider.updateProgress(i / 100,
//                   status: 'Uploading... $i%');
//             }

//             // Handle the file upload through TransactionProvider
//             await provider.handleFileUpload(uint8Bytes, file.name);

//             uploadProvider.completeUpload({
//               'filename': file.name,
//               'size': file.size,
//             });

//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('File uploaded successfully: ${file.name}'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             }
//           } catch (e) {
//             uploadProvider.failUpload(e.toString());

//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Upload failed: $e'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           }
//         });
//       });
//     } catch (e) {
//       uploadProvider.failUpload(e.toString());

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Upload failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Start batch processing
//   Future<void> _startProcessing() async {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);

//     try {
//       await provider.startAutomatedProcessing();

//       // Start monitoring processing status
//       _startProcessingMonitor();

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Processing started successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to start processing: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Monitor processing status
//   void _startProcessingMonitor() {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);

//     _processingTimer?.cancel();
//     _processingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       if (!provider.isBatchProcessing) {
//         timer.cancel();

//         if (provider.batchProcessingStatus?['completed'] == true) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content:
//                     Text('Processing completed! Data refreshed successfully.'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           }
//         } else if (provider.batchProcessingStatus?['error'] != null) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                     'Processing failed: ${provider.batchProcessingStatus!['error']}'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<TransactionProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Reconciliation Dashboard'),
//             elevation: 0,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.refresh),
//                 onPressed: () => provider.loadTransactionsFromDatabase(),
//                 tooltip: 'Refresh Data',
//               ),
//             ],
//           ),
//           body: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header Section
//                 _buildHeaderSection(context),

//                 const SizedBox(height: 32),

//                 // Upload and Processing Section
//                 _buildUploadProcessingSection(context, provider),

//                 const SizedBox(height: 32),

//                 // Data Status Section
//                 _buildDataStatusSection(context, provider),

//                 const SizedBox(height: 32),

//                 // Quick Actions
//                 _buildQuickActionsSection(context, provider),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeaderSection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(32),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).primaryColor,
//             Theme.of(context).primaryColor.withOpacity(0.8),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Automated Reconciliation System',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Upload files and automatically process PayTM, PhonePe & iCloud reconciliation data',
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                   color: Colors.white.withOpacity(0.9),
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUploadProcessingSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'File Upload & Processing',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),

//             // File Upload Area
//             _buildFileUploadArea(provider),

//             const SizedBox(height: 24),

//             // Processing Controls
//             _buildProcessingControls(context, provider),

//             const SizedBox(height: 16),

//             // Processing Status
//             if (provider.isBatchProcessing ||
//                 provider.batchProcessingStatus != null)
//               _buildProcessingStatus(provider),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFileUploadArea(TransactionProvider provider) {
//     return Consumer<UploadStateProvider>(
//       builder: (context, uploadProvider, child) {
//         return Container(
//           width: double.infinity,
//           height: 200,
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: (_isDragOver || uploadProvider.isUploading)
//                   ? Theme.of(context).primaryColor
//                   : Theme.of(context).dividerColor,
//               width: 2,
//             ),
//             borderRadius: BorderRadius.circular(12),
//             color: (_isDragOver || uploadProvider.isUploading)
//                 ? Theme.of(context).primaryColor.withOpacity(0.1)
//                 : Theme.of(context).cardColor,
//           ),
//           child: InkWell(
//             onTap: uploadProvider.isUploading ? null : _handleFileUpload,
//             borderRadius: BorderRadius.circular(12),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (uploadProvider.isUploading) ...[
//                   CircularProgressIndicator(
//                       value: uploadProvider.uploadProgress),
//                   const SizedBox(height: 16),
//                   Text('Uploading ${uploadProvider.uploadedFileName}...'),
//                   Text('${(uploadProvider.uploadProgress * 100).toInt()}%'),
//                 ] else ...[
//                   Icon(
//                     Icons.cloud_upload_outlined,
//                     size: 48,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Click to upload reconciliation files',
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Supports .zip, .xlsx, .xls files (Max 50MB)',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                   if (uploadProvider.uploadError != null) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       uploadProvider.uploadError!,
//                       style: const TextStyle(color: Colors.red),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                   if (provider.uploadedFileName != null &&
//                       !uploadProvider.isUploading) ...[
//                     const SizedBox(height: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(Icons.check_circle,
//                               color: Colors.green, size: 16),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Uploaded: ${provider.uploadedFileName}',
//                             style: const TextStyle(
//                                 color: Colors.green, fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildProcessingControls(
//       BuildContext context, TransactionProvider provider) {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: (provider.isBatchProcessing ||
//                     provider.uploadedFileName == null)
//                 ? null
//                 : _startProcessing,
//             icon: provider.isBatchProcessing
//                 ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Icon(Icons.play_arrow),
//             label: Text(provider.isBatchProcessing
//                 ? 'Processing...'
//                 : 'Start Execution'),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         ElevatedButton.icon(
//           onPressed: provider.loadTransactionsFromDatabase,
//           icon: const Icon(Icons.refresh),
//           label: const Text('Refresh Data'),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProcessingStatus(TransactionProvider provider) {
//     if (provider.batchProcessingStatus == null) return const SizedBox.shrink();

//     final status = provider.batchProcessingStatus!;
//     final progress = (status['progress'] ?? 0.0) / 100.0;
//     final currentStep = status['current_step'] ?? 0;
//     final totalSteps = status['total_steps'] ?? 3;
//     final stepName = status['step_name'] ?? '';
//     final message = status['message'] ?? '';
//     final error = status['error'];

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: error != null
//             ? Colors.red.withOpacity(0.1)
//             : Theme.of(context).primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: error != null
//               ? Colors.red.withOpacity(0.3)
//               : Theme.of(context).primaryColor.withOpacity(0.3),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 error != null ? Icons.error : Icons.info,
//                 color:
//                     error != null ? Colors.red : Theme.of(context).primaryColor,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 error != null ? 'Processing Error' : 'Processing Status',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: error != null
//                       ? Colors.red
//                       : Theme.of(context).primaryColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           if (error != null) ...[
//             Text(
//               error,
//               style: const TextStyle(color: Colors.red),
//             ),
//           ] else ...[
//             Text('Step $currentStep of $totalSteps: $stepName'),
//             const SizedBox(height: 8),
//             LinearProgressIndicator(
//               value: progress,
//               backgroundColor: Colors.grey[300],
//               valueColor:
//                   AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               message,
//               style: Theme.of(context).textTheme.bodySmall,
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildDataStatusSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Data Status',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStatusCard(
//                     context,
//                     'Database Connection',
//                     provider.isDatabaseConnected ? 'Connected' : 'Disconnected',
//                     provider.isDatabaseConnected
//                         ? Icons.check_circle
//                         : Icons.error,
//                     provider.isDatabaseConnected ? Colors.green : Colors.red,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatusCard(
//                     context,
//                     'Transactions',
//                     provider.hasData
//                         ? '${provider.allTransactions.length}'
//                         : 'No Data',
//                     provider.hasData ? Icons.data_usage : Icons.warning,
//                     provider.hasData ? Colors.blue : Colors.orange,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatusCard(
//                     context,
//                     'Data Source',
//                     provider.dataSource,
//                     Icons.source,
//                     Theme.of(context).primaryColor,
//                   ),
//                 ),
//               ],
//             ),
//             if (provider.error != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.error, color: Colors.red),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         provider.error!,
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//             if (provider.successMessage != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.check_circle, color: Colors.green),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         provider.successMessage!,
//                         style: const TextStyle(color: Colors.green),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(BuildContext context, String title, String value,
//       IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 20),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActionsSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Quick Actions',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             Wrap(
//               spacing: 16,
//               runSpacing: 16,
//               children: [
//                 _buildActionButton(
//                   context,
//                   'View Data',
//                   Icons.table_view,
//                   () => Navigator.pushNamed(context, '/data'),
//                   enabled: provider.hasData,
//                 ),
//                 _buildActionButton(
//                   context,
//                   'Analytics',
//                   Icons.analytics,
//                   () => Navigator.pushNamed(context, '/analytics'),
//                   enabled: provider.hasData,
//                 ),
//                 _buildActionButton(
//                   context,
//                   'Export',
//                   Icons.download,
//                   () => _showExportDialog(context, provider),
//                   enabled: provider.hasData,
//                 ),
//                 _buildActionButton(
//                   context,
//                   'Settings',
//                   Icons.settings,
//                   () => _showSettingsDialog(context, provider),
//                 ),
//                 _buildActionButton(
//                   context,
//                   'Upload Guidelines',
//                   Icons.help_outline,
//                   () => _showUploadGuidelinesDialog(context),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton(
//     BuildContext context,
//     String label,
//     IconData icon,
//     VoidCallback? onPressed, {
//     bool enabled = true,
//   }) {
//     return ElevatedButton.icon(
//       onPressed: enabled ? onPressed : null,
//       icon: Icon(icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       ),
//     );
//   }

//   void _showExportDialog(BuildContext context, TransactionProvider provider) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Export Data'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Choose export format:'),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 provider.exportDataFromDatabase();
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Export to Excel'),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () {
//                 // Implement JSON export
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Export to JSON'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSettingsDialog(BuildContext context, TransactionProvider provider) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Settings'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SwitchListTile(
//               title: const Text('Auto Refresh'),
//               subtitle:
//                   const Text('Automatically refresh data every 5 minutes'),
//               value: provider.autoRefreshEnabled,
//               onChanged: (value) {
//                 provider.setAutoRefresh(value);
//                 Navigator.of(context).pop();
//               },
//             ),
//             ListTile(
//               title: const Text('Clear All Data'),
//               subtitle: const Text('Remove all loaded transaction data'),
//               trailing: const Icon(Icons.delete, color: Colors.red),
//               onTap: () {
//                 provider.clearData();
//                 Navigator.of(context).pop();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('All data cleared')),
//                 );
//               },
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showUploadGuidelinesDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Upload Guidelines'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'File Requirements:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text('• Supported formats: .zip, .xlsx, .xls'),
//               const Text('• Maximum file size: 50MB'),
//               const Text('• Ensure files contain reconciliation data'),
//               const SizedBox(height: 16),
//               const Text(
//                 'File Naming Conventions:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text('• PayTM files: end with "*bill_txn_report.xlsx"'),
//               const Text(
//                   '• PhonePe files: start with "Merchant_Settlement_Report*.zip"'),
//               const Text('• iCloud payment files: start with "pmt*.zip"'),
//               const Text('• iCloud refund files: start with "ref*.zip"'),
//               const SizedBox(height: 16),
//               const Text(
//                 'Processing Steps:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text('1. Prepare Input Files (1-2 min)'),
//               const Text('2. PayTM & PhonePe Reconciliation (30-90 min)'),
//               const Text('3. Load Data to Database (2-3 min)'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Got it'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// //3

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'dart:html' as html;
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:async';
// import 'package:http/http.dart' as http;
// import 'providers.dart';
// import 'widgets.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   bool _isDragOver = false;
//   Timer? _processingTimer;

//   @override
//   void dispose() {
//     _processingTimer?.cancel();
//     super.dispose();
//   }

//   // File upload handling using HTML input
//   Future<void> _handleFileUpload() async {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);
//     final uploadProvider =
//         Provider.of<UploadStateProvider>(context, listen: false);

//     try {
//       // Create file input element
//       final html.FileUploadInputElement uploadInput =
//           html.FileUploadInputElement();
//       uploadInput.accept = '.zip,.xlsx,.xls';
//       uploadInput.click();

//       uploadInput.onChange.listen((e) async {
//         final files = uploadInput.files;
//         if (files!.isEmpty) return;

//         final file = files[0];
//         uploadProvider.startUpload(file.name);

//         // Read file as bytes
//         final reader = html.FileReader();
//         reader.readAsArrayBuffer(file);

//         reader.onLoadEnd.listen((e) async {
//           try {
//             final bytes = reader.result as List<int>;
//             final uint8Bytes = Uint8List.fromList(bytes);

//             // Simulate upload progress
//             for (int i = 0; i <= 100; i += 20) {
//               await Future.delayed(const Duration(milliseconds: 50));
//               uploadProvider.updateProgress(i / 100,
//                   status: 'Uploading... $i%');
//             }

//             // Handle the file upload through TransactionProvider
//             await provider.handleFileUpload(uint8Bytes, file.name);

//             uploadProvider.completeUpload({
//               'filename': file.name,
//               'size': file.size,
//             });

//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('File uploaded successfully: ${file.name}'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             }
//           } catch (e) {
//             uploadProvider.failUpload(e.toString());

//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Upload failed: $e'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           }
//         });
//       });
//     } catch (e) {
//       uploadProvider.failUpload(e.toString());

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Upload failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Load from database
//   Future<void> _loadFromDatabase() async {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);

//     try {
//       await provider.loadTransactionsFromDatabase();

//       if (mounted && provider.hasData) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 'Successfully loaded ${provider.allTransactions.length} transactions from database'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to load from database: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Load from Excel file
//   Future<void> _loadFromExcel() async {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);

//     try {
//       await provider.loadTransactionsFromFile();

//       if (mounted && provider.hasData) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 'Successfully loaded ${provider.allTransactions.length} transactions from Excel'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to load from Excel: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Start batch processing
//   Future<void> _startProcessing() async {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);

//     try {
//       await provider.startAutomatedProcessing();

//       // Start monitoring processing status
//       _startProcessingMonitor();

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Processing started successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to start processing: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Monitor processing status
//   void _startProcessingMonitor() {
//     final provider = Provider.of<TransactionProvider>(context, listen: false);

//     _processingTimer?.cancel();
//     _processingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       if (!provider.isBatchProcessing) {
//         timer.cancel();

//         if (provider.batchProcessingStatus?['completed'] == true) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content:
//                     Text('Processing completed! Data refreshed successfully.'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           }
//         } else if (provider.batchProcessingStatus?['error'] != null) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                     'Processing failed: ${provider.batchProcessingStatus!['error']}'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<TransactionProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Reconciliation Dashboard'),
//             elevation: 0,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.refresh),
//                 onPressed: () => provider.loadTransactionsFromDatabase(),
//                 tooltip: 'Refresh Data',
//               ),
//             ],
//           ),
//           body: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header Section
//                 _buildHeaderSection(context),

//                 const SizedBox(height: 32),

//                 // Data Source Selection - MAIN LOADING OPTIONS
//                 _buildDataSourceSection(context, provider),

//                 const SizedBox(height: 32),

//                 // Upload and Processing Section (if file uploaded)
//                 if (provider.uploadedFileName != null) ...[
//                   _buildUploadProcessingSection(context, provider),
//                   const SizedBox(height: 32),
//                 ],

//                 // Data Status Section
//                 _buildDataStatusSection(context, provider),

//                 const SizedBox(height: 32),

//                 // Quick Actions (if data loaded)
//                 if (provider.hasData) ...[
//                   _buildQuickActionsSection(context, provider),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeaderSection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(32),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).primaryColor,
//             Theme.of(context).primaryColor.withOpacity(0.8),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Reconciliation Dashboard',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Load data from database or upload files for processing',
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                   color: Colors.white.withOpacity(0.9),
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDataSourceSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Choose Data Source',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),

//             // Database Option - MOST PROMINENT
//             Container(
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.green.withOpacity(0.1),
//                     Colors.green.withOpacity(0.05),
//                   ],
//                 ),
//                 border: Border.all(color: Colors.green, width: 2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.all(16),
//                 leading: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.green,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child:
//                       const Icon(Icons.storage, color: Colors.white, size: 24),
//                 ),
//                 title: const Text(
//                   'Load from Database',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 subtitle: const Text(
//                   'Fetch live data from MySQL database (Recommended)',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//                 trailing: provider.isLoading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Icon(Icons.arrow_forward_ios, color: Colors.green),
//                 onTap: provider.isLoading ? null : _loadFromDatabase,
//               ),
//             ),

//             // Excel File Option
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Theme.of(context).dividerColor),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.all(16),
//                 leading: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.file_present,
//                       color: Colors.blue, size: 24),
//                 ),
//                 title: const Text(
//                   'Load from Excel File',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 subtitle: const Text('Upload Excel file for processing'),
//                 trailing: const Icon(Icons.arrow_forward_ios),
//                 onTap: provider.isLoading ? null : _loadFromExcel,
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Upload New Files Option
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Theme.of(context).dividerColor),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.all(16),
//                 leading: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.cloud_upload,
//                       color: Colors.orange, size: 24),
//                 ),
//                 title: const Text(
//                   'Upload & Process Files',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 subtitle: const Text(
//                     'Upload .zip/.xlsx files for automated processing'),
//                 trailing: const Icon(Icons.arrow_forward_ios),
//                 onTap: provider.isLoading ? null : _handleFileUpload,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUploadProcessingSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'File Processing',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),

//             // Uploaded file info
//             if (provider.uploadedFileName != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.check_circle, color: Colors.green),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child:
//                           Text('File uploaded: ${provider.uploadedFileName}'),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],

//             // Processing Controls
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: (provider.isBatchProcessing ||
//                             provider.uploadedFileName == null)
//                         ? null
//                         : _startProcessing,
//                     icon: provider.isBatchProcessing
//                         ? const SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Icon(Icons.play_arrow),
//                     label: Text(provider.isBatchProcessing
//                         ? 'Processing...'
//                         : 'Start Processing'),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: Theme.of(context).primaryColor,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             // Processing Status
//             if (provider.isBatchProcessing &&
//                 provider.batchProcessingStatus != null) ...[
//               const SizedBox(height: 16),
//               _buildProcessingStatus(provider),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProcessingStatus(TransactionProvider provider) {
//     final status = provider.batchProcessingStatus!;
//     final progress = (status['progress'] ?? 0.0) / 100.0;
//     final currentStep = status['current_step'] ?? 0;
//     final totalSteps = status['total_steps'] ?? 3;
//     final stepName = status['step_name'] ?? '';
//     final message = status['message'] ?? '';

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Processing Status: Step $currentStep of $totalSteps'),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(value: progress),
//           const SizedBox(height: 8),
//           Text(stepName, style: const TextStyle(fontWeight: FontWeight.bold)),
//           Text(message, style: Theme.of(context).textTheme.bodySmall),
//         ],
//       ),
//     );
//   }

//   Widget _buildDataStatusSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Data Status',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStatusCard(
//                     context,
//                     'Database Connection',
//                     provider.isDatabaseConnected ? 'Connected' : 'Disconnected',
//                     provider.isDatabaseConnected
//                         ? Icons.check_circle
//                         : Icons.error,
//                     provider.isDatabaseConnected ? Colors.green : Colors.red,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatusCard(
//                     context,
//                     'Transactions',
//                     provider.hasData
//                         ? '${provider.allTransactions.length}'
//                         : 'No Data',
//                     provider.hasData ? Icons.data_usage : Icons.warning,
//                     provider.hasData ? Colors.blue : Colors.orange,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildStatusCard(
//                     context,
//                     'Data Source',
//                     provider.dataSource,
//                     Icons.source,
//                     Theme.of(context).primaryColor,
//                   ),
//                 ),
//               ],
//             ),
//             if (provider.error != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.error, color: Colors.red),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         provider.error!,
//                         style: const TextStyle(color: Colors.red),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//             if (provider.successMessage != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.check_circle, color: Colors.green),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         provider.successMessage!,
//                         style: const TextStyle(color: Colors.green),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(BuildContext context, String title, String value,
//       IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 20),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActionsSection(
//       BuildContext context, TransactionProvider provider) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Quick Actions',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             Wrap(
//               spacing: 16,
//               runSpacing: 16,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () => Navigator.pushNamed(context, '/data'),
//                   icon: const Icon(Icons.table_view),
//                   label: const Text('View Data'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => Navigator.pushNamed(context, '/analytics'),
//                   icon: const Icon(Icons.analytics),
//                   label: const Text('Analytics'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => provider.exportDataFromDatabase(),
//                   icon: const Icon(Icons.download),
//                   label: const Text('Export'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => provider.refreshTransactionsFromDatabase(),
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('Refresh'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//4
// Enhanced home_screen.dart with multiple file upload support

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'providers.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDragOver = false;
  Timer? _processingTimer;
  List<String> _uploadedFiles = []; // Track multiple uploaded files

  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }

  // Enhanced file upload handling for MULTIPLE files
  Future<void> _handleMultipleFileUpload() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final uploadProvider =
        Provider.of<UploadStateProvider>(context, listen: false);

    try {
      // Create file input element with multiple file support
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = '.zip,.xlsx,.xls';
      uploadInput.multiple = true; // Enable multiple file selection
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) return;

        // Process all selected files
        List<String> successfulUploads = [];
        List<String> failedUploads = [];

        for (int i = 0; i < files.length; i++) {
          final file = files[i];

          try {
            // Validate file before uploading
            final validationError = _validateFile(file.name, file.size);
            if (validationError != null) {
              failedUploads.add('${file.name}: $validationError');
              continue;
            }

            uploadProvider
                .startUpload('${file.name} (${i + 1}/${files.length})');

            // Read file as bytes
            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);

            await reader.onLoadEnd.first;

            final bytes = reader.result as List<int>;
            final uint8Bytes = Uint8List.fromList(bytes);

            // Simulate upload progress for each file
            for (int progress = 0; progress <= 100; progress += 25) {
              await Future.delayed(const Duration(milliseconds: 30));
              uploadProvider.updateProgress(progress / 100,
                  status: 'Uploading ${file.name}... $progress%');
            }

            // Upload file to server
            final response = await _uploadFileToServer(uint8Bytes, file.name);

            if (response['success'] == true) {
              successfulUploads.add(file.name);
              _uploadedFiles.add(file.name);
            } else {
              failedUploads
                  .add('${file.name}: ${response['error'] ?? 'Upload failed'}');
            }
          } catch (e) {
            failedUploads.add('${file.name}: ${e.toString()}');
          }
        }

        // Update UI based on results
        if (successfulUploads.isNotEmpty) {
          uploadProvider.completeUpload({
            'totalFiles': files.length,
            'successfulFiles': successfulUploads,
            'failedFiles': failedUploads,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Upload completed: ${successfulUploads.length}/${files.length} files'),
                    if (successfulUploads.isNotEmpty)
                      Text('✓ ${successfulUploads.join(', ')}',
                          style: const TextStyle(fontSize: 12)),
                    if (failedUploads.isNotEmpty)
                      Text('✗ ${failedUploads.length} failed',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange)),
                  ],
                ),
                backgroundColor:
                    failedUploads.isEmpty ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          uploadProvider.failUpload('All uploads failed');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All uploads failed:'),
                    ...failedUploads.map((error) =>
                        Text('• $error', style: const TextStyle(fontSize: 12))),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        }

        // Refresh state
        setState(() {});
      });
    } catch (e) {
      uploadProvider.failUpload(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // File validation
  String? _validateFile(String fileName, int fileSize) {
    // Check file extension
    final allowedExtensions = {'zip', 'xlsx', 'xls'};
    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'Invalid file type. Only .zip, .xlsx, and .xls files are allowed.';
    }

    // Check file size (50MB limit)
    const maxSizeBytes = 50 * 1024 * 1024;
    if (fileSize > maxSizeBytes) {
      final sizeMB = fileSize / (1024 * 1024);
      return 'File too large (${sizeMB.toStringAsFixed(1)}MB). Maximum size is 50MB.';
    }

    return null; // Valid file
  }

  // Upload file to server
  // Future<Map<String, dynamic>> _uploadFileToServer(
  //     Uint8List bytes, String fileName) async {
  //   try {
  //     final request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('http://localhost:5000/api/upload'),
  //     );

  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         'file',
  //         bytes,
  //         filename: fileName,
  //       ),
  //     );

  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       return {'success': true, 'data': data};
  //     } else {
  //       final errorData = json.decode(response.body);
  //       return {
  //         'success': false,
  //         'error': errorData['error'] ?? 'Upload failed'
  //       };
  //     }
  //   } catch (e) {
  //     return {'success': false, 'error': e.toString()};
  //   }
  // }

  Future<Map<String, dynamic>> _uploadFileToServer(
      Uint8List bytes, String fileName) async {
    try {
      print('🚀 Uploading ${fileName} to backend...'); // DEBUG

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5000/api/upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      print('📤 Sending request to backend...'); // DEBUG
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Backend response: ${response.statusCode}'); // DEBUG
      print('📄 Response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Upload successful: ${data['filename']}'); // DEBUG
        return {'success': true, 'data': data};
      } else {
        final errorData = json.decode(response.body);
        print('❌ Upload failed: ${errorData['error']}'); // DEBUG
        return {
          'success': false,
          'error': errorData['error'] ?? 'Upload failed'
        };
      }
    } catch (e) {
      print('💥 Upload exception: $e'); // DEBUG
      return {'success': false, 'error': e.toString()};
    }
  }

  // Load from database
  Future<void> _loadFromDatabase() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    try {
      await provider.loadTransactionsFromDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data loaded successfully from database'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load from Excel (single file for compatibility)
  Future<void> _loadFromExcel() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    try {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = '.xlsx,.xls';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((e) async {
          try {
            final bytes = reader.result as List<int>;
            final uint8Bytes = Uint8List.fromList(bytes);
            // await provider.loadFromExcel(uint8Bytes, file.name);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Excel file loaded: ${file.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading Excel: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Future<void> _startProcessing() async {
  //   final provider = Provider.of<TransactionProvider>(context, listen: false);

  //   try {
  //     _showProcessingDialog();

  //     await provider.startBatchProcessing();

  //     _processingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
  //       provider.checkProcessingStatus();

  //       if (provider.batchProcessingStatus?['completed'] == true) {
  //         timer.cancel();
  //         Navigator.of(context).pop();

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Processing completed successfully!'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       } else if (provider.batchProcessingStatus?['error'] != null) {
  //         timer.cancel();
  //         Navigator.of(context).pop();

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //                 'Processing failed: ${provider.batchProcessingStatus!['error']}'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     });
  //   } catch (e) {
  //     Navigator.of(context).pop();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Future<void> _startProcessing() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    try {
      _showProcessingDialog();

      await provider.startBatchProcessing();

      _processingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        provider.checkProcessingStatus();

        if (provider.batchProcessingStatus?['completed'] == true) {
          timer.cancel();
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (provider.batchProcessingStatus?['error'] != null) {
          timer.cancel();
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Processing failed: ${provider.batchProcessingStatus!['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show processing dialog
  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final status = provider.batchProcessingStatus ?? {};

          return AlertDialog(
            title: const Text('Processing Files'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Processing ${_uploadedFiles.length} uploaded files...'),
                const SizedBox(height: 16),
                if (status['step_name'] != null) ...[
                  Text('Current Step: ${status['step_name']}'),
                  const SizedBox(height: 8),
                ],
                if (status['message'] != null) ...[
                  Text(status['message'], style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                LinearProgressIndicator(
                  value: (status['progress'] ?? 0) / 100.0,
                ),
                const SizedBox(height: 8),
                Text(
                    '${status['current_step'] ?? 0}/${status['total_steps'] ?? 3} steps'),
              ],
            ),
            actions: [
              if (status['error'] != null)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reconciliation Dashboard'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadTransactionsFromDatabase(),
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(context),
                const SizedBox(height: 32),

                // Data Source Selection
                _buildDataSourceSection(context, provider),
                const SizedBox(height: 32),

                // Multiple Files Upload Section
                if (_uploadedFiles.isNotEmpty) ...[
                  _buildUploadedFilesSection(context, provider),
                  const SizedBox(height: 32),
                ],

                // Data Status Section
                _buildDataStatusSection(context, provider),
                const SizedBox(height: 32),

                // Quick Actions
                if (provider.hasData) ...[
                  _buildQuickActionsSection(context, provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Reconciliation System',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Load data from database or upload files for automated processing',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildDataSourceSection(
      BuildContext context, TransactionProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Database Option
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.storage, color: Colors.green, size: 24),
                ),
                title: const Text(
                  'Load from Database',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    const Text('Get latest reconciliation data from MySQL'),
                trailing: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios, color: Colors.green),
                onTap: provider.isLoading ? null : _loadFromDatabase,
              ),
            ),

            const SizedBox(height: 12),

            // Excel File Option
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_present,
                      color: Colors.blue, size: 24),
                ),
                title: const Text(
                  'Load from Excel File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Upload single Excel file for quick view'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: provider.isLoading ? null : _loadFromExcel,
              ),
            ),

            const SizedBox(height: 12),

            // Multiple Files Upload Option
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload,
                      color: Colors.orange, size: 24),
                ),
                title: const Text(
                  'Upload Multiple Files & Process',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                    'Upload multiple .zip/.xlsx files for batch processing'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: provider.isLoading ? null : _handleMultipleFileUpload,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFilesSection(
      BuildContext context, TransactionProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uploaded Files (${_uploadedFiles.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _uploadedFiles.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of uploaded files
            ...(_uploadedFiles.map((fileName) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(fileName)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _uploadedFiles.remove(fileName);
                          });
                        },
                      ),
                    ],
                  ),
                ))),

            const SizedBox(height: 16),

            // Processing Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (provider.isBatchProcessing) ? null : _startProcessing,
                    icon: provider.isBatchProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(provider.isBatchProcessing
                        ? 'Processing...'
                        : 'Start Processing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _handleMultipleFileUpload,
                  icon: const Icon(Icons.add),
                  label: const Text('Add More Files'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatusSection(
      BuildContext context, TransactionProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Transactions',
                    '${provider.allTransactions.length}',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                // Expanded(
                //   child: _buildStatusCard(
                //     'Total Amount',
                //     '₹${provider.totalAmount.toStringAsFixed(2)}',
                //     Icons.currency_rupee,
                //     Colors.green,
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, TransactionProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/data'),
                    icon: const Icon(Icons.table_view),
                    label: const Text('View Data'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/analytics'),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analytics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
