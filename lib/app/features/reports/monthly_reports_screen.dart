import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

class MonthlyReportsScreen extends StatelessWidget {
  final FinancialController controller = Get.find<FinancialController>();

  MonthlyReportsScreen({super.key});

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

          final monthKey = DateHelper.formatMonthYear(
            controller.selectedMonth.value,
          );
          final salary = controller.totalSalaryIncome.value;
          final additional = controller.totalAdditionalIncome.value;
          final expenses = controller.totalSpent.value;
          final added = controller.totalAdded.value;
          final savings = controller.totalSavingsContributions.value;
          final investments = controller.totalInvestmentsContributions.value;
          final availableCash = controller.totalAvailableCash.value;

          final totalIn = salary + additional;
          final double savingsRatio = totalIn > 0
              ? ((savings + investments) / totalIn) * 100.0
              : 0.0;

          return RefreshIndicator(
            color: const Color(0xFF65B741),
            onRefresh: controller.refreshAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // 1. Top Custom App Bar Header
                _buildHeader(context, monthKey),
                const SizedBox(height: 16),

                // 2. Featured Executive Statement Dark Card
                _buildExecutiveStatementCard(
                  context,
                  monthKey,
                  availableCash,
                  savingsRatio,
                ),
                const SizedBox(height: 16),

                // 3. Export PDF & CSV Action Buttons
                _buildExportActions(
                  monthKey,
                  salary,
                  additional,
                  expenses,
                  savings,
                  investments,
                  availableCash,
                ),
                const SizedBox(height: 20),

                // 4. Accounting Breakdown Card
                _buildSectionTitle('Accounting Breakdown'),
                const SizedBox(height: 10),
                _buildAccountingBreakdownCard(
                  salary: salary,
                  additional: additional,
                  allocated: controller.totalAllocated.value,
                  added: added,
                  expenses: expenses,
                  savings: savings,
                  investments: investments,
                  availableCash: availableCash,
                ),
                const SizedBox(height: 20),

                // 5. Envelope Ledger Balances
                _buildSectionTitle('Envelope Ledger Balances'),
                const SizedBox(height: 10),
                _buildEnvelopeBalancesList(controller.accountSummaries),
                const SizedBox(height: 20),

                // 6. Every Transaction Ledger Section
                _buildSectionTitle(
                  'Transaction Ledger (${controller.transactions.length})',
                ),
                const SizedBox(height: 10),
                _buildTransactionsLedgerCard(controller.transactions),

                const SizedBox(height: 80), // bottom bar spacing
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- 1. Top Header ---
  Widget _buildHeader(BuildContext context, String monthKey) {
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
          'Financial Reports',
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
            Icons.receipt_long_rounded,
            size: 20,
            color: Color(0xFF1E232A),
          ),
        ),
      ],
    );
  }

  // --- 2. Featured Executive Statement Card (matching Forest Dark theme) ---
  Widget _buildExecutiveStatementCard(
    BuildContext context,
    String monthKey,
    int availableCash,
    double savingsRatio,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(
          0xFF222824,
        ), // Forest Dark matching Accounts & Dashboard
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
          // Top-right Month pill badge
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                monthKey,
                style: const TextStyle(
                  color: Color(0xFFD4F938), // Neon lime
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Executive Statement',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyHelper.formatPaise(availableCash),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Net Liquid Cash in Envelopes',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: Color(0xFFD4F938),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Retention Ratio: ${savingsRatio.toStringAsFixed(1)}% Saved/Invested',
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

  // --- 3. Export PDF & CSV Action Buttons ---
  Widget _buildExportActions(
    String monthKey,
    int salary,
    int additional,
    int expenses,
    int savings,
    int investments,
    int availableCash,
  ) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ExportService.exportMonthlyReportPdf(
                monthTitle: monthKey,
                salaryPaise: salary,
                additionalIncomePaise: additional,
                expensesPaise: expenses,
                savingsPaise: savings,
                investmentsPaise: investments,
                netCashPaise: availableCash,
                transactions: controller.transactions,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F938), // Neon Lime button
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4F938).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                      color: Color(0xFF1E232A),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Export PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ExportService.exportTransactionsToCsv(
                controller.transactions,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEF0F2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.table_chart_rounded,
                      size: 18,
                      color: Color(0xFF1E232A),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Export CSV',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. Accounting Breakdown Card ---
  Widget _buildAccountingBreakdownCard({
    required int salary,
    required int additional,
    required int allocated,
    required int added,
    required int expenses,
    required int savings,
    required int investments,
    required int availableCash,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          _buildBreakdownItem(
            'Salary Income (Primary)',
            salary,
            color: const Color(0xFF22C55E),
            icon: Icons.work_outline_rounded,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Additional Income (Freelance/Gifts)',
            additional,
            color: const Color(0xFF22C55E),
            icon: Icons.attach_money_rounded,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Allocated Envelope Budget',
            allocated,
            color: const Color(0xFF1E232A),
            icon: Icons.pie_chart_outline_rounded,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Additional Account Credits',
            added,
            color: const Color(0xFF3B82F6),
            icon: Icons.add_circle_outline_rounded,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Total Actual Outflow (Expenses)',
            expenses,
            color: const Color(0xFFEF4444),
            icon: Icons.arrow_downward_rounded,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Savings Contributions',
            savings,
            color: const Color(0xFF8B5CF6),
            icon: Icons.savings_outlined,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Investment Contributions',
            investments,
            color: const Color(0xFFF59E0B),
            icon: Icons.trending_up_rounded,
          ),
          const Divider(color: Color(0xFFEEF0F2), height: 16),
          _buildBreakdownItem(
            'Net Liquid Cash Balance',
            availableCash,
            color: const Color(0xFF65B741),
            isBold: true,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    int amountPaise, {
    required Color color,
    required IconData icon,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF1E232A),
              ),
            ),
          ],
        ),
        Text(
          CurrencyHelper.formatPaise(amountPaise),
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- 5. Envelope Ledger Balances List ---
  Widget _buildEnvelopeBalancesList(List<AccountLedgerSummary> summaries) {
    if (summaries.isEmpty) {
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
      children: summaries.asMap().entries.map((entry) {
        final index = entry.key;
        final s = entry.value;
        final iconData = _getAccountIcon(s.account.name, index);
        final color = _getCategoryColor(s.account.name, index);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.account.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Spent: ${CurrencyHelper.formatPaise(s.expensesPaise, hideDecimals: true)} • Added: ${CurrencyHelper.formatPaise(s.additionalAddedPaise, hideDecimals: true)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8C95A3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyHelper.formatPaise(s.currentBalancePaise),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: s.currentBalancePaise < 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1E232A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 6. Transaction Ledger Card ---
  Widget _buildTransactionsLedgerCard(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF0F2)),
        ),
        child: Column(
          children: const [
            Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Color(0xFF8C95A3),
            ),
            SizedBox(height: 8),
            Text(
              'No transactions recorded for this period.',
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Color(0xFFEEF0F2), height: 1),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isIncome =
              tx.type.isIncomeCategory || tx.type == TransactionType.refund;

          final iconBgColor = isIncome
              ? const Color(0xFFE9F9E5)
              : const Color(0xFFFFECEF);
          final iconColor = isIncome
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444);
          final amountColor = isIncome
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateHelper.formatDate(tx.transactionDate)} • ${tx.type.nameString}${tx.paymentMethod != null ? ' • ${tx.paymentMethod}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8C95A3),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyHelper.formatPaise(tx.amountPaise)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
    if (lower.contains('food') || lower.contains('groc')) {
      return const Color(0xFF3B82F6);
    }
    if (lower.contains('travel') || lower.contains('fuel')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('entertain') || lower.contains('fun')) {
      return const Color(0xFFEC4899);
    }
    if (lower.contains('emergenc')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('invest')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('daily') || lower.contains('saver')) {
      return const Color(0xFF06B6D4);
    }
    if (lower.contains('rent') || lower.contains('house')) {
      return const Color(0xFFF97316);
    }

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
    if (lower.contains('food') || lower.contains('groc')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('travel') || lower.contains('fuel')) {
      return Icons.directions_car_filled_rounded;
    }
    if (lower.contains('entertain')) {
      return Icons.movie_outlined;
    }
    if (lower.contains('emergenc')) {
      return Icons.shield_rounded;
    }
    if (lower.contains('invest')) {
      return Icons.trending_up_rounded;
    }
    if (lower.contains('daily') || lower.contains('saver')) {
      return Icons.savings_outlined;
    }
    if (lower.contains('rent') || lower.contains('house')) {
      return Icons.home_rounded;
    }
    return Icons.account_balance_wallet_outlined;
  }
}
