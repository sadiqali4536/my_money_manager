import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/investment_model.dart';
import '../../data/models/transaction_model.dart';

class InvestmentScreen extends StatelessWidget {
  final FinancialController controller = Get.find<FinancialController>();

  InvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Portfolio Tracker'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalValuation = controller.totalInvestmentValuation.value;
        final totalCost = controller.totalInvestmentCost.value;

        // Check if salary allocation has an Investment category amount
        int allocatedInvestmentPaise = 0;
        String? allocatedInvestmentCatName;
        String? allocatedInvestmentAccountId;
        final snapshot = controller.currentSnapshot.value;
        if (snapshot != null) {
          try {
            final Map<String, dynamic> rawAllocations =
                jsonDecode(snapshot.allocationsJson) as Map<String, dynamic>;
            for (var entry in rawAllocations.values) {
              final data = Map<String, dynamic>.from(entry as Map);
              final name = (data['name'] as String?)?.toLowerCase() ?? '';
              if (name.contains('invest')) {
                allocatedInvestmentPaise =
                    (data['amountPaise'] as num?)?.toInt() ?? 0;
                allocatedInvestmentCatName = data['name'] as String?;
                allocatedInvestmentAccountId = data['accountId'] as String?;
                break;
              }
            }
          } catch (_) {}
        }

        // Active list of investments, including allocated holding if none explicitly created
        final activeInvestments = List<InvestmentModel>.from(controller.investments);
        if (activeInvestments.isEmpty && allocatedInvestmentPaise > 0) {
          activeInvestments.add(
            InvestmentModel(
              id: 'allocated_investment_default',
              name: allocatedInvestmentCatName ?? 'Salary Investment Fund',
              type: InvestmentType.sip,
              totalInvestedPaise: allocatedInvestmentPaise,
              currentValuePaise: allocatedInvestmentPaise,
              startDate: DateTime.now(),
              accountId: allocatedInvestmentAccountId,
              notes: 'Allocated from monthly salary',
            ),
          );
        }

        final displayCost = totalCost > 0
            ? totalCost
            : (activeInvestments.isNotEmpty
                ? activeInvestments.fold<int>(0, (sum, i) => sum + i.totalInvestedPaise)
                : allocatedInvestmentPaise);

        final displayValuation = totalValuation > 0
            ? totalValuation
            : (activeInvestments.isNotEmpty
                ? activeInvestments.fold<int>(0, (sum, i) => sum + i.currentValuePaise)
                : allocatedInvestmentPaise);

        final totalPL = displayValuation - displayCost;
        final double overallReturnPct = displayCost > 0 ? (totalPL / displayCost) * 100.0 : 0.0;
        final isProfit = totalPL >= 0;

        // Investment related transactions (contributions & withdrawals)
        final investmentTxs = controller.transactions.where((t) {
          final isInvContribution = t.type == TransactionType.investmentContribution;
          final isInvWithdrawal = (t.type == TransactionType.refund || t.type == TransactionType.savingsWithdrawal) &&
              (t.title.toLowerCase().contains('investment') ||
                  (t.description != null && t.description!.toLowerCase().contains('redeemed')));
          return isInvContribution || isInvWithdrawal;
        }).toList();

