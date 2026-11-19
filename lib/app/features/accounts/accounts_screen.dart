import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../transactions/add_transaction_screen.dart';

class AccountsScreen extends StatelessWidget {
  final FinancialController controller = Get.find<FinancialController>();

  AccountsScreen({super.key});

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

          final summaries = controller.accountSummaries;
          final totalBalancePaise = controller.totalAvailableCash.value;

          return RefreshIndicator(
            color: const Color(0xFF65B741),
            onRefresh: controller.refreshAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // 1. App Bar Header: "My Accounts" and "+" action
                _buildHeader(context),
                const SizedBox(height: 16),

                // 2. White Total Balance Card
                _buildTotalBalanceCard(context, totalBalancePaise),
                const SizedBox(height: 16),

                // 3. List of Accounts Cards (1st dark/featured, others light)
                if (summaries.isEmpty)
                  _buildEmptyState(context)
                else
                  ...summaries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final summary = entry.value;
                    final isFirstCard = index == 0;
                    return _buildAccountCard(
                      context,
                      summary,
                      isDark: isFirstCard,
                      index: index,
                    );
                  }),

                const SizedBox(height: 80), // spacing for bottom bar
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- 1. Top Header ---
  Widget _buildHeader(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'My Accounts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
      ],
    );
  }

  // --- 2. Total Balance Card ---
  Widget _buildTotalBalanceCard(BuildContext context, int totalBalancePaise) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8C95A3),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyHelper.formatPaise(totalBalancePaise),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E232A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F9E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFF22C55E),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Account Card Item (Dark for index 0, Light for subsequent) ---
  Widget _buildAccountCard(
    BuildContext context,
    AccountLedgerSummary summary, {
    required bool isDark,
    required int index,
  }) {
    final acc = summary.account;
    final totalAdded =
        summary.openingBalancePaise +
        summary.additionalAddedPaise +
        summary.allocatedPaise;
    final spent = summary.expensesPaise;
    final balance = summary.currentBalancePaise;

    // Calculate progress ratio (added vs spent or balance ratio)
    final progress = totalAdded > 0
        ? (spent / totalAdded).clamp(0.0, 1.0)
        : 0.0;

    // Subtitle bank/source name (HDFC BANK, Cash, etc.)
    final subName = _getAccountSubTitle(acc.name, index);
    final iconData = _getAccountIcon(acc.name, index);
    final iconColor = _getIconColor(index);
    final iconBgColor = _getIconBgColor(index, isDark);

    final cardBgColor = isDark
        ? const Color(0xFF222824)
        : const Color(0xFFF9FAFB);
    final borderColor = isDark ? Colors.transparent : const Color(0xFFEEF0F2);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E232A);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF8C95A3);
    final amountColor = isDark ? Colors.white : const Color(0xFF1E232A);
    final metaColor = isDark ? Colors.white70 : const Color(0xFF8C95A3);
    final progressTrackColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);
    final progressFillColor = const Color(0xFF65B741); // lime green fill

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountLedgerDetails(context, summary),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Title/SubTitle + Balance Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Icon badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Balance Amount
                    Text(
                      CurrencyHelper.formatPaise(balance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Meta Row: Added ₹... | Spent ₹...
                Row(
                  children: [
                    Text(
                      'Added: ${CurrencyHelper.formatPaise(totalAdded, hideDecimals: true)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: metaColor,
                      ),
                    ),
                    Text(
                      '  |  ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: metaColor,
                      ),
                    ),
                    Text(
                      'Spent: ${CurrencyHelper.formatPaise(spent, hideDecimals: true)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: metaColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Bar (Lime green progress on gray track)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: progressTrackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressFillColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Icon and Subtitle Mapping ---
  String _getAccountSubTitle(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('saving')) return 'Savings';
    if (lower.contains('bank')) return 'Bank Account';
    if (lower.contains('cash') || lower.contains('wallet')) return 'Cash Wallet';
    if (lower.contains('invest')) return 'Investment Portfolio';
    if (lower.contains('emergency')) return 'Emergency Reserve';
    return 'Virtual Envelope';
  }

  IconData _getAccountIcon(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('cash') || lower.contains('wallet')) {
      return Icons.account_balance_wallet_rounded;
    }
    return Icons.credit_card_rounded;
  }

  Color _getIconColor(int index) {
    if (index % 3 == 0) return const Color(0xFF38BDF8); // Sky blue
    if (index % 3 == 1) return const Color(0xFF38BDF8); // Blue
    return const Color(0xFF22C55E); // Green
  }

  Color _getIconBgColor(int index, bool isDark) {
    if (index % 3 == 2) {
      return const Color(0xFFE9F9E5); // Soft green
    }
    return isDark
        ? const Color(0xFFE0F2FE)
        : const Color(0xFFE0F2FE); // Soft blue badge
  }

  // --- Empty State ---
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F9E5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 32,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Accounts Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Accounts are automatically created and synchronized when you add categories in the Salary Allocation page.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF8C95A3),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- Details Modal Bottom Sheet ---
  void _showAccountLedgerDetails(
    BuildContext context,
    AccountLedgerSummary summary,
  ) {
    final relatedTxs = controller.transactions
        .where(
          (t) =>
              t.sourceAccountId == summary.account.id ||
              t.destinationAccountId == summary.account.id,
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollCtrl) {
          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.account.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      Text(
                        'Available: ${CurrencyHelper.formatPaise(summary.currentBalancePaise)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonLime,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Get.to(
                            () => AddTransactionScreen(
                              initialType: TransactionType.addMoney,
                              targetAccountId: summary.account.id,
                            ),
                          );
                        },
                        child: const Text(
                          '+ Add Money',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (deleteCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: const Text(
                                'Delete Account?',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${summary.account.name}"? Transactions associated with this account will remain in history.',
                                style: const TextStyle(fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(deleteCtx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(deleteCtx); // Close alert
                                    Navigator.pop(ctx); // Close bottom sheet
                                    await controller.deleteAccount(
                                      summary.account.id,
                                    );
                                    Get.snackbar(
                                      'Account Deleted',
                                      'Account "${summary.account.name}" has been removed.',
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: const Color(0xFFEF4444),
                                      colorText: Colors.white,
                                    );
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Account Transactions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E232A),
                ),
              ),
              const SizedBox(height: 10),
              if (relatedTxs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No transactions recorded for this account yet.',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                )
              else
                ...relatedTxs.map((t) {
                  final isIncome =
                      t.type.isIncomeCategory ||
                      t.type == TransactionType.refund;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isIncome
                            ? const Color(0xFFE9F9E5)
                            : const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: isIncome
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${DateHelper.formatRelative(t.transactionDate)} • ${t.paymentMethod ?? 'UPI'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${CurrencyHelper.formatPaise(t.amountPaise)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isIncome
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
