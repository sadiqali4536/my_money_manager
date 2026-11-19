import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/controllers/app_lock_controller.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../analytics/analytics_screen.dart';
import '../investments/investment_screen.dart';
import '../recurring/recurring_transactions_screen.dart';
import '../reports/monthly_reports_screen.dart';
import '../salary_allocation/salary_allocation_screen.dart';
import '../savings/savings_screen.dart';

class SettingsScreen extends StatelessWidget {
  final FinancialController controller = Get.find<FinancialController>();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          children: [
            // App Bar Header
            const Center(
              child: Text(
                'Profile & Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E232A),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF222824), // Dark tone matching theme
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFD4F938),
                    child: Icon(Icons.person_rounded, size: 34, color: Color(0xFF1E232A)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Account Vault',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Base Currency: INR (₹) • Offline Local Vault',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Embedded Financial Analytics & Reports Section
            _buildSectionHeader('Financial Analytics & Insights'),
            _buildActionTile(
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBgColor: const Color(0xFFE6F3FF),
              title: 'Detailed Financial Analytics',
              subtitle: 'Category-wise spending breakdown, monthly trends & charts',
              onTap: () => Get.to(() => const AnalyticsScreen()),
            ),
            _buildActionTile(
              icon: Icons.assessment_outlined,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFE9F9E5),
              title: 'Financial Statements & Reports',
              subtitle: 'Monthly executive summaries, wealth retention metrics',
              onTap: () => Get.to(() => MonthlyReportsScreen()),
            ),

            const SizedBox(height: 18),

            // System Modules
            _buildSectionHeader('Wealth & Automation Modules'),
            _buildActionTile(
              icon: Icons.savings_outlined,
              iconColor: const Color(0xFF22C55E),
              iconBgColor: const Color(0xFFE9F9E5),
              title: 'Savings & Emergency Fund',
              subtitle: 'Manage goals, targets, and micro-savings challenges',
              onTap: () => Get.to(() => SavingsScreen()),
            ),
            _buildActionTile(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFF3E8FF),
              title: 'Investment Portfolio',
              subtitle: 'Track SIPs, mutual funds, FDs, and profit/loss valuation',
              onTap: () => Get.to(() => InvestmentScreen()),
            ),
            _buildActionTile(
              icon: Icons.event_repeat_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFFF6E6),
              title: 'Recurring Transactions',
              subtitle: 'Automated recurring salary, bills, and monthly dues',
              onTap: () => Get.to(() => RecurringTransactionsScreen()),
            ),

            const SizedBox(height: 18),

            // Privacy & Security (App Lock)
            _buildSectionHeader('Privacy & Security'),
            Obx(() {
              final lockController = AppLockController.to;
              final isEnabled = lockController.isAppLockEnabled.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0F1F3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF082B63).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF082B63),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'App Lock',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E232A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Protect your app with a PIN',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8C95A3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isEnabled,
                        activeColor: const Color(0xFF082B63), // Navy Blue
                        activeTrackColor: const Color(0xFFD4F938), // Yellow / Lime accent
                        onChanged: (val) {
                          lockController.handleToggle(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 18),

            // Data & Safety
            _buildSectionHeader('Data Management & Safety'),
            _buildActionTile(
              icon: Icons.table_chart_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              title: 'Export Transactions as CSV',
              subtitle: 'Excel-compatible raw data export',
              onTap: () => ExportService.exportTransactionsToCsv(controller.transactions),
            ),
            _buildActionTile(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFFECEF),
              title: 'Export Complete PDF Statement',
              subtitle: 'Print or share official ledger report',
              onTap: () => ExportService.exportMonthlyReportPdf(
                monthTitle: DateHelper.formatMonthYear(controller.selectedMonth.value),
                salaryPaise: controller.totalSalaryIncome.value,
                additionalIncomePaise: controller.totalAdditionalIncome.value,
                expensesPaise: controller.totalSpent.value,
                savingsPaise: controller.totalSavingsContributions.value,
                investmentsPaise: controller.totalInvestmentsContributions.value,
                netCashPaise: controller.totalAvailableCash.value,
                transactions: controller.transactions,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8C95A3),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
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
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8C95A3),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
