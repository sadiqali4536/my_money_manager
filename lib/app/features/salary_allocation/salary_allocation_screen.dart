import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/allocation_calculator.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/budget_model.dart';
import '../transactions/add_transaction_screen.dart';

class SalaryAllocationScreen extends StatefulWidget {
  final bool showBackButton;
  const SalaryAllocationScreen({super.key, this.showBackButton = false});

  @override
  State<SalaryAllocationScreen> createState() => _SalaryAllocationScreenState();
}

class _SalaryAllocationScreenState extends State<SalaryAllocationScreen> {
  final FinancialController controller = Get.find<FinancialController>();
  late TextEditingController _salaryInputController;
  late List<BudgetCategoryModel> _editableCategories;
  double _salaryRupees = 0.0;

  @override
  void initState() {
    super.initState();
    final initialPaise =
        controller.currentSnapshot.value?.salaryPaise ??
        (controller.totalSalaryIncome.value > 0
            ? controller.totalSalaryIncome.value
            : 0);
    _salaryRupees = CurrencyHelper.paiseToRupees(initialPaise);
    _salaryInputController = TextEditingController(
      text: _salaryRupees.toStringAsFixed(0),
    );
    _editableCategories = List.from(controller.budgetCategories);
  }

  @override
  void dispose() {
    _salaryInputController.dispose();
    super.dispose();
  }

  double get _totalPercentage {
    return AllocationCalculator.calculateTotalPercentage(_editableCategories);
  }

  bool get _isValid100Percent =>
      AllocationCalculator.isExact100Percent(_totalPercentage);

  bool get _isValidAllocation {
    final hasFixed = _editableCategories.any((c) => c.isFixed);
    if (!hasFixed) {
      return _isValid100Percent;
    }
    // With fixed amounts, valid when salary is entered and total allocated <= total salary
    return _salaryRupees > 0 && (_totalAllocatedPaise <= _totalSalaryPaise);
  }

  int get _totalSalaryPaise => CurrencyHelper.rupeesToPaise(_salaryRupees);

  AllocationCalculationResult get _allocationResult {
    return AllocationCalculator.calculateAllocations(
      totalSalaryPaise: _totalSalaryPaise,
      categories: _editableCategories,
    );
  }

  int get _totalAllocatedPaise => _allocationResult.totalAllocatedPaise;

  int get _remainingDecimalPaise => _allocationResult.remainingDecimalPaise;

  int get _remainingUnallocatedPaise =>
      _allocationResult.remainingUnallocatedPaise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top App Bar (does not scroll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildTopAppBar(context),
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0066FF),
                onRefresh: controller.refreshAllData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Blue Curved Salary Card with Calculate button
                      _buildSalaryInputCard(context),
                      const SizedBox(height: 12),

                      // 3. Status Banner: Allocation is perfect / Warning
                      _buildStatusBanner(context),
                      const SizedBox(height: 16),

                      // 4. Section Header: Allocation Categories & "+ Add Category"
                      _buildCategoriesHeader(context),
                      const SizedBox(height: 12),

                      // 5. Reorderable Categories List
                      _buildCategoriesList(context),
                      const SizedBox(height: 16),

                      // 6. Summary: Total Allocated & Remaining Unallocated
                      _buildSummaryBox(context),
                      const SizedBox(height: 14),

                      // 6b. Remaining Decimal Amount Card
                      if (_remainingDecimalPaise > 0) ...[
                        _buildRemainingDecimalCard(context),
                        const SizedBox(height: 14),
                      ],

                      // 7. Allocation warning banner if > 100% or < 100%
                      if (!_isValid100Percent) ...[
                        _buildWarningBanner(context),
                        const SizedBox(height: 14),
                      ],

                      // 8. Reset Allocation Outline Button
                      _buildResetButton(context),
                      const SizedBox(height: 12),

                      // 9. Save Allocation Solid Blue Button
                      _buildSaveButton(context),

