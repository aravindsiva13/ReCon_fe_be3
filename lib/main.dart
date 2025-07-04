import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reconciliation_app/data_screen.dart';
import 'providers.dart';
import 'home_screen.dart' hide SizedBox;
import 'analytics_screen.dart';

void main() {
  runApp(const ReconciliationApp());
}

class ReconciliationApp extends StatelessWidget {
  const ReconciliationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => UploadStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Reconciliation Dashboard',
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Consumer<TransactionProvider>(
          builder: (context, transactionProvider, child) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    const Icon(Icons.account_balance, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      appState.appTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Data summary in app bar
                  if (transactionProvider.hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${transactionProvider.allTransactions.length} transactions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Theme toggle button
                  IconButton(
                    onPressed: () =>
                        context.read<ThemeProvider>().toggleTheme(),
                    icon: Icon(
                      context.watch<ThemeProvider>().isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    tooltip: 'Toggle theme',
                  ),

                  // Settings button
                  IconButton(
                    onPressed: () => _showSettingsDialog(context),
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Settings',
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.home),
                      text: 'Dashboard',
                    ),
                    Tab(
                      icon: Icon(Icons.table_view),
                      text: 'Data',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics),
                      text: 'Analytics',
                    ),
                  ],
                ),
              ),
              body: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: const [
                      HomeScreen(),
                      DataScreen(),
                      AnalyticsScreen(),
                    ],
                  ),

                  // Error overlay
                  if (transactionProvider.hasError)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                transactionProvider.error ??
                                    'An error occurred',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              onPressed: () => transactionProvider.clearData(),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Success message overlay
                  if (transactionProvider.successMessage != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.green,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                transactionProvider.successMessage!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              onPressed: () => transactionProvider.clearData(),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme Settings
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Dark Mode'),
                trailing: Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    return Switch(
                      value: provider.isDarkMode,
                      onChanged: (value) => provider.toggleTheme(),
                    );
                  },
                ),
              ),

              const Divider(),

              // Export Options
              const ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Export Options'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showExportOptions(context);
                        },
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export to Excel'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showExportOptions(context);
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export to PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final provider = context.read<TransactionProvider>();

    if (!provider.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format:'),
            SizedBox(height: 16),
            // Export format options would go here
            Text(
                'Export functionality will be implemented based on your requirements.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement actual export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature will be implemented'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
