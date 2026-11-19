import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/hive_database_helper.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/investment_model.dart';
import '../models/recurring_model.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';
import '../../core/utils/currency_helper.dart';

class FinancialRepository {
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // -------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------
  Future<List<AccountModel>> getAccounts() async {
    await _dbHelper.init();
    final list = _dbHelper.accountsBox.values.map((v) {
      return AccountModel.fromMap(Map<String, dynamic>.from(v));
    }).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<AccountModel?> getAccountById(String id) async {
    await _dbHelper.init();
    final data = _dbHelper.accountsBox.get(id);
    if (data != null) {
      return AccountModel.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> createAccount(AccountModel account) async {
    await _dbHelper.init();
    await _dbHelper.accountsBox.put(account.id, account.toMap());
  }

  Future<void> updateAccount(AccountModel account) async {
    await _dbHelper.init();
    await _dbHelper.accountsBox.put(account.id, account.toMap());
  }

  Future<void> deleteAccount(String id) async {
    await _dbHelper.init();
    await _dbHelper.accountsBox.delete(id);

    // Keep transaction history completely intact (transactions preserve historical records).
    // Also remove matching budget category if any exists
    final catKeysToDelete = <dynamic>[];
    for (var entry in _dbHelper.budgetCategoriesBox.toMap().entries) {
      if (entry.value['accountId'] == id) {
        catKeysToDelete.add(entry.key);
      }
    }
    for (var k in catKeysToDelete) {
      await _dbHelper.budgetCategoriesBox.delete(k);
    }
  }

  // -------------------------------------------------------------
  // Budget Categories & Allocation Snapshots
  // -------------------------------------------------------------
  Future<List<BudgetCategoryModel>> getBudgetCategories() async {
    await _dbHelper.init();
    final list = _dbHelper.budgetCategoriesBox.values.map((v) {
      return BudgetCategoryModel.fromMap(Map<String, dynamic>.from(v));
    }).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<void> saveBudgetCategories(List<BudgetCategoryModel> categories) async {
    await _dbHelper.init();
    await _dbHelper.budgetCategoriesBox.clear();
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i].copyWith(sortOrder: i + 1);
      await _dbHelper.budgetCategoriesBox.put(cat.id, cat.toMap());
    }
  }

  Future<MonthlyBudgetSnapshot?> getMonthlySnapshot(String monthKey) async {
    await _dbHelper.init();
    final data = _dbHelper.monthlyBudgetsBox.get(monthKey);
    if (data != null) {
      return MonthlyBudgetSnapshot.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> saveMonthlyBudgetSnapshot({
    required String monthKey,
    required int salaryPaise,
    required Map<String, dynamic> allocationsMap,
  }) async {
    await _dbHelper.init();
    final snapshot = MonthlyBudgetSnapshot(
      id: _uuid.v4(),
      monthKey: monthKey,
      salaryPaise: salaryPaise,
      allocationsJson: jsonEncode(allocationsMap),
    );
    await _dbHelper.monthlyBudgetsBox.put(monthKey, snapshot.toMap());
  }

  // -------------------------------------------------------------
  // Transactions
  // -------------------------------------------------------------
  Future<List<TransactionModel>> getAllTransactions() async {
    return getTransactions();
  }

  Future<List<TransactionModel>> getTransactions({
    String? accountId,
    String? monthKey,
    TransactionType? type,
  }) async {
    await _dbHelper.init();
    var list = _dbHelper.transactionsBox.values.map((v) {
      return TransactionModel.fromMap(Map<String, dynamic>.from(v));
    }).toList();

    if (accountId != null) {
      list = list.where((t) => t.sourceAccountId == accountId || t.destinationAccountId == accountId).toList();
    }
    if (monthKey != null) {
      list = list.where((t) => DateHelper.getMonthKey(t.transactionDate) == monthKey).toList();
    }
    if (type != null) {
      list = list.where((t) => t.type == type).toList();
    }

    list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbHelper.init();
    await _dbHelper.transactionsBox.put(transaction.id, transaction.toMap());

    // Update goal if savings contribution or withdrawal
    if (transaction.type == TransactionType.savingsContribution && transaction.destinationAccountId != null) {
      final goals = await getSavingsGoals();
      final goal = goals.where((g) => g.accountId == transaction.destinationAccountId).firstOrNull;
      if (goal != null) {
        await updateSavingsGoal(goal.copyWith(
          currentSavedPaise: goal.currentSavedPaise + transaction.amountPaise,
        ));
      }
    } else if (transaction.type == TransactionType.savingsWithdrawal && transaction.sourceAccountId != null) {
      final goals = await getSavingsGoals();
      final goal = goals.where((g) => g.accountId == transaction.sourceAccountId).firstOrNull;
      if (goal != null) {
        final newSaved = (goal.currentSavedPaise - transaction.amountPaise);
        await updateSavingsGoal(goal.copyWith(
          currentSavedPaise: newSaved > 0 ? newSaved : 0,
        ));
      }
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _dbHelper.init();
    await _dbHelper.transactionsBox.put(transaction.id, transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _dbHelper.init();
    await _dbHelper.transactionsBox.delete(id);
  }

  // -------------------------------------------------------------
  // Comprehensive Monthly Ledger Calculation Engine
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getFinancialDashboardMetrics(String monthKey) async {
    await _dbHelper.init();

    final accounts = await getAccounts();
    final allTxs = await getTransactions();
    final snapshot = await getMonthlySnapshot(monthKey);
    final goals = await getSavingsGoals();
    final investments = await getInvestments();

    final monthTxs = allTxs.where((t) => DateHelper.getMonthKey(t.transactionDate) == monthKey).toList();

    int totalSalaryIncome = 0;
    int totalAdditionalIncome = 0;
    int totalAllocated = snapshot?.salaryPaise ?? 0;
    int totalAdded = 0;
    int totalSpent = 0;
    int totalTransferred = 0;
    int totalSavingsContributions = 0;
    int totalInvestmentsContributions = 0;

    for (var tx in monthTxs) {
      switch (tx.type) {
        case TransactionType.salary:
          totalSalaryIncome += tx.amountPaise;
          break;
        case TransactionType.additionalIncome:
          totalAdditionalIncome += tx.amountPaise;
          break;
        case TransactionType.expense:
          totalSpent += tx.amountPaise;
          break;
        case TransactionType.addMoney:
          totalAdded += tx.amountPaise;
          break;
        case TransactionType.transfer:
          totalTransferred += tx.amountPaise;
          break;
        case TransactionType.savingsContribution:
          totalSavingsContributions += tx.amountPaise;
          break;
        case TransactionType.investmentContribution:
          totalInvestmentsContributions += tx.amountPaise;
          break;
        case TransactionType.refund:
          totalSpent -= tx.amountPaise;
          break;
        default:
          break;
      }
    }

    final totalIncome = totalSalaryIncome + totalAdditionalIncome;

    final Map<String, int> allocatedMap = {};
    if (snapshot != null) {
      try {
        final Map<String, dynamic> rawAllocations = jsonDecode(snapshot.allocationsJson) as Map<String, dynamic>;
        for (var entry in rawAllocations.entries) {
          final data = entry.value as Map<String, dynamic>;
          final accId = data['accountId'] as String?;
          final amt = (data['amountPaise'] as num?)?.toInt() ?? 0;
          if (accId != null) {
            allocatedMap[accId] = amt;
          }
        }
      } catch (_) {}
    }

    final List<AccountLedgerSummary> summaries = [];
    int totalAvailableCash = 0;

    for (var acc in accounts) {
      final allocated = allocatedMap[acc.id] ?? 0;

      int additionalAdded = 0;
      int credits = 0;
      int expenses = 0;
      int transfersReceived = 0;
      int transfersSent = 0;
      int adjustments = 0;

      for (var tx in monthTxs) {
        if (tx.destinationAccountId == acc.id) {
          // Do not count internal remaining decimal allocation as additionalAdded
          // if it is already included in the snapshot's allocated amount.
          final isDecimalAllocationTx = tx.title == 'Remaining Decimal Allocation' ||
              (tx.description != null && tx.description!.contains('Decimal balance allocated'));
          if (tx.type == TransactionType.addMoney) {
            if (!isDecimalAllocationTx) {
              additionalAdded += tx.amountPaise;
            }
          }
          // Note: TransactionType.salary represents overall salary income distributed
          // to envelopes via `allocated = allocatedMap[acc.id]`. Counting it here as credits
          // would double-count the salary for this account. Only additionalIncome represents
          // extra credited income.
          if (tx.type == TransactionType.additionalIncome) credits += tx.amountPaise;
          if (tx.type == TransactionType.transfer) transfersReceived += tx.amountPaise;
          if (tx.type == TransactionType.refund) expenses -= tx.amountPaise;
          if (tx.type == TransactionType.savingsWithdrawal) transfersReceived += tx.amountPaise;
          if (tx.type == TransactionType.adjustment) adjustments += tx.amountPaise;
        }

        if (tx.sourceAccountId == acc.id) {
          if (tx.type == TransactionType.expense) expenses += tx.amountPaise;
          if (tx.type == TransactionType.transfer) transfersSent += tx.amountPaise;
          if (tx.type == TransactionType.savingsContribution) transfersSent += tx.amountPaise;
          if (tx.type == TransactionType.investmentContribution) transfersSent += tx.amountPaise;
          if (tx.type == TransactionType.adjustment) adjustments -= tx.amountPaise;
        }
      }

      final currentBalance = acc.openingBalancePaise +
          allocated +
          additionalAdded +
          credits +
          transfersReceived -
          expenses -
          transfersSent +
          adjustments;

      totalAvailableCash += currentBalance;

      summaries.add(AccountLedgerSummary(
        account: acc,
        openingBalancePaise: acc.openingBalancePaise,
        allocatedPaise: allocated,
        additionalAddedPaise: additionalAdded,
        creditsPaise: credits,
        expensesPaise: expenses,
        transfersReceivedPaise: transfersReceived,
        transfersSentPaise: transfersSent,
        adjustmentsPaise: adjustments,
        currentBalancePaise: currentBalance,
      ));
    }

    int totalSavingsAccumulated = 0;
    for (var g in goals) {
      totalSavingsAccumulated += g.currentSavedPaise;
    }

    int totalInvestmentValuation = 0;
    int totalInvestmentCost = 0;
    for (var inv in investments) {
      totalInvestmentCost += inv.totalInvestedPaise;
      totalInvestmentValuation += inv.currentValuePaise;
    }

    final netWorth = totalAvailableCash + totalSavingsAccumulated + totalInvestmentValuation;

    return {
      'totalSalaryIncome': totalSalaryIncome,
      'totalAdditionalIncome': totalAdditionalIncome,
      'totalIncome': totalIncome,
      'totalAllocated': totalAllocated,
      'totalAdded': totalAdded,
      'totalSpent': totalSpent,
      'totalTransferred': totalTransferred,
      'totalSavingsContributions': totalSavingsContributions,
      'totalInvestmentsContributions': totalInvestmentsContributions,
      'totalAvailableCash': totalAvailableCash,
      'totalSavingsAccumulated': totalSavingsAccumulated,
      'totalInvestmentValuation': totalInvestmentValuation,
      'totalInvestmentCost': totalInvestmentCost,
      'netWorth': netWorth,
      'accountSummaries': summaries,
      'snapshot': snapshot,
    };
  }

  // -------------------------------------------------------------
  // Savings Goals & Challenges
  // -------------------------------------------------------------
  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    await _dbHelper.init();
    final list = _dbHelper.savingsGoalsBox.values.map((v) {
      return SavingsGoalModel.fromMap(Map<String, dynamic>.from(v));
    }).toList();
    list.sort((a, b) => (b.isEmergencyFund ? 1 : 0).compareTo(a.isEmergencyFund ? 1 : 0));
    return list;
  }

  Future<void> createSavingsGoal(SavingsGoalModel goal) async {
    await _dbHelper.init();
    await _dbHelper.savingsGoalsBox.put(goal.id, goal.toMap());
  }

  Future<void> updateSavingsGoal(SavingsGoalModel goal) async {
    await _dbHelper.init();
    await _dbHelper.savingsGoalsBox.put(goal.id, goal.toMap());
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _dbHelper.init();
    await _dbHelper.savingsGoalsBox.delete(id);
  }

  // -------------------------------------------------------------
  // Investments
  // -------------------------------------------------------------
  Future<List<InvestmentModel>> getInvestments() async {
    await _dbHelper.init();
    final list = _dbHelper.investmentsBox.values.map((v) {
      return InvestmentModel.fromMap(Map<String, dynamic>.from(v));
    }).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  Future<void> createInvestment(InvestmentModel investment) async {
    await _dbHelper.init();
    await _dbHelper.investmentsBox.put(investment.id, investment.toMap());
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _dbHelper.init();
    await _dbHelper.investmentsBox.put(investment.id, investment.toMap());
  }

  Future<void> deleteInvestment(String id) async {
    await _dbHelper.init();
    await _dbHelper.investmentsBox.delete(id);
  }

  // -------------------------------------------------------------
  // Recurring Transactions
  // -------------------------------------------------------------
  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    await _dbHelper.init();
    final list = _dbHelper.recurringTransactionsBox.values.map((v) {
      return RecurringTransactionModel.fromMap(Map<String, dynamic>.from(v));
    }).toList();
    list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return list;
  }

  Future<void> createRecurringTransaction(RecurringTransactionModel rec) async {
    await _dbHelper.init();
    await _dbHelper.recurringTransactionsBox.put(rec.id, rec.toMap());
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _dbHelper.init();
    await _dbHelper.recurringTransactionsBox.delete(id);
  }

  Future<void> resetAllData() async {
    await _dbHelper.resetAllData();
  }
}