                      const SizedBox(height: 80), // spacing for bottom bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Top App Bar ---
  Widget _buildTopAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.showBackButton || Navigator.canPop(context))
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
          'Salary Allocation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: Color(0xFF1E232A),
          ),
          onPressed: () => _showInfoDialog(context),
        ),
      ],
    );
  }

  // --- 2. Blue Curved Salary Card ---
  Widget _buildSalaryInputCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter Your Monthly Salary',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Floating 3D wallet illustration badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFFFFD54F),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // White rounded container with Salary text field & pencil
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '₹ ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _salaryInputController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E232A),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _salaryRupees =
                                  double.tryParse(val.replaceAll(',', '')) ??
                                  0.0;
                            });
                          },
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Yellow Calculate / Clear Button
              InkWell(
                onTap: () {
                  if (_salaryInputController.text.trim().isNotEmpty) {
                    setState(() {
                      _salaryInputController.clear();
                      _salaryRupees = 0.0;
                    });
                  } else {
                    FocusScope.of(context).unfocus();
                    setState(() {});
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F), // Gold yellow
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _salaryInputController.text.trim().isNotEmpty
                            ? Icons.close_rounded
                            : Icons.calculate_rounded,
                        size: 18,
                        color: const Color(0xFF1E232A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _salaryInputController.text.trim().isNotEmpty
                            ? 'Clear'
                            : 'Calculate',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Status Banner ---
  Widget _buildStatusBanner(BuildContext context) {
    final allocResult = _allocationResult;
    final hasFixed = _editableCategories.any((c) => c.isFixed);
    final hasPercentage = _editableCategories.any((c) => !c.isFixed);

    if (hasFixed) {
      if (allocResult.isFixedExceedingSalary) {
        final exceedPaise =
            allocResult.totalFixedAllocationsPaise - _totalSalaryPaise;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD8A8)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF97316),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fixed amounts exceed salary by ${CurrencyHelper.formatPaise(exceedPaise, hideDecimals: true)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    const Text(
                      'Please reduce fixed allocations or increase salary.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final isExactMatch =
          _salaryRupees > 0 &&
          (_totalAllocatedPaise + _remainingDecimalPaise == _totalSalaryPaise);

      if (isExactMatch && (!hasPercentage || _isValid100Percent)) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F9E5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB7EB8F)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Allocation is perfect! 🎉',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    Text(
                      'Fixed: ${CurrencyHelper.formatPaise(allocResult.totalFixedAllocationsPaise, hideDecimals: true)}  •  Remaining Salary: ${CurrencyHelper.formatPaise(allocResult.remainingSalaryForPercentagesPaise, hideDecimals: true)} (100% distributed)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 20,
              ),
            ],
          ),
        );
      } else {
        final remainingSalaryPaise =
            allocResult.remainingSalaryForPercentagesPaise;
        final unallocatedPaise = allocResult.unallocatedPortionPaise;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fixed: ${CurrencyHelper.formatPaise(allocResult.totalFixedAllocationsPaise, hideDecimals: true)}  |  Avail. for %: ${CurrencyHelper.formatPaise(remainingSalaryPaise, hideDecimals: true)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    Text(
                      hasPercentage
                          ? (_totalPercentage < 100
                                ? 'Percentages total ${_totalPercentage.toStringAsFixed(1)}% (Missing ${(100 - _totalPercentage).toStringAsFixed(1)}% of remaining salary)'
                                : 'Percentages exceed 100% by ${(_totalPercentage - 100).toStringAsFixed(1)}%')
                          : 'Unallocated Salary: ${CurrencyHelper.formatPaise(unallocatedPaise, hideDecimals: true)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    if (_isValid100Percent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F9E5), // Soft green
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB7EB8F)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allocation is perfect! 🎉',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                  Text(
                    'Total equals your salary',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 20,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFF97316),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Total: ${_totalPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                  ),
                ),
                Text(
                  _totalPercentage < 100
                      ? 'Please allocate the remaining ${(100 - _totalPercentage).toStringAsFixed(1)}%'
                      : 'Allocations exceed 100% by ${(_totalPercentage - 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Section Header: Allocation Categories & "+ Add Category" ---
  Widget _buildCategoriesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Allocation Categories',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        InkWell(
          onTap: _showAddCategoryDialog,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
                SizedBox(width: 3),
                Text(
                  'Add Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 5. Categories List (Reorderable / Editable) ---
  Widget _buildCategoriesList(BuildContext context) {
    if (_editableCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F1F3)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                color: Color(0xFF4F46E5),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Allocation Categories Yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E232A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "+ Add Category" above to create your custom budget envelopes (e.g. Food, Travel, Rent).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8C95A3),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final allocResult = _allocationResult;

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _editableCategories.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _editableCategories.removeAt(oldIndex);
            _editableCategories.insert(newIndex, item);
          });
          controller.updateBudgetCategories(_editableCategories);
        },
        itemBuilder: (context, index) {
          final cat = _editableCategories[index];
          final catAmountPaise = allocResult.categoryAmountsPaise[cat.id] ?? 0;

          // Get spent & remaining from controller account summary
          int spentPaise = 0;
          int remainingPaise = catAmountPaise;

          final matchSummary = controller.accountSummaries.firstWhereOrNull(
            (s) => s.account.id == cat.accountId,
          );
          if (matchSummary != null) {
            spentPaise = matchSummary.expensesPaise;
            final totalBalance = matchSummary.currentBalancePaise;
            remainingPaise = totalBalance > 0
                ? totalBalance
                : (catAmountPaise - spentPaise);
          }

          final progress = catAmountPaise > 0
              ? (spentPaise / catAmountPaise).clamp(0.0, 1.0)
              : 0.0;

          final iconData = _getCategoryIcon(cat.name);
          final iconColor = _getCategoryColor(cat.name, index);
          final iconBgColor = iconColor.withOpacity(0.12);

          return Container(
            key: ValueKey(cat.id),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon container
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Name + Spent / Remaining
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showEditCategoryDialog(index),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E232A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 12,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Spent: ${CurrencyHelper.formatPaise(spentPaise, hideDecimals: true)}  |  Remaining: ${CurrencyHelper.formatPaise(remainingPaise, hideDecimals: true)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8C95A3),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Mini Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFF1F3F5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Percentage / Fixed Amount Dropdown / Pill with Custom Input option
                    InkWell(
                      onTap: () => _showEditPercentageDialog(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat.isFixed
                                  ? CurrencyHelper.formatPaise(
                                      cat.fixedAmountPaise,
                                      hideDecimals: true,
                                    )
                                  : (cat.percentage ==
                                            cat.percentage.roundToDouble()
                                        ? '${cat.percentage.toInt()}%'
                                        : '${cat.percentage.toStringAsFixed(1)}%'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E232A),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Calculated Rupee Amount with exact & decimal tooltip/breakdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyHelper.formatPaise(
                            catAmountPaise,
                            hideDecimals: true,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E232A),
                          ),
                        ),
                        if (cat.allocatedRemainderPaise > 0)
                          Text(
                            '+₹${(cat.allocatedRemainderPaise / 100.0).toStringAsFixed(2)} rem added',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF22C55E),
                            ),
                          )
                        else if (allocResult
                                    .categoryDetails[cat.id]
                                    ?.decimalPaise !=
                                null &&
                            (allocResult
                                        .categoryDetails[cat.id]
                                        ?.decimalPaise ??
                                    0) >
                                0)
                          Text(
                            '+₹${(allocResult.categoryDetails[cat.id]!.decimalPaise / 100.0).toStringAsFixed(2).substring(1)} rem',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 6),

                    // Reorder handle & Delete icon
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        size: 18,
                        color: Colors.black26,
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final removedCat = _editableCategories[index];
                        setState(() {
                          _editableCategories.removeAt(index);
                        });
                        controller.deleteBudgetCategory(removedCat.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 6. Summary: Total Allocated & Remaining Unallocated ---
  Widget _buildSummaryBox(BuildContext context) {
    final allocResult = _allocationResult;
    final hasFixed = _editableCategories.any((c) => c.isFixed);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left: Total Allocated (Whole Rupees)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Allocated',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          CurrencyHelper.formatPaise(
                            _totalAllocatedPaise,
                            hideDecimals: true,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF22C55E),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
              // Right: Remaining Unallocated / Decimal Balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isValid100Percent && _remainingDecimalPaise > 0
                          ? 'Decimal Remainder'
                          : 'Remaining Unallocated',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isValid100Percent
                          ? '₹${(_remainingDecimalPaise / 100.0).toStringAsFixed(2)}'
                          : CurrencyHelper.formatPaise(
                              _remainingUnallocatedPaise,
                              hideDecimals: true,
                            ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _remainingUnallocatedPaise == 0
                            ? const Color(0xFF22C55E)
                            : (_isValid100Percent
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasFixed) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Total Fixed: ${CurrencyHelper.formatPaise(allocResult.totalFixedAllocationsPaise, hideDecimals: true)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Remaining Salary: ${CurrencyHelper.formatPaise(allocResult.remainingSalaryForPercentagesPaise, hideDecimals: true)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 6b. Remaining Decimal Amount Card ---
  Widget _buildRemainingDecimalCard(BuildContext context) {
    final decimalRupeesStr =
        '₹${(_remainingDecimalPaise / 100.0).toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Remaining Decimal Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  decimalRupeesStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This amount comes from the decimal portions of all category calculations. Category balances only receive whole rupees, keeping the fractional sum separate.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showAllocateRemainingBottomSheet,
              icon: const Icon(Icons.call_split_rounded, size: 16),
              label: const Text(
                'Allocate Remaining Amount',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 7. Warning Banner ---
  Widget _buildWarningBanner(BuildContext context) {
    final diff = (_totalPercentage - 100.0).abs();
    final isExceed = _totalPercentage > 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft amber
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExceed
                      ? 'Warning: Allocations exceed 100%'
                      : 'Warning: Allocations are under 100%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isExceed
                      ? 'Exceeds by ${diff.toStringAsFixed(1)}%. Please adjust your percentages.'
                      : 'Missing ${diff.toStringAsFixed(1)}%. Please distribute to reach 100%.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
        ],
      ),
    );
  }

  // --- 8. Reset Button ---
  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          foregroundColor: const Color(0xFF2563EB),
        ),
        onPressed: _resetDefaultPercentages,
        icon: const Icon(Icons.restart_alt_rounded, size: 20),
        label: const Text(
          'Reset Allocation',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  // --- 9. Save Button ---
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066FF), // Figma Royal Blue
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: _isValidAllocation && _salaryRupees > 0
            ? _saveAllocation
            : null,
        icon: const Icon(Icons.save_rounded, size: 18),
        label: const Text(
          'Save Allocation',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  // --- Helpers & Dialogs ---
  bool _isResetting = false;

  void _showResetConfirmationDialog() {
    if (_isResetting) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Are you sure?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to reset the salary allocation? All current allocation data and previously allocated remaining amounts will be cleared.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (_isResetting) return;
              _isResetting = true;
              Navigator.pop(ctx);
              try {
                await _executeClearAllAllocations();
              } finally {
                _isResetting = false;
              }
            },
            child: const Text('Reset Allocation'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeClearAllAllocations() async {
    setState(() {
      _salaryRupees = 0.0;
      _salaryInputController.text = '0';
      _editableCategories = _editableCategories.map((cat) {
        return cat.copyWith(
          percentage: 0.0,
          fixedAmountPaise: 0,
          allocatedRemainderPaise: 0,
        );
      }).toList();
    });

    // 1. Clear remaining decimal allocations and reverse internal remaining ledger transactions
    await controller.clearRemainingDecimalAllocations();

    // 2. Persist reset categories in controller & storage
    await controller.updateBudgetCategories(_editableCategories);

    Get.snackbar(
      'Allocation Reset',
      'Salary allocation and remaining decimal amounts have been reset to ₹0.00.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  void _resetDefaultPercentages() {
    _showResetConfirmationDialog();
  }

  Future<void> _saveAllocation() async {
    final salaryPaise = CurrencyHelper.rupeesToPaise(_salaryRupees);
    await controller.saveMonthlySalaryAllocation(
      salaryPaise: salaryPaise,
      categories: _editableCategories,
    );
    Get.snackbar(
      'Allocation Saved',
      'Monthly allocation for ${DateHelper.formatMonthYear(controller.selectedMonth.value)} saved successfully.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  void _showAllocateRemainingBottomSheet() {
    if (_editableCategories.isEmpty) {
      Get.snackbar(
        'No Categories',
        'Please add at least one category before allocating remaining amount.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    final decimalPaise = _remainingDecimalPaise;
    final decimalRupeesStr = '₹${(decimalPaise / 100.0).toStringAsFixed(2)}';
    String? selectedCategoryId = _editableCategories.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            final selectedCategory = _editableCategories.firstWhere(
              (c) => c.id == selectedCategoryId,
              orElse: () => _editableCategories.first,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      const Text(
                        'Allocate Remaining Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          decimalRupeesStr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the account where you want to deposit this fractional remaining balance:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selection List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _editableCategories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final cat = _editableCategories[idx];
                        final isSelected = cat.id == selectedCategoryId;
                        final icon = _getCategoryIcon(cat.name);
                        final color = _getCategoryColor(cat.name, idx);

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedCategoryId = cat.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF5F3FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: const Color(0xFF1E232A),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Selected target preview box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Target: ${selectedCategory.name}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+$decimalRupeesStr',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        // 1. Update the local editable category immediately
                        setState(() {
                          final idx = _editableCategories.indexWhere(
                            (c) => c.id == selectedCategory.id,
                          );
                          if (idx != -1) {
                            _editableCategories[idx] = _editableCategories[idx]
                                .copyWith(
                                  allocatedRemainderPaise:
                                      _editableCategories[idx]
                                          .allocatedRemainderPaise +
                                      decimalPaise,
                                );
                          }
                        });

                        // 2. Persist in controller, database, snapshot, and ledger
                        await controller.allocateRemainingDecimalAmount(
                          amountPaise: decimalPaise,
                          destinationAccountId: selectedCategory.accountId,
                          destinationAccountName: selectedCategory.name,
                          categoryId: selectedCategory.id,
                        );

                        Get.snackbar(
                          'Decimal Allocation Confirmed',
                          '$decimalRupeesStr was added directly into ${selectedCategory.name}.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: const Color(0xFF22C55E),
                          colorText: Colors.white,
                        );
                      },
                      child: Text(
                        'Confirm Allocation of $decimalRupeesStr',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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

  void _showAddCategoryDialog() {
    final textCtrl = TextEditingController();
    final percentCtrl = TextEditingController(text: '10');
    final fixedAmountCtrl = TextEditingController();
    AllocationType selectedType = AllocationType.percentage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Add Allocation Category',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Allocation Type Toggle (Segmented Switch)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedType = AllocationType.percentage;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == AllocationType.percentage
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow:
                                  selectedType == AllocationType.percentage
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Percentage (%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    selectedType == AllocationType.percentage
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedType == AllocationType.percentage
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedType = AllocationType.fixed;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == AllocationType.fixed
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selectedType == AllocationType.fixed
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Fixed Amount (₹)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedType == AllocationType.fixed
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedType == AllocationType.fixed
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Food, Travel, Rent, Savings',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedType == AllocationType.percentage)
                  TextField(
                    key: const ValueKey('add_percent_input'),
                    controller: percentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Percentage (%)',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  TextField(
                    key: const ValueKey('add_fixed_input'),
                    controller: fixedAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Fixed Amount',
                      prefixText: '₹ ',
                      hintText: 'e.g. 5000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final name = textCtrl.text.trim();
                  if (name.isNotEmpty) {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final newId = 'cat_$timestamp';
                    final newAccId = 'acc_$timestamp';

                    double percent = 0.0;
                    int fixedPaise = 0;

                    if (selectedType == AllocationType.percentage) {
                      percent =
                          (double.tryParse(percentCtrl.text.trim()) ?? 0.0)
                              .clamp(0.0, 100.0);
                    } else {
                      final fixedRupees =
                          double.tryParse(fixedAmountCtrl.text.trim()) ?? 0.0;
                      fixedPaise = (fixedRupees * 100).round();
                    }

                    final newCat = BudgetCategoryModel(
                      id: newId,
                      name: name,
                      percentage: percent,
                      accountId: newAccId,
                      allocationType: selectedType,
                      fixedAmountPaise: fixedPaise,
                    );

                    setState(() {
                      _editableCategories.add(newCat);
                    });

                    // Persist category and automatically create/synchronize account in storage
                    controller.addBudgetCategory(category: newCat);

                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(int index) {
    final textCtrl = TextEditingController(
      text: _editableCategories[index].name,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Rename Category',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: textCtrl,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _editableCategories[index] = _editableCategories[index]
                      .copyWith(name: textCtrl.text.trim());
                });
                controller.updateBudgetCategories(_editableCategories);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPercentageDialog(int index) {
    final cat = _editableCategories[index];
    AllocationType selectedType = cat.allocationType;
    final percentCtrl = TextEditingController(
      text: cat.percentage == cat.percentage.roundToDouble()
          ? cat.percentage.toInt().toString()
          : cat.percentage.toString(),
    );
    final fixedCtrl = TextEditingController(
      text: cat.isFixed
          ? (cat.fixedAmountPaise / 100.0 == (cat.fixedAmountPaise ~/ 100)
                ? (cat.fixedAmountPaise ~/ 100).toString()
                : (cat.fixedAmountPaise / 100.0).toStringAsFixed(2))
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Allocation for ${cat.name}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Allocation Type Toggle (Segmented Switch)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedType = AllocationType.percentage;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == AllocationType.percentage
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow:
                                  selectedType == AllocationType.percentage
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Percentage (%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    selectedType == AllocationType.percentage
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedType == AllocationType.percentage
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedType = AllocationType.fixed;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == AllocationType.fixed
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selectedType == AllocationType.fixed
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Fixed Amount (₹)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedType == AllocationType.fixed
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedType == AllocationType.fixed
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (selectedType == AllocationType.percentage) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [5.0, 10.0, 15.0, 20.0, 25.0, 30.0].map((
                      quickVal,
                    ) {
                      return ActionChip(
                        label: Text('${quickVal.toInt()}%'),
                        onPressed: () {
                          percentCtrl.text = quickVal.toInt().toString();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('edit_percent_field'),
                    controller: percentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Percentage (%)',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    key: const ValueKey('edit_fixed_field'),
                    controller: fixedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Fixed Amount',
                      prefixText: '₹ ',
                      hintText: 'e.g. 5000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (selectedType == AllocationType.percentage) {
                    final parsed = double.tryParse(percentCtrl.text.trim());
                    if (parsed != null && parsed >= 0 && parsed <= 100) {
                      setState(() {
                        _editableCategories[index] = _editableCategories[index]
                            .copyWith(
                              percentage: double.parse(
                                parsed.toStringAsFixed(2),
                              ),
                              allocationType: AllocationType.percentage,
                              fixedAmountPaise: 0,
                            );
                      });
                      controller.updateBudgetCategories(_editableCategories);
                      Navigator.pop(ctx);
                    }
                  } else {
                    final parsedFixed = double.tryParse(fixedCtrl.text.trim());
                    if (parsedFixed != null && parsedFixed >= 0) {
                      final fixedPaise = (parsedFixed * 100).round();
                      setState(() {
                        _editableCategories[index] = _editableCategories[index]
                            .copyWith(
                              percentage: 0.0,
                              allocationType: AllocationType.fixed,
                              fixedAmountPaise: fixedPaise,
                            );
                      });
                      controller.updateBudgetCategories(_editableCategories);
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'How Salary Allocation Works',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          '1. Enter your monthly take-home salary.\n'
          '2. Adjust each envelope category percentage until the total equals 100%.\n'
          '3. Tapping Save locks this month\'s allocation snapshot without affecting prior months.\n'
          '4. Each envelope tracks its starting allocation, added money, total spent and remaining balance.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('food') || lower.contains('grocer')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('travel') ||
        lower.contains('car') ||
        lower.contains('fuel')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('emergency')) {
      return Icons.shield_rounded;
    }
    if (lower.contains('invest')) {
      return Icons.bar_chart_rounded;
    }
    if (lower.contains('daily') || lower.contains('saving')) {
      return Icons.savings_rounded;
    }
    if (lower.contains('entertainment') || lower.contains('fun')) {
      return Icons.movie_filter_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  Color _getCategoryColor(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('food')) return const Color(0xFFF59E0B); // Orange / Gold
    if (lower.contains('travel')) return const Color(0xFF3B82F6); // Blue
    if (lower.contains('emergency')) return const Color(0xFF22C55E); // Green
    if (lower.contains('invest')) return const Color(0xFF8B5CF6); // Purple
    if (lower.contains('daily') || lower.contains('saving')) {
      return const Color(0xFF14B8A6); // Teal
    }
    if (lower.contains('entertainment')) return const Color(0xFFEC4899); // Pink
    return const Color(0xFF64748B); // Slate
  }
}
