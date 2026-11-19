import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/investment_model.dart';
import '../../data/models/recurring_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/financial_repository.dart';
import 'allocation_calculator.dart';
import 'currency_helper.dart';

class FinancialController extends GetxController {
  final FinancialRepository repository = FinancialRepository();
  final Uuid _uuid = const Uuid();

  // State Observables
  final Rx<DateTime> selectedMonth = Rx<DateTime>(DateTime.now());
  final RxBool isLoading = false.obs;

  // Data lists
  final RxList<AccountLedgerSummary> accountSummaries =
      <AccountLedgerSummary>[].obs;
  final RxList<BudgetCategoryModel> budgetCategories =
      <BudgetCategoryModel>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<SavingsGoalModel> savingsGoals = <SavingsGoalModel>[].obs;
  final RxList<InvestmentModel> investments = <InvestmentModel>[].obs;
  final RxList<RecurringTransactionModel> recurringTransactions =
      <RecurringTransactionModel>[].obs;

  // Monthly Snapshot
  final Rx<MonthlyBudgetSnapshot?> currentSnapshot = Rx<MonthlyBudgetSnapshot?>(
    null,
  );

  // Overall Financial Metrics
  final RxInt totalSalaryIncome = 0.obs;
  final RxInt totalAdditionalIncome = 0.obs;
  final RxInt totalIncome = 0.obs;
  final RxInt totalAllocated = 0.obs;
  final RxInt totalAdded = 0.obs;
  final RxInt totalSpent = 0.obs;
  final RxInt totalTransferred = 0.obs;
  final RxInt totalSavingsContributions = 0.obs;
  final RxInt totalInvestmentsContributions = 0.obs;
  final RxInt totalAvailableCash = 0.obs;
  final RxInt totalSavingsAccumulated = 0.obs;
  final RxInt totalInvestmentValuation = 0.obs;
  final RxInt totalInvestmentCost = 0.obs;
  final RxInt netWorth = 0.obs;

  String get currentMonthKey => DateHelper.getMonthKey(selectedMonth.value);

  @override
  void onInit() {
    super.onInit();
    refreshAllData();
  }

  void changeSelectedMonth(DateTime month) {
    selectedMonth.value = month;
    refreshAllData();
  }

