import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/transaction_model.dart';
import '../accounts/accounts_screen.dart';
import '../analytics/analytics_screen.dart';
import '../salary_allocation/salary_allocation_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transaction_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  final FinancialController controller = Get.find<FinancialController>();

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons for dark header
        statusBarBrightness: Brightness.dark, // iOS dark background -> white icons
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1B201E), // Dark header tone
        body: SafeArea(
          bottom: false,
          child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonLime),
            );
          }

          return RefreshIndicator(
            color: AppColors.neonLime,
            backgroundColor: AppColors.darkBackground,
            onRefresh: controller.refreshAllData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dark Top Section (Greeting, Bell, Total Balance Card)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        _buildTotalBalanceCard(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // 2. White Curved Container with the rest of content
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3 Summary Metric Cards (Income, Expenses, Savings)
                        _buildThreeMetricCards(context),
                        const SizedBox(height: 16),

                        // Monthly Budget Card with progress
                        _buildMonthlyBudgetCard(context),
                        const SizedBox(height: 20),

                        // 4 Circular Action Buttons
                        _buildCircleActions(context),
                        const SizedBox(height: 22),

                        // Recent Transactions Section
                        _buildRecentTransactionsHeader(context),
                        const SizedBox(height: 12),
                        _buildRecentTransactionsList(context),

                        const SizedBox(height: 70), // Bottom navigation spacing
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
    );
  }

  // --- 1. Top Header ---
  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Welcome to My Money Manager',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. Dark Total Balance Card ---
  Widget _buildTotalBalanceCard(BuildContext context) {
    final balancePaise = controller.totalAvailableCash.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF232B25), // Forest dark card
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Wallet outline icon on top-right
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 42,
              color: AppColors.neonLime.withOpacity(0.9),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white54,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyHelper.formatPaise(balancePaise),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.to(
                      () => const AddTransactionScreen(
                        initialType: TransactionType.addMoney,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonLime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.black87),
                          SizedBox(width: 4),
                          Text(
                            'Add Money',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Three Metrics (Income, Expenses, Savings) ---
  Widget _buildThreeMetricCards(BuildContext context) {
    final income = controller.totalIncome.value;
    final expense = controller.totalSpent.value;
    final savings = controller.totalSavingsAccumulated.value;

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
            icon: Icons.arrow_downward_rounded,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyHelper.formatPaise(amountPaise),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E232A),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8C95A3),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Monthly Budget Progress Card ---
  Widget _buildMonthlyBudgetCard(BuildContext context) {
    final allocated = controller.totalAllocated.value;
    final spent = controller.totalSpent.value;
    final budget = allocated > 0 ? allocated : spent;
    final remaining = budget - spent;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E232A),
                ),
              ),
              Text(
                CurrencyHelper.formatPaise(budget, hideDecimals: true),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E232A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyHelper.formatPaise(spent, hideDecimals: true)} Spent',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${CurrencyHelper.formatPaise(remaining > 0 ? remaining : 0, hideDecimals: true)} Remaining',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. Quick Action Circular Buttons ---
  Widget _buildCircleActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          label: 'Add\nIncome',
          icon: Icons.arrow_upward_rounded,
          iconColor: const Color(0xFF22C55E),
          bgColor: const Color(0xFFE9F9E5),
          onTap: () => Get.to(
            () => const AddTransactionScreen(
              initialType: TransactionType.additionalIncome,
            ),
          ),
        ),
        _buildActionItem(
          label: 'Add\nExpense',
          icon: Icons.arrow_downward_rounded,
          iconColor: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFFECEF),
          onTap: () => Get.to(
            () => const AddTransactionScreen(
              initialType: TransactionType.expense,
            ),
          ),
        ),
        _buildActionItem(
          label: 'Transfer\n',
          icon: Icons.sync_alt_rounded,
          iconColor: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFFF6E6),
          onTap: () => Get.to(
            () => const AddTransactionScreen(
              initialType: TransactionType.transfer,
            ),
          ),
        ),
        _buildActionItem(
          label: 'View\nReports',
          icon: Icons.bar_chart_rounded,
          iconColor: const Color(0xFF374151),
          bgColor: const Color(0xFFF3F4F6),
          onTap: () => Get.to(() => const AnalyticsScreen()),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Recent Transactions ---
  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        InkWell(
          onTap: () => Get.to(() => const TransactionHistoryScreen()),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              'See All >',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList(BuildContext context) {
    if (controller.transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: Colors.black26),
            const SizedBox(height: 8),
            const Text(
              'No transactions yet',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonLime,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Get.to(() => AddTransactionScreen()),
              child: const Text(
                'Add Transaction',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: controller.transactions.take(5).map((tx) {
        return _buildDesignTransactionCard(context, tx);
      }).toList(),
    );
  }

  Widget _buildDesignTransactionCard(
    BuildContext context,
    TransactionModel tx,
  ) {
    final isIncome =
        tx.type.isIncomeCategory || tx.type == TransactionType.refund;
    final prefix = isIncome ? '+' : '-';
    final amountColor = isIncome
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    final title = tx.title.isNotEmpty
        ? tx.title
        : (tx.description ?? 'Transaction');
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'T';

    // Look up account/category name from controller
    String categoryLabel = 'General';
    final targetId = tx.sourceAccountId ?? tx.destinationAccountId;
    if (targetId != null) {
      try {
        final match = controller.accountSummaries.firstWhereOrNull(
          (s) => s.account.id == targetId,
        );
        if (match != null) {
          categoryLabel = match.account.name;
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome
                      ? const Color(0xFFE9F9E5)
                      : const Color(0xFFFFECEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isIncome
                    ? const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E232A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateHelper.formatRelative(tx.transactionDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$prefix${CurrencyHelper.formatPaise(tx.amountPaise)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${CurrencyHelper.formatPaise(tx.balanceAfterPaise > 0 ? tx.balanceAfterPaise : controller.totalAvailableCash.value, hideDecimals: true)} Remaining',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
