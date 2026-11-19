import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/transaction_model.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final FinancialController controller = Get.find<FinancialController>();

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

          // Check if salary allocation has an Emergency category amount
          int allocatedEmergencyPaise = 0;
          final snapshot = controller.currentSnapshot.value;
          if (snapshot != null) {
            try {
              final Map<String, dynamic> rawAllocations =
                  jsonDecode(snapshot.allocationsJson) as Map<String, dynamic>;
              for (var entry in rawAllocations.values) {
                final data = Map<String, dynamic>.from(entry as Map);
                final name = (data['name'] as String?)?.toLowerCase() ?? '';
                if (name.contains('emergenc')) {
                  allocatedEmergencyPaise =
                      (data['amountPaise'] as num?)?.toInt() ?? 0;
                  break;
                }
              }
            } catch (_) {}
          }

          // Find or create emergency goal virtual object
          final storedEmergency = controller.savingsGoals.firstWhereOrNull(
            (g) => g.isEmergencyFund,
          );

          final emergencyGoal = storedEmergency != null
              ? (storedEmergency.currentSavedPaise == 0 &&
                        allocatedEmergencyPaise > 0
                    ? storedEmergency.copyWith(
                        currentSavedPaise: allocatedEmergencyPaise,
                        targetAmountPaise:
                            storedEmergency.targetAmountPaise >
                                allocatedEmergencyPaise
                            ? storedEmergency.targetAmountPaise
                            : allocatedEmergencyPaise * 3,
                      )
                    : storedEmergency)
              : SavingsGoalModel(
                  id: 'emergency_fund_default',
                  name: 'Emergency Fund',
                  targetAmountPaise: allocatedEmergencyPaise > 0
                      ? allocatedEmergencyPaise * 3
                      : 5000000,
                  currentSavedPaise: allocatedEmergencyPaise,
                  isEmergencyFund: true,
                );

          final customGoals = controller.savingsGoals
              .where((g) => !g.isEmergencyFund)
              .toList();

          return RefreshIndicator(
            color: const Color(0xFF65B741),
            onRefresh: controller.refreshAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // 1. Top Custom App Bar Header
                _buildHeader(context),
                const SizedBox(height: 16),

                // 2. Emergency Fund Featured Card
                _buildEmergencyFundCard(context, emergencyGoal),
                const SizedBox(height: 16),

                // 3. Emergency Fund Dynamic Activity Timeline Graph
                _buildEmergencyFundChart(context, emergencyGoal),
                const SizedBox(height: 18),

                // // 4. Daily Micro-Savings Challenge Card
                // _buildDailySavingsChallengeCard(context),
                // const SizedBox(height: 20),

                // 5. Goal-Based Pockets Section Header & Cards
                _buildGoalPocketsHeader(context, customGoals.length),
                const SizedBox(height: 10),

                if (customGoals.isEmpty)
                  _buildEmptyCustomGoalsState(context)
                else
                  ...customGoals.map(
                    (goal) => _buildGoalItemCard(context, goal),
                  ),

                const SizedBox(height: 80), // bottom bar spacing
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- 1. Top Custom Header ---
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
          'Savings & Emergency',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  // --- 2. Emergency Fund Featured Card (Forest Dark Theme) ---
  Widget _buildEmergencyFundCard(BuildContext context, SavingsGoalModel goal) {
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
          // Top right funded percentage pill
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
                '${(goal.progressPercentage * 100).toStringAsFixed(0)}% Funded',
                style: const TextStyle(
                  color: Color(0xFFD4F938), // Neon Lime
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFFD4F938),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Emergency Shield',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                CurrencyHelper.formatPaise(goal.currentSavedPaise),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Target: ${CurrencyHelper.formatPaise(goal.targetAmountPaise)} • Remaining: ${CurrencyHelper.formatPaise(goal.remainingTargetPaise)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progressPercentage,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFD4F938),
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4F938),
                        foregroundColor: const Color(0xFF1E232A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showDepositDialog(context, goal),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text(
                        'Deposit',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showWithdrawDialog(context, goal),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text(
                        'Withdraw',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Emergency Fund Timeline Chart ---
  Widget _buildEmergencyFundChart(BuildContext context, SavingsGoalModel goal) {
    final goalTxs = controller.transactions.where((t) {
      final isDeposit =
          t.type == TransactionType.savingsContribution &&
          (t.destinationAccountId == goal.accountId ||
              t.title.toLowerCase().contains(goal.name.toLowerCase()) ||
              (goal.isEmergencyFund &&
                  t.title.toLowerCase().contains('emergency')));
      final isWithdrawal =
          t.type == TransactionType.savingsWithdrawal &&
          (t.sourceAccountId == goal.accountId ||
              t.title.toLowerCase().contains(goal.name.toLowerCase()) ||
              (goal.isEmergencyFund &&
                  t.title.toLowerCase().contains('emergency')));
      return isDeposit || isWithdrawal;
    }).toList();

    goalTxs.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    final List<FlSpot> spots = [];
    int runningBalancePaise = 0;

    if (goalTxs.isEmpty) {
      final double currentRupees = CurrencyHelper.paiseToRupees(
        goal.currentSavedPaise,
      );
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot(1, currentRupees));
    } else {
      spots.add(const FlSpot(0, 0));
      for (int i = 0; i < goalTxs.length; i++) {
        final tx = goalTxs[i];
        if (tx.type == TransactionType.savingsContribution) {
          runningBalancePaise += tx.amountPaise;
        } else {
          runningBalancePaise = (runningBalancePaise - tx.amountPaise)
              .clamp(0, double.infinity)
              .toInt();
        }
        final double rupees = CurrencyHelper.paiseToRupees(runningBalancePaise);
        spots.add(FlSpot((i + 1).toDouble(), rupees));
      }
    }

    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 1000.0;
    // Calculate clean graduated intervals like ₹0, ₹100, ₹500, ₹1,000, ₹2,000...
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

    final double maxX = (spots.length - 1).toDouble().clamp(1.0, 50.0);

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
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: Color(0xFF65B741),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Activity Timeline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF1E232A),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyHelper.formatPaise(goal.currentSavedPaise),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF1E232A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Visualizes deposits (+) and emergency withdrawals (-)',
            style: TextStyle(fontSize: 11, color: Color(0xFF8C95A3)),
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
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      const FlLine(color: Color(0xFFF3F4F6), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (val != idx.toDouble()) {
                          return const SizedBox.shrink();
                        }
                        // Like the reference: 1, 2, 3, 4, 5, 6...
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
                        // Format clean amount like ₹0, ₹1,000, ₹2,000, ₹3,000...
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
                    color: const Color(
                      0xFFB91C1C,
                    ), // Classic crimson red curve like the sample chart
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
          // Legend below chart like in the reference image
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 16, height: 2.5, color: const Color(0xFFB91C1C)),
              const SizedBox(width: 6),
              const Text(
                'Emergency Fund Growth',
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
    );
  }

  // --- 4. Daily Micro-Savings Challenge Card ---
  Widget _buildDailySavingsChallengeCard(BuildContext context) {
    final dailyTiers = [10, 20, 50, 100];

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
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFF59E0B),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daily Micro-Savings',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1E232A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Automated Habit',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Deposit a quick savings amount seamlessly into your fund:',
            style: TextStyle(fontSize: 12, color: Color(0xFF8C95A3)),
          ),
          const SizedBox(height: 14),
          Row(
            children: dailyTiers.map((tier) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _depositDailyChallenge(tier),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEF0F2)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '₹$tier',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF1E232A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 5. Goal Pockets Header & List ---
  Widget _buildGoalPocketsHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Goal-Based Pockets ($count)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCustomGoalsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: const [
          Icon(Icons.savings_outlined, size: 44, color: Color(0xFF8C95A3)),
          SizedBox(height: 8),
          Text(
            'No custom savings goals yet',
            style: TextStyle(
              color: Color(0xFF8C95A3),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItemCard(BuildContext context, SavingsGoalModel goal) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1E232A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF22C55E),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${CurrencyHelper.formatPaise(goal.currentSavedPaise)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1E232A),
                ),
              ),
              Text(
                'Target: ${CurrencyHelper.formatPaise(goal.targetAmountPaise)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8C95A3)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF65B741),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showDepositDialog(context, goal),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Deposit', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showWithdrawDialog(context, goal),
                icon: const Icon(Icons.remove, size: 14),
                label: const Text('Withdraw', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _depositDailyChallenge(int rupees) {
    final emergencyGoal = controller.savingsGoals.firstWhereOrNull(
      (g) => g.isEmergencyFund,
    );
    final goalId =
        emergencyGoal?.id ??
        (controller.savingsGoals.isNotEmpty
            ? controller.savingsGoals.first.id
            : 'emergency_fund_default');
    final fromAccId = controller.accountSummaries.isNotEmpty
        ? controller.accountSummaries.first.account.id
        : 'acc_food';

    controller.addSavingsDeposit(
      goalId: goalId,
      amountPaise: CurrencyHelper.rupeesToPaise(rupees.toDouble()),
      fromAccountId: fromAccId,
    );
    Get.snackbar(
      'Savings Deposited',
      '₹$rupees added to your goal.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  void _showDepositDialog(BuildContext context, SavingsGoalModel goal) {
    final amountCtrl = TextEditingController();
    String? sourceAccId = controller.accountSummaries.isNotEmpty
        ? controller.accountSummaries.first.account.id
        : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deposit to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Deposit Amount (₹)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: sourceAccId,
              decoration: const InputDecoration(
                labelText: 'From Budget Account',
              ),
              items: controller.accountSummaries.map((s) {
                return DropdownMenuItem(
                  value: s.account.id,
                  child: Text(s.account.name),
                );
              }).toList(),
              onChanged: (val) => sourceAccId = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rupees = double.tryParse(amountCtrl.text) ?? 0.0;
              if (rupees > 0 && sourceAccId != null) {
                controller.addSavingsDeposit(
                  goalId: goal.id,
                  amountPaise: CurrencyHelper.rupeesToPaise(rupees),
                  fromAccountId: sourceAccId!,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, SavingsGoalModel goal) {
    final amountCtrl = TextEditingController();
    String? destAccId = controller.accountSummaries.isNotEmpty
        ? controller.accountSummaries.first.account.id
        : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw from ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Withdrawal Amount (₹)',
                helperText:
                    'Available: ${CurrencyHelper.formatPaise(goal.currentSavedPaise)}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: destAccId,
              decoration: const InputDecoration(labelText: 'Credit To Account'),
              items: controller.accountSummaries.map((s) {
                return DropdownMenuItem(
                  value: s.account.id,
                  child: Text(s.account.name),
                );
              }).toList(),
              onChanged: (val) => destAccId = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final rupees = double.tryParse(amountCtrl.text) ?? 0.0;
              final withdrawPaise = CurrencyHelper.rupeesToPaise(rupees);
              if (rupees > 0 && destAccId != null) {
                if (withdrawPaise > goal.currentSavedPaise) {
                  Get.snackbar(
                    'Insufficient Balance',
                    'Cannot withdraw more than current savings.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: const Color(0xFFEF4444),
                    colorText: Colors.white,
                  );
                  return;
                }
                controller.withdrawSavingsGoal(
                  goalId: goal.id,
                  amountPaise: withdrawPaise,
                  toAccountId: destAccId!,
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
}
