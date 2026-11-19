import 'package:flutter_test/flutter_test.dart';
import 'package:my_money_manager/app/core/utils/allocation_calculator.dart';
import 'package:my_money_manager/app/data/models/budget_model.dart';

void main() {
  group('AllocationCalculator Tests', () {
    test('User Example ₹698 with whole-rupee allocation and decimal breakdown', () {
      final categories = [
        BudgetCategoryModel(id: 'c_travel', name: 'Travel', percentage: 12.0, accountId: 'acc_travel'),
        BudgetCategoryModel(id: 'c_food', name: 'Food', percentage: 12.0, accountId: 'acc_food'),
        BudgetCategoryModel(id: 'c_ent', name: 'Entertainment', percentage: 11.0, accountId: 'acc_ent'),
        BudgetCategoryModel(id: 'c_saver', name: 'Daily Saver', percentage: 15.0, accountId: 'acc_saver'),
        BudgetCategoryModel(id: 'c_emerg', name: 'Emergency', percentage: 25.0, accountId: 'acc_emerg'),
        BudgetCategoryModel(id: 'c_invest', name: 'Investment', percentage: 25.0, accountId: 'acc_invest'),
      ];

      final totalSalaryPaise = 69800; // ₹698.00
      final result = AllocationCalculator.calculateAllocations(
        totalSalaryPaise: totalSalaryPaise,
        categories: categories,
      );

      expect(result.isValid100Percent, true);
      expect(result.totalPercentage, 100.0);

      // Verify category whole-rupee allocations:
      // Travel (12% of 698 = 83.76) -> 83
      expect(result.categoryAmountsPaise['c_travel'], 8300);
      expect(result.categoryDetails['c_travel']?.wholeRupees, 83);
      expect(result.categoryDetails['c_travel']?.decimalPaise, 76);

      // Food (12% of 698 = 83.76) -> 83
      expect(result.categoryAmountsPaise['c_food'], 8300);
      expect(result.categoryDetails['c_food']?.wholeRupees, 83);
      expect(result.categoryDetails['c_food']?.decimalPaise, 76);

      // Entertainment (11% of 698 = 76.78) -> 76
      expect(result.categoryAmountsPaise['c_ent'], 7600);
      expect(result.categoryDetails['c_ent']?.wholeRupees, 76);
      expect(result.categoryDetails['c_ent']?.decimalPaise, 78);

      // Daily Saver (15% of 698 = 104.70) -> 104
      expect(result.categoryAmountsPaise['c_saver'], 10400);
      expect(result.categoryDetails['c_saver']?.wholeRupees, 104);
      expect(result.categoryDetails['c_saver']?.decimalPaise, 70);

      // Emergency (25% of 698 = 174.50) -> 174
      expect(result.categoryAmountsPaise['c_emerg'], 17400);
      expect(result.categoryDetails['c_emerg']?.wholeRupees, 174);
      expect(result.categoryDetails['c_emerg']?.decimalPaise, 50);

      // Investment (25% of 698 = 174.50) -> 174
      expect(result.categoryAmountsPaise['c_invest'], 17400);
      expect(result.categoryDetails['c_invest']?.wholeRupees, 174);
      expect(result.categoryDetails['c_invest']?.decimalPaise, 50);

      // Sum of whole rupees: 83 + 83 + 76 + 104 + 174 + 174 = ₹694 (69400 paise)
      expect(result.totalAllocatedPaise, 69400);

      // Remaining decimal sum: 76 + 76 + 78 + 70 + 50 + 50 = ₹4.00 (400 paise)
      expect(result.remainingDecimalPaise, 400);
      expect(result.remainingDecimalRupees, 4.00);

      // Total consistency check: Whole rupees + Decimal remaining == Original Total
      expect(result.totalAllocatedPaise + result.remainingDecimalPaise, totalSalaryPaise);
    });

    test('Standard example ₹25,000 matches exactly', () {
      final categories = [
        BudgetCategoryModel(id: 'cat_food', name: 'Food & Groceries', percentage: 20.0, accountId: 'acc_food'),
        BudgetCategoryModel(id: 'cat_travel', name: 'Travel', percentage: 15.0, accountId: 'acc_travel'),
        BudgetCategoryModel(id: 'cat_emergency', name: 'Emergency Fund', percentage: 20.0, accountId: 'acc_emergency'),
        BudgetCategoryModel(id: 'cat_investments', name: 'Investments', percentage: 15.0, accountId: 'acc_investments'),
        BudgetCategoryModel(id: 'cat_daily_savings', name: 'Daily Savings', percentage: 10.0, accountId: 'acc_daily_savings'),
        BudgetCategoryModel(id: 'cat_entertainment', name: 'Entertainment', percentage: 10.0, accountId: 'acc_entertainment'),
        BudgetCategoryModel(id: 'cat_other', name: 'Other / Buffer', percentage: 10.0, accountId: 'acc_other'),
      ];

      final totalSalaryPaise = 2500000; // ₹25,000.00
      final result = AllocationCalculator.calculateAllocations(
        totalSalaryPaise: totalSalaryPaise,
        categories: categories,
      );

      expect(result.isValid100Percent, true);
      expect(result.totalPercentage, 100.0);
      expect(result.totalAllocatedPaise, 2500000);
      expect(result.remainingDecimalPaise, 0);

      expect(result.categoryAmountsPaise['cat_food'], 500000); // ₹5,000
      expect(result.categoryAmountsPaise['cat_travel'], 375000); // ₹3,750
      expect(result.categoryAmountsPaise['cat_emergency'], 500000); // ₹5,000
      expect(result.categoryAmountsPaise['cat_investments'], 375000); // ₹3,750
      expect(result.categoryAmountsPaise['cat_daily_savings'], 250000); // ₹2,500
      expect(result.categoryAmountsPaise['cat_entertainment'], 250000); // ₹2,500
      expect(result.categoryAmountsPaise['cat_other'], 250000); // ₹2,500

      final sum = result.categoryAmountsPaise.values.reduce((a, b) => a + b);
      expect(sum, totalSalaryPaise);
    });

    test('Decimal percentages and odd amounts separate whole rupees and decimals cleanly', () {
      final categories = [
        BudgetCategoryModel(id: 'c1', name: 'Cat 1', percentage: 20.0, accountId: 'a1'),
        BudgetCategoryModel(id: 'c2', name: 'Cat 2', percentage: 15.0, accountId: 'a2'),
        BudgetCategoryModel(id: 'c3', name: 'Cat 3', percentage: 20.0, accountId: 'a3'),
        BudgetCategoryModel(id: 'c4', name: 'Cat 4', percentage: 15.0, accountId: 'a4'),
        BudgetCategoryModel(id: 'c5', name: 'Cat 5', percentage: 10.0, accountId: 'a5'),
        BudgetCategoryModel(id: 'c6', name: 'Cat 6', percentage: 10.0, accountId: 'a6'),
        BudgetCategoryModel(id: 'c7', name: 'Cat 7', percentage: 10.0, accountId: 'a7'),
      ];

      final totalSalaryPaise = 3333300; // ₹33,333.00
      final result = AllocationCalculator.calculateAllocations(
        totalSalaryPaise: totalSalaryPaise,
        categories: categories,
      );

      expect(result.isValid100Percent, true);
      // Total whole allocations + remaining decimal paise must exactly match original amount
      expect(result.totalAllocatedPaise + result.remainingDecimalPaise, totalSalaryPaise);
    });

    test('TEST B: Fixed Amount ₹10,000 + 6 percentage categories from ₹12,500 salary', () {
      final categories = [
        BudgetCategoryModel(
          id: 'c_loan',
          name: 'Loan',
          percentage: 0.0,
          accountId: 'acc_loan',
          allocationType: AllocationType.fixed,
          fixedAmountPaise: 1000000, // ₹10,000.00
        ),
        BudgetCategoryModel(id: 'c_travel', name: 'Travel', percentage: 12.0, accountId: 'acc_travel'),
        BudgetCategoryModel(id: 'c_food', name: 'Food', percentage: 12.0, accountId: 'acc_food'),
        BudgetCategoryModel(id: 'c_ent', name: 'Entertainment', percentage: 11.0, accountId: 'acc_ent'),
        BudgetCategoryModel(id: 'c_saver', name: 'Daily Saver', percentage: 15.0, accountId: 'acc_saver'),
        BudgetCategoryModel(id: 'c_emerg', name: 'Emergency', percentage: 25.0, accountId: 'acc_emerg'),
        BudgetCategoryModel(id: 'c_invest', name: 'Investment', percentage: 25.0, accountId: 'acc_invest'),
      ];

      final totalSalaryPaise = 1250000; // ₹12,500.00
      final result = AllocationCalculator.calculateAllocations(
        totalSalaryPaise: totalSalaryPaise,
        categories: categories,
      );

      // Total Fixed: ₹10,000 (1000000 paise)
      expect(result.totalFixedAllocationsPaise, 1000000);
      // Remaining Salary for Percentages: ₹2,500 (250000 paise)
      expect(result.remainingSalaryForPercentagesPaise, 250000);

      // Percentage allocations calculated using ₹2,500:
      // Travel (12%) = 2500 * 0.12 = ₹300
      expect(result.categoryAmountsPaise['c_travel'], 30000);
      // Food (12%) = 2500 * 0.12 = ₹300
      expect(result.categoryAmountsPaise['c_food'], 30000);
      // Entertainment (11%) = 2500 * 0.11 = ₹275
      expect(result.categoryAmountsPaise['c_ent'], 27500);
      // Daily Saver (15%) = 2500 * 0.15 = ₹375
      expect(result.categoryAmountsPaise['c_saver'], 37500);
      // Emergency (25%) = 2500 * 0.25 = ₹625
      expect(result.categoryAmountsPaise['c_emerg'], 62500);
      // Investment (25%) = 2500 * 0.25 = ₹625
      expect(result.categoryAmountsPaise['c_invest'], 62500);
      // Loan (Fixed) = ₹10,000
      expect(result.categoryAmountsPaise['c_loan'], 1000000);

      // Total Allocated: 10000 + 300 + 300 + 275 + 375 + 625 + 625 = ₹12,500.00
      expect(result.totalAllocatedPaise, 1250000);
      expect(result.remainingDecimalPaise, 0);
      expect(result.unallocatedPortionPaise, 0);
      expect(result.isValid100Percent, true);
    });

    test('MANDATORY VALIDATION: Salary ₹12,500, Fixed ₹11,050, Remaining ₹1,450. Total Allocated strictly NEVER ₹12,503', () {
      final categories = [
        BudgetCategoryModel(
          id: 'c_fixed_loan',
          name: 'Loan',
          percentage: 0.0,
          accountId: 'acc_loan',
          allocationType: AllocationType.fixed,
          fixedAmountPaise: 1105000, // ₹11,050.00
        ),
        // 6 categories summing strictly to 100%
        BudgetCategoryModel(id: 'c_travel', name: 'Travel', percentage: 12.0, accountId: 'acc_travel'),
        BudgetCategoryModel(id: 'c_food', name: 'Food', percentage: 12.0, accountId: 'acc_food'),
        BudgetCategoryModel(id: 'c_ent', name: 'Entertainment', percentage: 11.0, accountId: 'acc_ent'),
        BudgetCategoryModel(id: 'c_saver', name: 'Daily Saver', percentage: 15.0, accountId: 'acc_saver'),
        BudgetCategoryModel(id: 'c_emerg', name: 'Emergency', percentage: 25.0, accountId: 'acc_emerg'),
        BudgetCategoryModel(id: 'c_invest', name: 'Investment', percentage: 25.0, accountId: 'acc_invest'),
      ];

      final totalSalaryPaise = 1250000; // ₹12,500.00
      final result = AllocationCalculator.calculateAllocations(
        totalSalaryPaise: totalSalaryPaise,
        categories: categories,
      );

      // Verify Fixed Allocation & Remaining Base
      expect(result.totalFixedAllocationsPaise, 1105000); // ₹11,050.00
      expect(result.remainingSalaryForPercentagesPaise, 145000); // ₹1,450.00

      // Mandatory Validation:
      // Total Fixed Amount + Total Percentage Amount = Original Salary
      // ₹11,050 + ₹1,450 = ₹12,500
      expect(result.totalAllocatedPaise + result.remainingDecimalPaise, totalSalaryPaise);
      expect(result.totalAllocatedPaise, isNot(1250300)); // NEVER ₹12,503
      expect(result.totalAllocatedPaise <= totalSalaryPaise, true);

      // Even if categories had previous leftover allocatedRemainderPaise from an earlier session (e.g. ₹3.00),
      // the calculation must strictly clamp and never produce ₹12,503!
      final categoriesWithOldStaleRemainder = [
        BudgetCategoryModel(
          id: 'c_fixed_loan',
          name: 'Loan',
          percentage: 0.0,
          accountId: 'acc_loan',
          allocationType: AllocationType.fixed,
          fixedAmountPaise: 1105000, // ₹11,050.00
        ),
        BudgetCategoryModel(id: 'c_travel', name: 'Travel', percentage: 12.0, accountId: 'acc_travel'),
        BudgetCategoryModel(id: 'c_food', name: 'Food', percentage: 12.0, accountId: 'acc_food'),
        BudgetCategoryModel(id: 'c_ent', name: 'Entertainment', percentage: 11.0, accountId: 'acc_ent'),
        BudgetCategoryModel(
          id: 'c_saver',
          name: 'Daily Saver',
          percentage: 15.0,
          accountId: 'acc_saver',
          allocatedRemainderPaise: 300, // Old stale ₹3.00 remainder from prior month or test
        ),
        BudgetCategoryModel(id: 'c_emerg', name: 'Emergency', percentage: 25.0, accountId: 'acc_emerg'),
        BudgetCategoryModel(id: 'c_invest', name: 'Investment', percentage: 25.0, accountId: 'acc_invest'),
      ];

      final resultWithStale = AllocationCalculator.calculateAllocations(
        totalSalaryPaise: totalSalaryPaise,
        categories: categoriesWithOldStaleRemainder,
      );

      expect(resultWithStale.totalAllocatedPaise + resultWithStale.remainingDecimalPaise, totalSalaryPaise);
      expect(resultWithStale.totalAllocatedPaise, isNot(1250300)); // Must NEVER be ₹12,503!
      expect(resultWithStale.totalAllocatedPaise <= totalSalaryPaise, true);
    });
  });
}
