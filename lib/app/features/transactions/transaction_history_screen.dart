import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/widgets/transaction_list_item.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FinancialController controller = Get.find<FinancialController>();

  String _searchQuery = '';
  TransactionType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV Spreadsheet',
            onPressed: () => ExportService.exportTransactionsToCsv(controller.transactions),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF Report',
            onPressed: () => ExportService.exportMonthlyReportPdf(
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
        onPressed: () => Get.to(() => const AddTransactionScreen()),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions by title or description...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All', _typeFilter == null, () => setState(() => _typeFilter = null)),
                _buildFilterChip('Expenses', _typeFilter == TransactionType.expense,
                    () => setState(() => _typeFilter = TransactionType.expense)),
                _buildFilterChip('Added Money', _typeFilter == TransactionType.addMoney,
                    () => setState(() => _typeFilter = TransactionType.addMoney)),
                _buildFilterChip('Income', _typeFilter == TransactionType.additionalIncome,
                    () => setState(() => _typeFilter = TransactionType.additionalIncome)),
                _buildFilterChip('Transfers', _typeFilter == TransactionType.transfer,
                    () => setState(() => _typeFilter = TransactionType.transfer)),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Transaction List
          Expanded(
            child: Obx(() {
              final filtered = controller.transactions.where((TransactionModel t) {
                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final matchTitle = t.title.toLowerCase().contains(_searchQuery);
                  final matchDesc = t.description?.toLowerCase().contains(_searchQuery) ?? false;
                  if (!matchTitle && !matchDesc) return false;
                }
                // Type filter
                if (_typeFilter != null && t.type != _typeFilter) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No transactions match the selected filters.',
                          style: TextStyle(color: AppColors.textSecondaryLight)),
                    ],
                  ),
                );
              }

              // Calculate Filtered Totals
              int totalFilteredPaise = filtered.fold<int>(0, (int sum, TransactionModel t) => sum + t.amountPaise);

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.backgroundLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${filtered.length} Transactions',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Total: ${CurrencyHelper.formatPaise(totalFilteredPaise)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return TransactionListItem(
                          transaction: tx,
                          onDelete: () => controller.deleteTransaction(tx.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimaryLight)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