        // Sort descending for transaction history list
        investmentTxs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Portfolio Valuation Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Portfolio Current Value',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isProfit ? AppColors.success : AppColors.expense,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isProfit ? '+' : ''}${overallReturnPct.toStringAsFixed(2)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyHelper.formatPaise(displayValuation),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Invested Amount', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(CurrencyHelper.formatPaise(displayCost),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Profit / Loss', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              '${isProfit ? '+' : ''}${CurrencyHelper.formatPaise(totalPL)}',
                              style: TextStyle(
                                color: isProfit ? AppColors.successLight : AppColors.expenseLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Graphical Chart of Investment Growth & Decreases over time
              _buildInvestmentGrowthChart(context, investmentTxs, displayCost),

              const SizedBox(height: 20),

              // 3. Holdings & SIPs Header and List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Holdings & Instruments (${activeInvestments.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (activeInvestments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.trending_up_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No investments recorded yet', style: TextStyle(color: AppColors.textSecondaryLight)),
                    ],
                  ),
                )
              else
                ...activeInvestments.map((inv) => _buildInvestmentCard(context, inv)),

              const SizedBox(height: 24),

              // 4. Investment-Only Transaction History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Investment Activity History (${investmentTxs.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInvestmentTransactionHistory(context, investmentTxs),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // --- Investment Growth Chart ---
  Widget _buildInvestmentGrowthChart(
    BuildContext context,
    List<TransactionModel> txs,
    int currentInvestedPaise,
  ) {
    // Chronological order for line progression
    final chronologicalTxs = List<TransactionModel>.from(txs);
    chronologicalTxs.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    final List<FlSpot> spots = [];
    int runningInvestedPaise = 0;

    if (chronologicalTxs.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot(1, CurrencyHelper.paiseToRupees(currentInvestedPaise)));
    } else {
      spots.add(const FlSpot(0, 0));
      for (int i = 0; i < chronologicalTxs.length; i++) {
        final tx = chronologicalTxs[i];
        final isContribution = tx.type == TransactionType.investmentContribution;
        if (isContribution) {
          runningInvestedPaise += tx.amountPaise;
        } else {
          runningInvestedPaise = (runningInvestedPaise - tx.amountPaise).clamp(0, double.infinity).toInt();
        }
        final rupees = CurrencyHelper.paiseToRupees(runningInvestedPaise);
        spots.add(FlSpot((i + 1).toDouble(), rupees));
      }
    }

    final double maxX = (spots.length - 1).toDouble().clamp(1.0, 100.0);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 1000.0;
    final double rawMax = maxY * 1.15;
    double interval = 500;
    if (rawMax <= 100) {
      interval = 20;
    } else if (rawMax <= 500) {
      interval = 100;
    } else if (rawMax <= 1000) {
      interval = 200;
    } else if (rawMax <= 2500) {
      interval = 500;
    } else if (rawMax <= 5000) {
      interval = 1000;
    } else if (rawMax <= 10000) {
      interval = 2000;
    } else {
      interval = (rawMax / 5).ceilToDouble();
    }
    maxY = (rawMax / interval).ceil() * interval;
    if (maxY == 0) maxY = interval * 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Investment Progression Over Time',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  CurrencyHelper.formatPaise(currentInvestedPaise),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tracks capital additions (deposits) and redeemed holdings (withdrawals)',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => const FlLine(
                      color: Color(0xFFF3F4F6),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (val != idx.toDouble()) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              idx == 0 ? '0' : '$idx',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E232A),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: interval,
                        getTitlesWidget: (val, meta) {
                          if (val < 0 || val > maxY) {
                            return const SizedBox.shrink();
                          }
                          final int amount = val.round();
                          final String formatted = NumberFormat.currency(
                            locale: 'en_IN',
                            symbol: '₹',
                            decimalDigits: 0,
                          ).format(amount);
                          return Text(
                            formatted,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E232A),
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Color(0xFF9CA3AF), width: 1.5),
                      bottom: BorderSide(color: Color(0xFF9CA3AF), width: 1.5),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFFB91C1C), // Crimson red curve matching the reference chart
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 16, height: 2.5, color: const Color(0xFFB91C1C)),
                const SizedBox(width: 6),
                const Text(
                  'Investment Growth',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E232A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Investment Card with Add/Withdraw Actions ---
  Widget _buildInvestmentCard(BuildContext context, InvestmentModel inv) {
    final isProfit = inv.isProfitable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Text(inv.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(inv.type.displayName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isProfit ? AppColors.successLight : AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isProfit ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isProfit ? AppColors.success : AppColors.expense,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invested Cost', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 2),
                    Text(CurrencyHelper.formatPaise(inv.totalInvestedPaise), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Current Valuation', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyHelper.formatPaise(inv.currentValuePaise),
                      style: TextStyle(fontWeight: FontWeight.w700, color: isProfit ? AppColors.success : AppColors.expense),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddMoneyToHoldingDialog(context, inv),
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Add Money', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showWithdrawFromHoldingDialog(context, inv),
                  icon: const Icon(Icons.remove_circle_outline, size: 14),
                  label: const Text('Withdraw', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: () => _showUpdateValuationDialog(context, inv),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                  label: const Text('Valuation', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Investment Transaction History List ---
  Widget _buildInvestmentTransactionHistory(BuildContext context, List<TransactionModel> txs) {
    if (txs.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: const Text(
            'No investment transactions recorded yet.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: txs.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.dividerLight, height: 1),
        itemBuilder: (context, index) {
          final tx = txs[index];
          final isDeposit = tx.type == TransactionType.investmentContribution;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDeposit ? const Color(0xFFF3E8FF) : const Color(0xFFFFECEF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDeposit ? Icons.add_chart_rounded : Icons.money_off_rounded,
                    color: isDeposit ? const Color(0xFF8B5CF6) : AppColors.expense,
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateHelper.formatDate(tx.transactionDate)} • ${isDeposit ? "Deposit" : "Withdrawal"}${tx.description != null ? " • ${tx.description}" : ""}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isDeposit ? "+" : "-"}${CurrencyHelper.formatPaise(tx.amountPaise)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDeposit ? const Color(0xFF8B5CF6) : AppColors.expense,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMoneyToHoldingDialog(BuildContext context, InvestmentModel inv) {
    final amountCtrl = TextEditingController();
    String? fromAccId = controller.accountSummaries.isNotEmpty ? controller.accountSummaries.first.account.id : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Money to ${inv.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Additional Investment (₹)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: fromAccId,
              decoration: const InputDecoration(labelText: 'Deduct From Account'),
              items: controller.accountSummaries.map((s) {
                return DropdownMenuItem(value: s.account.id, child: Text(s.account.name));
              }).toList(),
              onChanged: (val) => fromAccId = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final rupees = double.tryParse(amountCtrl.text) ?? 0.0;
              if (rupees > 0 && fromAccId != null) {
                controller.depositToInvestment(
                  investmentId: inv.id,
                  amountPaise: CurrencyHelper.rupeesToPaise(rupees),
                  fromAccountId: fromAccId!,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawFromHoldingDialog(BuildContext context, InvestmentModel inv) {
    final amountCtrl = TextEditingController();
    String? toAccId = controller.accountSummaries.isNotEmpty ? controller.accountSummaries.first.account.id : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw from ${inv.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Withdrawal Amount (₹)',
                helperText: 'Current Invested: ${CurrencyHelper.formatPaise(inv.totalInvestedPaise)}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: toAccId,
              decoration: const InputDecoration(labelText: 'Credit To Account'),
              items: controller.accountSummaries.map((s) {
                return DropdownMenuItem(value: s.account.id, child: Text(s.account.name));
              }).toList(),
              onChanged: (val) => toAccId = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
            onPressed: () {
              final rupees = double.tryParse(amountCtrl.text) ?? 0.0;
              final withdrawPaise = CurrencyHelper.rupeesToPaise(rupees);
              if (rupees > 0 && toAccId != null) {
                if (withdrawPaise > inv.totalInvestedPaise) {
                  Get.snackbar('Insufficient Units', 'Cannot withdraw more than total invested amount.',
                      snackPosition: SnackPosition.TOP, backgroundColor: AppColors.expense, colorText: Colors.white);
                  return;
                }
                controller.withdrawFromInvestment(
                  investmentId: inv.id,
                  amountPaise: withdrawPaise,
                  toAccountId: toAccId!,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showUpdateValuationDialog(BuildContext context, InvestmentModel inv) {
    final valueCtrl = TextEditingController(text: CurrencyHelper.paiseToRupees(inv.currentValuePaise).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Valuation: ${inv.name}'),
        content: TextField(
          controller: valueCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Current Value (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final rupees = double.tryParse(valueCtrl.text) ?? 0.0;
              if (rupees >= 0) {
                controller.updateInvestmentValuation(inv.id, CurrencyHelper.rupeesToPaise(rupees));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
