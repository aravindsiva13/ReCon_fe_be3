import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'providers.dart';
import 'models.dart';
import 'widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedPeriod = 'All Time';
  String _selectedView = 'Overview';

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (!provider.hasData) {
          return const Center(
            child: NoDataWidget(
              message: 'No transaction data available for analysis',
              actionText: 'Load Data',
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with controls
              _buildAnalyticsHeader(context, provider),
              const SizedBox(height: 24),

              // Overview Section
              if (_selectedView == 'Overview') ...[
                _buildOverviewSection(context, provider),
              ],

              // Status Distribution Section
              _buildStatusDistributionSection(context, provider),
              const SizedBox(height: 24),

              // Payment vs Refund Analysis
              _buildPaymentVsRefundSection(context, provider),
              const SizedBox(height: 24),

              // Top MIDs Analysis
              _buildTopMIDsSection(context, provider),
              const SizedBox(height: 24),

              // Insights Section
              _buildInsightsSection(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsHeader(
      BuildContext context, TransactionProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Dashboard',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Analyzing ${provider.filteredTransactions.length} transactions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Control buttons
            Row(
              children: [
                // Period selector
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(
                        value: 'All Time', child: Text('All Time')),
                    DropdownMenuItem(
                        value: 'This Month', child: Text('This Month')),
                    DropdownMenuItem(
                        value: 'This Week', child: Text('This Week')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                ),
                const SizedBox(width: 16),

                // View selector
                DropdownButton<String>(
                  value: _selectedView,
                  items: const [
                    DropdownMenuItem(
                        value: 'Overview', child: Text('Overview')),
                    DropdownMenuItem(
                        value: 'Detailed', child: Text('Detailed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedView = value!;
                    });
                  },
                ),
                const Spacer(),

                // Export button
                ExportButton(
                  transactions: provider.filteredTransactions,
                  fileName: 'analytics_report',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(
      BuildContext context, TransactionProvider provider) {
    final stats = provider.summaryStats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SummaryStatsWidget(stats: stats),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusDistributionSection(
      BuildContext context, TransactionProvider provider) {
    final statusData = provider.getStatusDistributionData();
    final totalTransactions = provider.filteredTransactions.length;

    return ChartCard(
      title: 'Status Distribution',
      subtitle: 'Breakdown of transaction reconciliation status',
      height: 350,
      chart: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: statusData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final percentage =
                      (data['count'] as int) / totalTransactions * 100;

                  return PieChartSectionData(
                    value: (data['count'] as int).toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: data['color'] as Color,
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),

          // Legend
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statusData.map((data) {
                final percentage = (data['count'] as int) /
                    provider.filteredTransactions.length *
                    100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: data['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['status'] as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${(data['count'] as int)} transactions (${percentage.toStringAsFixed(1)}%)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentVsRefundSection(
      BuildContext context, TransactionProvider provider) {
    final paymentData = provider.getPaymentVsRefundData();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return ChartCard(
      title: 'Payment vs Refund Analysis',
      subtitle: 'Volume comparison between payments and refunds',
      height: 300,
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: paymentData
                  .map((e) => e['amount'] as double)
                  .reduce((a, b) => a > b ? a : b) *
              1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // Fixed: Using proper parameter name for fl_chart 0.67.0
              // tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${paymentData[group.x.toInt()]['type']}\n${currencyFormat.format(rod.toY)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    paymentData[value.toInt()]['type'] as String,
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    currencyFormat.format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: paymentData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['amount'] as double,
                  color: entry.value['color'] as Color,
                  width: 40,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        // Legend
        Row(
          children: paymentData.map((data) {
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (data['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: (data['color'] as Color).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      data['type'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: data['color'] as Color,
                      ),
                    ),
                    Text(
                      currencyFormat.format(data['amount'] as double),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: data['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopMIDsSection(
      BuildContext context, TransactionProvider provider) {
    final topMIDsData = provider.getTopMIDsData(limit: 10);

    if (topMIDsData.isEmpty) {
      return const SizedBox.shrink();
    }

    return ChartCard(
      title: 'Top MIDs by Transaction Volume',
      subtitle: 'Merchants with highest transaction counts',
      height: 300,
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (topMIDsData.first['count'] as int) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // Fixed: Using proper parameter name for fl_chart 0.67.0
              // tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topMIDsData[group.x.toInt()]['mid']}\n${rod.toY.toInt()} transactions',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < topMIDsData.length) {
                    final mid = topMIDsData[value.toInt()]['mid'] as String;
                    return Text(
                      mid.length > 10 ? '${mid.substring(0, 10)}...' : mid,
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: topMIDsData.asMap().entries.take(10).map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['count'] as int).toDouble(),
                  color: Colors.blue,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
      BuildContext context, TransactionProvider provider) {
    final discrepancyAnalysis = provider.getDiscrepancyAnalysis();
    final stats = provider.summaryStats;

    if (stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Key Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'Success Rate',
                    '${stats.successRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    stats.successRate >= 90 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Discrepant Transactions',
                    '${discrepancyAnalysis['totalDiscrepantTransactions']}',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Perfect Matches',
                    '${stats.perfectMatches}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Insights List
            _buildInsightsList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(TransactionProvider provider) {
    // Generate insights based on data
    final List<String> insights = [];
    final stats = provider.summaryStats!;

    // Success rate insight
    if (stats.successRate >= 95) {
      insights.add(
          'Excellent reconciliation performance with ${stats.successRate.toStringAsFixed(1)}% success rate');
    } else if (stats.successRate >= 85) {
      insights.add(
          'Good reconciliation performance, but room for improvement at ${stats.successRate.toStringAsFixed(1)}%');
    } else {
      insights.add(
          'Reconciliation performance needs attention at ${stats.successRate.toStringAsFixed(1)}% success rate');
    }

    // Volume insight
    insights.add('Processing ${stats.totalTransactions} total transactions');

    // Discrepancy insight
    if (stats.investigateCount > 0) {
      insights
          .add('${stats.investigateCount} transactions require investigation');
    }

    // Manual refund insight
    if (stats.manualRefunds > 0) {
      insights.add(
          '${stats.manualRefunds} transactions require manual refund processing');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...insights
            .map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}