  Future<void> refreshAllData() async {
    isLoading.value = true;
    try {
      final mKey = currentMonthKey;

      // 1. Load categories & accounts
      final cats = await repository.getBudgetCategories();
      budgetCategories.assignAll(cats);

      // 2. Load metrics & ledger summaries
      final metrics = await repository.getFinancialDashboardMetrics(mKey);
      totalSalaryIncome.value = metrics['totalSalaryIncome'];
      totalAdditionalIncome.value = metrics['totalAdditionalIncome'];
      totalIncome.value = metrics['totalIncome'];
      totalAllocated.value = metrics['totalAllocated'];
      totalAdded.value = metrics['totalAdded'];
      totalSpent.value = metrics['totalSpent'];
      totalTransferred.value = metrics['totalTransferred'];
      totalSavingsContributions.value = metrics['totalSavingsContributions'];
      totalInvestmentsContributions.value =
          metrics['totalInvestmentsContributions'];
      totalAvailableCash.value = metrics['totalAvailableCash'];
      totalSavingsAccumulated.value = metrics['totalSavingsAccumulated'];
      totalInvestmentValuation.value = metrics['totalInvestmentValuation'];
      totalInvestmentCost.value = metrics['totalInvestmentCost'];
      netWorth.value = metrics['netWorth'];

      accountSummaries.assignAll(
        metrics['accountSummaries'] as List<AccountLedgerSummary>,
      );
      currentSnapshot.value = metrics['snapshot'] as MonthlyBudgetSnapshot?;

      // 3. Load all transactions
      final txs = await repository.getAllTransactions();
      transactions.assignAll(txs);

      // 4. Load savings, investments, recurring
      final sGoals = await repository.getSavingsGoals();
      savingsGoals.assignAll(sGoals);

      final invs = await repository.getInvestments();
      investments.assignAll(invs);

      final recurs = await repository.getRecurringTransactions();
      recurringTransactions.assignAll(recurs);

      // 5. Automatically sync Emergency and Investment allocations from current snapshot
      await _syncAllocationsWithSavingsAndInvestments();
    } catch (e) {
      debugPrint('Error refreshing financial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Automatically synchronizes Emergency and Investment categories from the Salary Allocation
  /// snapshot with the Savings Goals and Investment portfolio tracker.
  Future<void> _syncAllocationsWithSavingsAndInvestments() async {
    final snapshot = currentSnapshot.value;
    if (snapshot == null) return;

    try {
      final Map<String, dynamic> rawAllocations =
          jsonDecode(snapshot.allocationsJson) as Map<String, dynamic>;

      for (var entry in rawAllocations.entries) {
        final catId = entry.key;
        final data = Map<String, dynamic>.from(entry.value as Map);
        final String name = (data['name'] as String?)?.trim() ?? '';
        final int allocatedPaise = (data['amountPaise'] as num?)?.toInt() ?? 0;
        final String? accId = data['accountId'] as String?;
        final lower = name.toLowerCase();

        // 1. Sync Emergency Fund
        if (lower.contains('emergenc')) {
          final existingEmergency = savingsGoals.firstWhereOrNull(
            (g) => g.isEmergencyFund,
          );
          if (existingEmergency != null) {
            // If current saved is 0 or less than the allocated amount, update it to reflect allocation
            if (existingEmergency.currentSavedPaise != allocatedPaise &&
                allocatedPaise > 0) {
              final updated = existingEmergency.copyWith(
                name: name,
                currentSavedPaise: allocatedPaise,
                targetAmountPaise:
                    existingEmergency.targetAmountPaise > allocatedPaise
                    ? existingEmergency.targetAmountPaise
                    : (allocatedPaise * 3), // default healthy 3-month target
                accountId: accId ?? existingEmergency.accountId,
              );
              await repository.updateSavingsGoal(updated);
              final idx = savingsGoals.indexWhere(
                (g) => g.id == existingEmergency.id,
              );
              if (idx != -1) savingsGoals[idx] = updated;
            }
          } else if (allocatedPaise > 0) {
            final newEmergency = SavingsGoalModel(
              id: _uuid.v4(),
              name: name.isNotEmpty ? name : 'Emergency Fund',
              targetAmountPaise: allocatedPaise * 3,
              currentSavedPaise: allocatedPaise,
              isEmergencyFund: true,
              accountId: accId,
            );
            await repository.createSavingsGoal(newEmergency);
            savingsGoals.add(newEmergency);
          }
        }

        // 2. Sync Investment category
        if (lower.contains('invest')) {
          final existingInv = investments.firstWhereOrNull(
            (i) => i.id == catId || i.name.toLowerCase() == lower,
          );
          if (existingInv != null) {
            if (existingInv.totalInvestedPaise != allocatedPaise &&
                allocatedPaise > 0) {
              final updated = existingInv.copyWith(
                totalInvestedPaise: allocatedPaise,
                currentValuePaise:
                    existingInv.currentValuePaise == 0 ||
                        existingInv.currentValuePaise ==
                            existingInv.totalInvestedPaise
                    ? allocatedPaise
                    : existingInv.currentValuePaise,
                accountId: accId ?? existingInv.accountId,
              );
              await repository.updateInvestment(updated);
              final idx = investments.indexWhere((i) => i.id == existingInv.id);
              if (idx != -1) investments[idx] = updated;
            }
          } else if (allocatedPaise > 0) {
            final newInv = InvestmentModel(
              id: catId,
              name: name.isNotEmpty ? name : 'Salary Investment Fund',
              type: InvestmentType.sip,
              totalInvestedPaise: allocatedPaise,
              currentValuePaise: allocatedPaise,
              startDate: DateTime.now(),
              accountId: accId,
              notes: 'Allocated from monthly salary',
            );
            await repository.createInvestment(newInv);
            investments.add(newInv);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing allocations with savings & investments: $e');
    }
  }

  // -------------------------------------------------------------
  // Salary Allocation Operations
  // -------------------------------------------------------------
  Future<void> saveMonthlySalaryAllocation({
    required int salaryPaise,
    required List<BudgetCategoryModel> categories,
  }) async {
    final mKey = currentMonthKey;

    // Use AllocationCalculator to ensure whole-rupee allocation with separate decimal tracking
    final calcResult = AllocationCalculator.calculateAllocations(
      totalSalaryPaise: salaryPaise,
      categories: categories,
    );

    // Map allocations: CategoryId -> Allocated Paise (whole-rupee portions)
    final Map<String, dynamic> allocationsMap = {};
    for (var cat in categories) {
      final catAmountPaise = calcResult.categoryAmountsPaise[cat.id] ?? 0;
      final detail = calcResult.categoryDetails[cat.id];
      allocationsMap[cat.id] = {
        'name': cat.name,
        'percentage': cat.percentage,
        'accountId': cat.accountId,
        'amountPaise': catAmountPaise,
        'exactRupees': detail?.exactRupees,
        'wholeRupees': detail?.wholeRupees,
        'decimalPaise': detail?.decimalPaise,
      };
    }

    // Save persistent snapshot for this month
    await repository.saveMonthlyBudgetSnapshot(
      monthKey: mKey,
      salaryPaise: salaryPaise,
      allocationsMap: allocationsMap,
    );

    // Save categories if altered
    await repository.saveBudgetCategories(categories);

    // Synchronize corresponding accounts for all categories
    for (var cat in categories) {
      final existingAccount = await repository.getAccountById(cat.accountId);
      if (existingAccount == null) {
        // Also check by name to avoid duplicate creation if accountId was legacy
        final allAccounts = await repository.getAccounts();
        final matchByName = allAccounts.firstWhereOrNull(
          (a) => a.name.toLowerCase() == cat.name.trim().toLowerCase(),
        );
        if (matchByName != null) {
          if (matchByName.id != cat.accountId) {
            // Keep category linked to this account
            final updatedCat = cat.copyWith(accountId: matchByName.id);
            final idx = categories.indexOf(cat);
            if (idx != -1) categories[idx] = updatedCat;
            await repository.saveBudgetCategories(categories);
          }
        } else {
          final newAcc = AccountModel(
            id: cat.accountId,
            name: cat.name,
            iconKey: 'restaurant',
            colorValue: 0xFF3B82F6,
            openingBalancePaise: 0,
            sortOrder: accountSummaries.length + 1,
          );
          await repository.createAccount(newAcc);
        }
      } else if (existingAccount.name != cat.name) {
        await repository.updateAccount(
          existingAccount.copyWith(name: cat.name),
        );
      }
    }

    // Record or update the monthly Salary Transaction
    // Ensure we don't duplicate: search existing salary tx for this month
    final existingSalaryTx = transactions.firstWhereOrNull(
      (t) =>
          t.type == TransactionType.salary &&
          DateHelper.getMonthKey(t.transactionDate) == mKey,
    );

    if (existingSalaryTx != null) {
      await repository.updateTransaction(
        existingSalaryTx.copyWith(
          amountPaise: salaryPaise,
          title:
              'Monthly Salary (${DateHelper.formatMonthYear(selectedMonth.value)})',
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      final newSalaryTx = TransactionModel(
        id: _uuid.v4(),
        type: TransactionType.salary,
        amountPaise: salaryPaise,
        destinationAccountId: categories.isNotEmpty
            ? categories.first.accountId
            : null,
        title:
            'Monthly Salary (${DateHelper.formatMonthYear(selectedMonth.value)})',
        description: 'Auto allocated to budget categories',
        transactionDate: DateTime(
          selectedMonth.value.year,
          selectedMonth.value.month,
          1,
        ),
      );
      await repository.addTransaction(newSalaryTx);
    }

    await refreshAllData();
  }

  /// Allocate the remaining decimal amount to a user-selected account and category
  Future<void> allocateRemainingDecimalAmount({
    required int amountPaise,
    required String destinationAccountId,
    required String destinationAccountName,
    String? categoryId,
  }) async {
    final mKey = currentMonthKey;

    // 1. If categoryId provided, update the budget category's allocatedRemainderPaise
    if (categoryId != null) {
      final updatedCategories = budgetCategories.map((c) {
        if (c.id == categoryId) {
          return c.copyWith(
            allocatedRemainderPaise: c.allocatedRemainderPaise + amountPaise,
          );
        }
        return c;
      }).toList();
      await repository.saveBudgetCategories(updatedCategories);
      budgetCategories.assignAll(updatedCategories);

      // Also update snapshot if exists
      final snapshot = currentSnapshot.value;
      if (snapshot != null) {
        try {
          final Map<String, dynamic> rawAllocations =
              jsonDecode(snapshot.allocationsJson) as Map<String, dynamic>;
          if (rawAllocations.containsKey(categoryId)) {
            final catData = Map<String, dynamic>.from(
              rawAllocations[categoryId] as Map,
            );
            final currentAmount =
                (catData['amountPaise'] as num?)?.toInt() ?? 0;
            catData['amountPaise'] = currentAmount + amountPaise;
            rawAllocations[categoryId] = catData;
            await repository.saveMonthlyBudgetSnapshot(
              monthKey: mKey,
              salaryPaise: snapshot.salaryPaise,
              allocationsMap: rawAllocations,
            );
          }
        } catch (e) {
          debugPrint('Error updating snapshot for decimal allocation: $e');
        }
      }
    }

    // 2. Add an internal ledger transaction
    final tx = TransactionModel(
      id: _uuid.v4(),
      type: TransactionType.addMoney,
      amountPaise: amountPaise,
      destinationAccountId: destinationAccountId,
      title: 'Remaining Decimal Allocation',
      description:
          'Decimal balance allocated to $destinationAccountName ($mKey)',
      paymentMethod: 'Internal Allocation',
      transactionDate: DateTime.now(),
    );

    await repository.addTransaction(tx);
    await refreshAllData();
  }

  /// Reverses and clears all remaining decimal allocations for the current month.
  /// Reverses internal ledger transactions without affecting unrelated transactions or manual funds.
  Future<void> clearRemainingDecimalAllocations() async {
    final mKey = currentMonthKey;

    // 1. Reset allocatedRemainderPaise on all categories and persist
    final updatedCategories = budgetCategories.map((c) {
      return c.copyWith(allocatedRemainderPaise: 0);
    }).toList();
    await repository.saveBudgetCategories(updatedCategories);
    budgetCategories.assignAll(updatedCategories);

    // 2. Delete any "Remaining Decimal Allocation" transactions recorded for this month
    final allTxs = await repository.getAllTransactions();
    final decimalTxsToDelete = allTxs.where((t) {
      final isDecimalTx =
          t.title == 'Remaining Decimal Allocation' ||
          (t.description != null &&
              t.description!.contains('Decimal balance allocated'));
      final isThisMonth = DateHelper.getMonthKey(t.transactionDate) == mKey;
      return isDecimalTx && isThisMonth;
    }).toList();

    for (var tx in decimalTxsToDelete) {
      await repository.deleteTransaction(tx.id);
    }

    // 3. Update snapshot if present to remove remainder from categories
    final snapshot = currentSnapshot.value;
    if (snapshot != null) {
      try {
        final Map<String, dynamic> rawAllocations =
            jsonDecode(snapshot.allocationsJson) as Map<String, dynamic>;
        bool altered = false;
        for (var entry in rawAllocations.entries) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          if (data.containsKey('amountPaise')) {
            // Restore wholeRupees portion only if decimal was previously added
            final wholeRupees = (data['wholeRupees'] as num?)?.toInt();
            if (wholeRupees != null) {
              data['amountPaise'] = wholeRupees * 100;
              rawAllocations[entry.key] = data;
              altered = true;
            }
          }
        }
        if (altered) {
          await repository.saveMonthlyBudgetSnapshot(
            monthKey: mKey,
            salaryPaise: snapshot.salaryPaise,
            allocationsMap: rawAllocations,
          );
        }
      } catch (e) {
        debugPrint('Error updating snapshot during decimal clearing: $e');
      }
    }

    await refreshAllData();
  }

  // -------------------------------------------------------------
  // Transaction Operations
  // -------------------------------------------------------------
  Future<void> addTransaction({
    required TransactionType type,
    required int amountPaise,
    String? sourceAccountId,
    String? destinationAccountId,
    String? categoryId,
    required String title,
    String? description,
    String? paymentMethod,
    DateTime? transactionDate,
    String? attachmentPath,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      type: type,
      amountPaise: amountPaise,
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      categoryId: categoryId,
      title: title,
      description: description,
      paymentMethod: paymentMethod ?? 'UPI',
      transactionDate: transactionDate ?? DateTime.now(),
      attachmentPath: attachmentPath,
    );

    await repository.addTransaction(tx);
    await refreshAllData();
  }

  Future<void> updateTransaction(TransactionModel updatedTx) async {
    await repository.updateTransaction(
      updatedTx.copyWith(updatedAt: DateTime.now()),
    );
    await refreshAllData();
  }

  Future<void> deleteTransaction(String id) async {
    await repository.deleteTransaction(id);
    await refreshAllData();
  }

  // -------------------------------------------------------------
  // Savings Goal Operations
  // -------------------------------------------------------------
  Future<void> addSavingsDeposit({
    required String goalId,
    required int amountPaise,
    required String fromAccountId,
  }) async {
    final goal = savingsGoals.firstWhereOrNull((g) => g.id == goalId);
    if (goal == null) return;

    // 1. Create transaction of type savingsContribution
    final tx = TransactionModel(
      id: _uuid.v4(),
      type: TransactionType.savingsContribution,
      amountPaise: amountPaise,
      sourceAccountId: fromAccountId,
      destinationAccountId: goal.accountId,
      title: 'Deposit to ${goal.name}',
      description: 'Savings goal deposit',
      transactionDate: DateTime.now(),
    );
    await repository.addTransaction(tx);

    // 2. Update goal saved amount
    final updatedGoal = goal.copyWith(
      currentSavedPaise: goal.currentSavedPaise + amountPaise,
    );
    await repository.updateSavingsGoal(updatedGoal);

    await refreshAllData();
  }

  /// Withdraw funds from a savings goal (e.g. Emergency Fund) and credit to destination account
  Future<void> withdrawSavingsGoal({
    required String goalId,
    required int amountPaise,
    required String toAccountId,
    String? reason,
  }) async {
    final goal = savingsGoals.firstWhereOrNull((g) => g.id == goalId);
    if (goal == null) return;

    // 1. Create transaction of type savingsWithdrawal
    final tx = TransactionModel(
      id: _uuid.v4(),
      type: TransactionType.savingsWithdrawal,
      amountPaise: amountPaise,
      sourceAccountId: goal.accountId,
      destinationAccountId: toAccountId,
      title: 'Withdrawal from ${goal.name}',
      description: reason ?? 'Savings goal withdrawal',
      transactionDate: DateTime.now(),
    );
    await repository.addTransaction(tx);

    // 2. Deduct from goal saved amount
    final newSavedPaise = (goal.currentSavedPaise - amountPaise)
        .clamp(0, double.infinity)
        .toInt();
    final updatedGoal = goal.copyWith(currentSavedPaise: newSavedPaise);
    await repository.updateSavingsGoal(updatedGoal);

    await refreshAllData();
  }

  Future<void> addSavingsGoal({
    required String name,
    required int targetAmountPaise,
    DateTime? targetDate,
    bool isEmergencyFund = false,
    String iconKey = 'savings',
    int colorValue = 0xFF10B981,
  }) async {
    final goal = SavingsGoalModel(
      id: _uuid.v4(),
      name: name,
      targetAmountPaise: targetAmountPaise,
      currentSavedPaise: 0,
      targetDate: targetDate,
      isEmergencyFund: isEmergencyFund,
      iconKey: iconKey,
      colorValue: colorValue,
    );
    await repository.createSavingsGoal(goal);
    await refreshAllData();
  }

  Future<void> deleteSavingsGoal(String id) async {
    await repository.deleteSavingsGoal(id);
    await refreshAllData();
  }

  // -------------------------------------------------------------
  // Investment Operations
  // -------------------------------------------------------------
  Future<void> addInvestment({
    required String name,
    required InvestmentType type,
    required int initialAmountPaise,
    required String fromAccountId,
    String? notes,
  }) async {
    final inv = InvestmentModel(
      id: _uuid.v4(),
      name: name,
      type: type,
      totalInvestedPaise: initialAmountPaise,
      currentValuePaise: initialAmountPaise,
      startDate: DateTime.now(),
      notes: notes,
      accountId: fromAccountId,
    );

    await repository.createInvestment(inv);

    // Record Transaction
    final tx = TransactionModel(
      id: _uuid.v4(),
      type: TransactionType.investmentContribution,
      amountPaise: initialAmountPaise,
      sourceAccountId: fromAccountId,
      title: 'Investment: $name',
      description: type.displayName,
      transactionDate: DateTime.now(),
    );
    await repository.addTransaction(tx);

    await refreshAllData();
  }

  Future<void> updateInvestmentValuation(
    String investmentId,
    int newCurrentValuePaise,
  ) async {
    final inv = investments.firstWhereOrNull((i) => i.id == investmentId);
    if (inv == null) return;

    final updated = inv.copyWith(currentValuePaise: newCurrentValuePaise);
    await repository.updateInvestment(updated);
    await refreshAllData();
  }

  /// Add further capital / top-up into an existing investment
  Future<void> depositToInvestment({
    required String investmentId,
    required int amountPaise,
    required String fromAccountId,
    String? notes,
  }) async {
    final inv = investments.firstWhereOrNull((i) => i.id == investmentId);
    if (inv == null) return;

    final updated = inv.copyWith(
      totalInvestedPaise: inv.totalInvestedPaise + amountPaise,
      currentValuePaise: inv.currentValuePaise + amountPaise,
    );
    await repository.updateInvestment(updated);

    final tx = TransactionModel(
      id: _uuid.v4(),
      type: TransactionType.investmentContribution,
      amountPaise: amountPaise,
      sourceAccountId: fromAccountId,
      title: 'Investment Deposit: ${inv.name}',
      description: notes ?? inv.type.displayName,
      transactionDate: DateTime.now(),
    );
    await repository.addTransaction(tx);

    await refreshAllData();
  }

  /// Withdraw from an investment (redeem shares / units) and credit back to an account
  Future<void> withdrawFromInvestment({
    required String investmentId,
    required int amountPaise,
    required String toAccountId,
    String? notes,
  }) async {
    final inv = investments.firstWhereOrNull((i) => i.id == investmentId);
    if (inv == null) return;

    final newInvested = (inv.totalInvestedPaise - amountPaise)
        .clamp(0, double.infinity)
        .toInt();
    final newCurrent = (inv.currentValuePaise - amountPaise)
        .clamp(0, double.infinity)
        .toInt();
    final updated = inv.copyWith(
      totalInvestedPaise: newInvested,
      currentValuePaise: newCurrent,
    );
    await repository.updateInvestment(updated);

    final tx = TransactionModel(
      id: _uuid.v4(),
      type: TransactionType.refund, // or income/refund to account
      amountPaise: amountPaise,
      destinationAccountId: toAccountId,
      title: 'Investment Withdrawal: ${inv.name}',
      description: notes ?? 'Redeemed units from ${inv.type.displayName}',
      transactionDate: DateTime.now(),
    );
    await repository.addTransaction(tx);

    await refreshAllData();
  }

  Future<void> deleteInvestment(String id) async {
    await repository.deleteInvestment(id);
    await refreshAllData();
  }

  // -------------------------------------------------------------
  // Recurring Transactions
  // -------------------------------------------------------------
  Future<void> addRecurringTransaction({
    required String title,
    required int amountPaise,
    required String typeName,
    required String accountId,
    required RecurrenceFrequency frequency,
    required DateTime nextDueDate,
    String? notes,
  }) async {
    final rec = RecurringTransactionModel(
      id: _uuid.v4(),
      title: title,
      amountPaise: amountPaise,
      typeName: typeName,
      accountId: accountId,
      frequency: frequency,
      nextDueDate: nextDueDate,
      notes: notes,
    );
    await repository.createRecurringTransaction(rec);
    await refreshAllData();
  }

  Future<void> executeRecurringTransaction(
    RecurringTransactionModel rec,
  ) async {
    TransactionType txType;
    if (rec.typeName == 'income') {
      txType = TransactionType.additionalIncome;
    } else if (rec.typeName == 'savings') {
      txType = TransactionType.savingsContribution;
    } else if (rec.typeName == 'investment') {
      txType = TransactionType.investmentContribution;
    } else {
      txType = TransactionType.expense;
    }

    final tx = TransactionModel(
      id: _uuid.v4(),
      type: txType,
      amountPaise: rec.amountPaise,
      sourceAccountId: txType == TransactionType.expense ? rec.accountId : null,
      destinationAccountId: txType != TransactionType.expense
          ? rec.accountId
          : null,
      title: rec.title,
      description: 'Auto recurring payment (${rec.frequency.name})',
      transactionDate: DateTime.now(),
    );

    await repository.addTransaction(tx);
    await refreshAllData();
  }

  Future<void> deleteRecurring(String id) async {
    await repository.deleteRecurringTransaction(id);
    await refreshAllData();
  }

  // -------------------------------------------------------------
  // Virtual Accounts & Custom Categories
  // -------------------------------------------------------------
  Future<void> addBudgetCategory({
    required BudgetCategoryModel category,
  }) async {
    // 1. Ensure corresponding account is created and synchronized with stable accountId
    final existingAccount = await repository.getAccountById(category.accountId);
    if (existingAccount == null) {
      final allAccounts = await repository.getAccounts();
      final matchByName = allAccounts.firstWhereOrNull(
        (a) => a.name.toLowerCase() == category.name.trim().toLowerCase(),
      );
      if (matchByName != null) {
        // Link with existing account
        category = category.copyWith(accountId: matchByName.id);
      } else {
        // Create corresponding account permanently
        final newAcc = AccountModel(
          id: category.accountId,
          name: category.name,
          iconKey: 'restaurant',
          colorValue: 0xFF3B82F6,
          openingBalancePaise: 0,
          sortOrder: allAccounts.length + 1,
        );
        await repository.createAccount(newAcc);
      }
    } else if (existingAccount.name != category.name) {
      await repository.updateAccount(
        existingAccount.copyWith(name: category.name),
      );
    }

    final updatedList = List<BudgetCategoryModel>.from(budgetCategories)
      ..add(category);
    await repository.saveBudgetCategories(updatedList);
    budgetCategories.assignAll(updatedList);
    await refreshAllData();
  }

  Future<void> updateBudgetCategories(
    List<BudgetCategoryModel> categories,
  ) async {
    // Synchronize account names with updated category names
    for (var cat in categories) {
      final existingAccount = await repository.getAccountById(cat.accountId);
      if (existingAccount != null && existingAccount.name != cat.name) {
        await repository.updateAccount(
          existingAccount.copyWith(name: cat.name),
        );
      }
    }
    await repository.saveBudgetCategories(categories);
    budgetCategories.assignAll(categories);
    await refreshAllData();
  }

  Future<void> deleteBudgetCategory(String categoryId) async {
    final catToDelete = budgetCategories.firstWhereOrNull(
      (c) => c.id == categoryId,
    );
    final updatedList = budgetCategories
        .where((c) => c.id != categoryId)
        .toList();
    await repository.saveBudgetCategories(updatedList);
    budgetCategories.assignAll(updatedList);

    // If there is an associated account, check if it has transactions
    if (catToDelete != null) {
      final accId = catToDelete.accountId;
      final accTxs = await repository.getTransactions(accountId: accId);
      if (accTxs.isEmpty) {
        // Safe to remove the account since no transactions were ever recorded for it
        await repository.deleteAccount(accId);
      } else {
        // Account has transactions: do NOT delete account to preserve transaction history
        debugPrint(
          'Preserving account $accId as it has ${accTxs.length} historical transactions.',
        );
      }
    }

    await refreshAllData();
  }

  Future<void> addCustomAccount({
    required String name,
    required String iconKey,
    required int colorValue,
    int openingBalancePaise = 0,
    String? customId,
  }) async {
    final newId = customId ?? 'acc_${_uuid.v4().substring(0, 8)}';
    final acc = AccountModel(
      id: newId,
      name: name,
      iconKey: iconKey,
      colorValue: colorValue,
      openingBalancePaise: openingBalancePaise,
      sortOrder: accountSummaries.length + 1,
    );
    await repository.createAccount(acc);
    await refreshAllData();
  }

  Future<void> deleteAccount(String id) async {
    await repository.deleteAccount(id);
    await refreshAllData();
  }

  Future<void> resetAllFinancialData() async {
    await repository.resetAllData();
    await refreshAllData();
  }
}
