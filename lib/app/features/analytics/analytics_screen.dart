import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FinancialController controller = Get.find<FinancialController>();
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonLime),
            );
          }

          final totalExpensePaise = controller.totalSpent.value;
          final totalIncomePaise = controller.totalIncome.value;
          final totalSavingsPaise = controller.totalSavingsAccumulated.value;
          final accounts = controller.accountSummaries;

          return RefreshIndicator(
            color: const Color(0xFF65B741),
            onRefresh: controller.refreshAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // 1. Top Custom App Bar Header matching other pages
                _buildHeader(context),
                const SizedBox(height: 16),

                // 2. Net Worth Featured Dark Card
                _buildFeaturedNetWorthCard(context),
                const SizedBox(height: 16),

                // 3. Three Metric Tiles (Income, Expenses, Savings)
                _buildThreeMetricCards(
                  totalIncomePaise,
                  totalExpensePaise,
                  totalSavingsPaise,
                ),
                const SizedBox(height: 18),

                // 4. Cash Flow Ratio Overview Card
                _buildCashFlowOverviewCard(totalIncomePaise, totalExpensePaise),
                const SizedBox(height: 20),

                // 5. Category Spending Distribution Pie Chart
                _buildSectionTitle('Category Spending Distribution'),
                const SizedBox(height: 10),
                _buildCategoryPieChart(accounts, totalExpensePaise),
                const SizedBox(height: 20),

                // 6. Budget Utilization Envelopes
                _buildSectionTitle('Budget Utilization per Envelope'),
                const SizedBox(height: 10),
                _buildBudgetUtilizationList(accounts),
                const SizedBox(height: 20),

                // 7. Net Worth & Financial Assets Breakdown Card
                _buildSectionTitle('Net Worth Breakdown'),
                const SizedBox(height: 10),
                _buildNetWorthDetailsCard(),

                const SizedBox(height: 80), // bottom bar spacing
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- 1. Top App Bar Header ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (Navigator.canPop(context))
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1E232A),
            ),
            onPressed: () => Navigator.maybePop(context),
          )
        else
          const SizedBox(width: 40),
        const Text(
          'Analytics & Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: const Icon(
            Icons.insights_rounded,
            size: 20,
            color: Color(0xFF1E232A),
          ),
        ),
      ],
    );
  }

  // --- 2. Featured Net Worth Dark Card (matching Accounts & Dashboard) ---
  Widget _buildFeaturedNetWorthCard(BuildContext context) {
    final netWorthPaise = controller.netWorth.value;
    final availableCashPaise = controller.totalAvailableCash.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF222824), // Forest Dark matching Account featured card
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top-right subtle badge icon
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFFD4F938), // Figma Neon lime
                size: 22,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Calculated Net Worth',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.info_outline, color: Colors.white38, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyHelper.formatPaise(netWorthPaise),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 15,
                      color: Color(0xFFD4F938),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Liquid Envelopes: ${CurrencyHelper.formatPaise(availableCashPaise)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Three Metric Tiles ---
  Widget _buildThreeMetricCards(int income, int expense, int savings) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Income',
            amountPaise: income,
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFF22C55E),
            circleBg: const Color(0xFFE9F9E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Expenses',
            amountPaise: expense,
            icon: Icons.arrow_downward_rounded,
            iconColor: const Color(0xFFEF4444),
            circleBg: const Color(0xFFFFECEF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Savings',
            amountPaise: savings,
            icon: Icons.savings_outlined,
            iconColor: const Color(0xFF3B82F6),
            circleBg: const Color(0xFFE6F3FF),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int amountPaise,
    required IconData icon,
    required Color iconColor,
    required Color circleBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: circleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8C95A3),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyHelper.formatPaise(amountPaise, hideDecimals: true),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E232A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Cash Flow Overview Card ---
  Widget _buildCashFlowOverviewCard(int incomePaise, int expensePaise) {
    final maxAmount = (incomePaise > expensePaise ? incomePaise : expensePaise);
    final incomeRatio = maxAmount > 0 ? (incomePaise / maxAmount) : 0.0;
    final expenseRatio = maxAmount > 0 ? (expensePaise / maxAmount) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Cash Flow Dynamics',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E232A),
                ),
              ),
              Icon(
                Icons.swap_horiz_rounded,
                color: Color(0xFF8C95A3),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Total Income',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8C95A3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyHelper.formatPaise(incomePaise, hideDecimals: true),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: incomeRatio.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFF22C55E),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Total Spent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8C95A3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyHelper.formatPaise(expensePaise, hideDecimals: true),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: expenseRatio.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFFEF4444),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. Pie Chart Card ---
  Widget _buildCategoryPieChart(List<AccountLedgerSummary> accounts, int totalExpensePaise) {
    if (totalExpensePaise == 0) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF0F2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 38,
              color: Color(0xFF8C95A3),
            ),
            SizedBox(height: 8),
            Text(
              'No expenses recorded in this period yet.',
              style: TextStyle(
                color: Color(0xFF8C95A3),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final spentAccounts = accounts.where((a) => a.expensesPaise > 0).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: List.generate(spentAccounts.length, (i) {
                  final item = spentAccounts[i];
                  final isTouched = i == _touchedPieIndex;
                  final double percentage =
                      (item.expensesPaise / totalExpensePaise) * 100.0;
                  final color = _getCategoryColor(item.account.name, i);

                  return PieChartSectionData(
                    color: color,
                    value: item.expensesPaise.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: isTouched ? 54.0 : 44.0,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: spentAccounts.asMap().entries.map((entry) {
              final idx = entry.key;
              final a = entry.value;
              final color = _getCategoryColor(a.account.name, idx);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${a.account.name}: ${CurrencyHelper.formatPaise(a.expensesPaise, hideDecimals: true)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E232A),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 6. Budget Utilization List ---
  Widget _buildBudgetUtilizationList(List<AccountLedgerSummary> accounts) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF0F2)),
        ),
        child: const Text(
          'No account envelopes configured yet.',
          style: TextStyle(color: Color(0xFF8C95A3), fontSize: 13),
        ),
      );
    }

    return Column(
      children: accounts.asMap().entries.map((entry) {
        final index = entry.key;
        final acc = entry.value;

        final double maxBudget = acc.allocatedPaise > 0
            ? acc.allocatedPaise.toDouble()
            : (acc.currentBalancePaise + acc.expensesPaise).toDouble();
        final double ratio = maxBudget > 0 ? (acc.expensesPaise / maxBudget) : 0.0;
        final isOverbudget = ratio > 1.0;
        final iconData = _getAccountIcon(acc.account.name, index);
        final color = _getCategoryColor(acc.account.name, index);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc.account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF1E232A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}% utilized',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isOverbudget
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF8C95A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${CurrencyHelper.formatPaise(acc.expensesPaise, hideDecimals: true)} / ${CurrencyHelper.formatPaise(maxBudget.toInt(), hideDecimals: true)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Color(0xFF1E232A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: isOverbudget
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF65B741),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 7. Net Worth Breakdown Card ---
  Widget _buildNetWorthDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Asset Class Allocation',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E232A),
                ),
              ),
              Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF8C95A3),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildNetWorthRow(
            'Liquid Envelopes Balance',
            controller.totalAvailableCash.value,
            Icons.account_balance_wallet_outlined,
            const Color(0xFF22C55E),
            const Color(0xFFE9F9E5),
          ),
          const SizedBox(height: 10),
          _buildNetWorthRow(
            'Savings Pockets & Goals',
            controller.totalSavingsAccumulated.value,
            Icons.savings_outlined,
            const Color(0xFF3B82F6),
            const Color(0xFFE6F3FF),
          ),
          const SizedBox(height: 10),
          _buildNetWorthRow(
            'Investments & Assets',
            controller.totalInvestmentValuation.value,
            Icons.trending_up_rounded,
            const Color(0xFF8B5CF6),
            const Color(0xFFF3E8FF),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEF0F2), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Net Worth Value',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF1E232A),
                ),
              ),
              Text(
                CurrencyHelper.formatPaise(controller.netWorth.value),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF65B741),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthRow(
    String title,
    int amountPaise,
    IconData icon,
    Color iconColor,
    Color circleBg,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: circleBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E232A),
              ),
            ),
          ],
        ),
        Text(
          CurrencyHelper.formatPaise(amountPaise),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Color(0xFF1E232A),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E232A),
      ),
    );
  }

  Color _getCategoryColor(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('food') || lower.contains('groc')) return const Color(0xFF3B82F6);
    if (lower.contains('travel') || lower.contains('fuel')) return const Color(0xFF10B981);
    if (lower.contains('entertain') || lower.contains('fun')) return const Color(0xFFEC4899);
    if (lower.contains('emergenc')) return const Color(0xFFF59E0B);
    if (lower.contains('invest')) return const Color(0xFF8B5CF6);
    if (lower.contains('daily') || lower.contains('saver')) return const Color(0xFF06B6D4);
    if (lower.contains('rent') || lower.contains('house')) return const Color(0xFFF97316);

    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
      Color(0xFF64748B),
    ];
    return palette[index % palette.length];
  }

  IconData _getAccountIcon(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('food') || lower.contains('groc')) return Icons.restaurant_rounded;
    if (lower.contains('travel') || lower.contains('fuel')) return Icons.directions_car_filled_rounded;
    if (lower.contains('entertain')) return Icons.movie_outlined;
    if (lower.contains('emergenc')) return Icons.shield_rounded;
    if (lower.contains('invest')) return Icons.trending_up_rounded;
    if (lower.contains('daily') || lower.contains('saver')) return Icons.savings_outlined;
    if (lower.contains('rent') || lower.contains('house')) return Icons.home_rounded;
    return Icons.account_balance_wallet_outlined;
  }
}
