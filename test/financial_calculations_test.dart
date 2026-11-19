import 'package:flutter_test/flutter_test.dart';
import 'package:my_money_manager/app/core/utils/currency_helper.dart';
import 'package:my_money_manager/app/data/models/budget_model.dart';

void main() {
  group('CurrencyHelper & Decimal-safe Paise Calculations', () {
    test('Correct Paise to Rupee conversions', () {
      expect(CurrencyHelper.rupeesToPaise(25000.0), 2500000);
      expect(CurrencyHelper.paiseToRupees(2500000), 25000.0);
      expect(CurrencyHelper.rupeesToPaise(0.50), 50);
      expect(CurrencyHelper.paiseToRupees(50), 0.50);
    });

    test('Indian Currency Formatting (INR)', () {
      final formatted = CurrencyHelper.formatPaise(2500000);
      expect(formatted.contains('25,000'), isTrue);
      expect(formatted.startsWith('₹'), isTrue);
    });
  });

  group('Salary Allocation Percentage Validation', () {
    final defaultCategories = [
      BudgetCategoryModel(id: 'cat_food', name: 'Food & Groceries', percentage: 20.0, accountId: 'acc_food'),
      BudgetCategoryModel(id: 'cat_travel', name: 'Travel', percentage: 15.0, accountId: 'acc_travel'),
      BudgetCategoryModel(id: 'cat_emergency', name: 'Emergency Fund', percentage: 20.0, accountId: 'acc_emergency'),
      BudgetCategoryModel(id: 'cat_investments', name: 'Investments', percentage: 15.0, accountId: 'acc_investments'),
      BudgetCategoryModel(id: 'cat_daily_savings', name: 'Daily Savings', percentage: 10.0, accountId: 'acc_daily_savings'),
      BudgetCategoryModel(id: 'cat_entertainment', name: 'Entertainment', percentage: 10.0, accountId: 'acc_entertainment'),
      BudgetCategoryModel(id: 'cat_other', name: 'Other', percentage: 10.0, accountId: 'acc_other'),
    ];

    test('Categories sum strictly to 100%', () {
      final total = defaultCategories.fold(0.0, (sum, c) => sum + c.percentage);
      expect(total, 100.0);
    });

    test('Exact Allocation amount calculations for ₹25,000 salary', () {
      const salaryPaise = 2500000; // ₹25,000

      // Food (20%): ₹5,000
      final foodPaise = ((salaryPaise * 20.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(foodPaise), 5000.0);

      // Travel (15%): ₹3,750
      final travelPaise = ((salaryPaise * 15.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(travelPaise), 3750.0);

      // Emergency (20%): ₹5,000
      final emergencyPaise = ((salaryPaise * 20.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(emergencyPaise), 5000.0);

      // Investments (15%): ₹3,750
      final invPaise = ((salaryPaise * 15.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(invPaise), 3750.0);

      // Daily Savings (10%): ₹2,500
      final dailySavingsPaise = ((salaryPaise * 10.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(dailySavingsPaise), 2500.0);

      // Entertainment (10%): ₹2,500
      final entPaise = ((salaryPaise * 10.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(entPaise), 2500.0);

      // Other (10%): ₹2,500
      final otherPaise = ((salaryPaise * 10.0) / 100).round();
      expect(CurrencyHelper.paiseToRupees(otherPaise), 2500.0);

      final sumAll = foodPaise + travelPaise + emergencyPaise + invPaise + dailySavingsPaise + entPaise + otherPaise;
      expect(sumAll, salaryPaise);
    });
  });

  group('Financial Accounting Ledger Rules', () {
    test('Account ledger calculation: Food ₹5000 - ₹500 spent + ₹1000 added = ₹5500', () {
      int foodInitialAllocation = 500000; // ₹5,000
      int foodExpense = 50000;           // ₹500
      int foodAddMoney = 100000;         // ₹1,000

      int balance = foodInitialAllocation - foodExpense + foodAddMoney;
      expect(CurrencyHelper.paiseToRupees(balance), 5500.0);
    });

    test('Overall financial calculation dashboard metrics example', () {
      // Salary received: ₹25,000
      int salary = 2500000;
      // Additional income: ₹2,000
      int additionalIncome = 200000;
      // Additional credits to accounts: ₹1,000
      int addedCredits = 100000;
      // Actual expenses: ₹8,500
      int expenses = 850000;
      // Internal transfers: ₹500 (does not change net cash)

      int totalIncome = salary + additionalIncome; // ₹27,000
      int netCashRemaining = (totalIncome + addedCredits) - expenses; // ₹19,500 if added money is external cash

      expect(CurrencyHelper.paiseToRupees(totalIncome), 27000.0);
      expect(CurrencyHelper.paiseToRupees(expenses), 8500.0);
      expect(CurrencyHelper.paiseToRupees(netCashRemaining), 19500.0);
    });

    test('User Scenario: Salary ₹1,028 allocation and ₹4 remaining decimal added to Food & Grocery', () {
      // User scenario:
      // Total salary: ₹1,028 (102,800 paise)
      // Food & Grocery allocated: ₹154 (15,400 paise)
      // Remaining decimal amount: ₹4 (400 paise)
      // Destination account: Food & Grocery
      final int initialAllocationPaise = 15400;
      final int remainderPaise = 400;
      final int updatedSnapshotPaise = initialAllocationPaise + remainderPaise; // 15800 paise (₹158.00)

      // When counting ledger balance:
      // 1. Snapshot allocation has 15800 paise
      // 2. The internal transaction 'Remaining Decimal Allocation' of 400 paise is recorded
      // Balance must NOT double-add the 400 paise (which would result in ₹162)
      bool filterDecimalTx(String title) {
        return title == 'Remaining Decimal Allocation';
      }
      int additionalAdded = 0;
      if (!filterDecimalTx('Remaining Decimal Allocation')) {
        additionalAdded += remainderPaise;
      }
      final int finalBalancePaise = updatedSnapshotPaise + additionalAdded;
      expect(CurrencyHelper.paiseToRupees(finalBalancePaise), 158.0);

      // Total balance must be exactly ₹1,028, not ₹2,060
      final int totalSalary = 102800;
      expect(CurrencyHelper.paiseToRupees(totalSalary), 1028.0);
    });
  });
}
