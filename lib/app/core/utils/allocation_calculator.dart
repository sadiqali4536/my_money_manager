import '../../data/models/budget_model.dart';

/// Holds the breakdown of an individual category's allocation
class CategoryAllocationDetail {
  final String categoryId;
  final String categoryName;
  final double percentage;

  /// The exact mathematical amount in rupees e.g. 83.76
  final double exactRupees;

  /// Whole rupee portion allocated to the category e.g. 83
  final int wholeRupees;

  /// The exact whole rupee amount in paise e.g. 8300
  int get wholePaise => wholeRupees * 100;

  /// Decimal portion remaining e.g. 0.76
  final double decimalRupees;

  /// Decimal portion in paise e.g. 76
  final int decimalPaise;

  const CategoryAllocationDetail({
    required this.categoryId,
    required this.categoryName,
    required this.percentage,
    required this.exactRupees,
    required this.wholeRupees,
    required this.decimalRupees,
    required this.decimalPaise,
  });
}

class AllocationCalculationResult {
  /// Map of CategoryId -> Allocated amount in Paise (whole rupees + remainder for percentage, or fixed amount)
  final Map<String, int> categoryAmountsPaise;

  /// Detailed per-category calculation breakdown
  final Map<String, CategoryAllocationDetail> categoryDetails;

  /// Total of all allocations in paise
  final int totalAllocatedPaise;

  /// Remaining decimal amount in paise aggregated from percentage category calculations
  final int remainingDecimalPaise;

  /// Remaining decimal amount in rupees (e.g. 4.00)
  double get remainingDecimalRupees => remainingDecimalPaise / 100.0;

  /// Total unallocated paise
  final int unallocatedPortionPaise;

  /// Total percentage sum of all percentage-based categories
  final double totalPercentage;

  /// Whether total percentage sums up to 100% (or true if no percentage categories and fixed amounts <= salary)
  final bool isValid100Percent;

  /// Sum of all fixed allocations in paise
  final int totalFixedAllocationsPaise;

  /// Remaining salary available for percentage distribution:
  /// (totalSalaryPaise - totalFixedAllocationsPaise).clamp(0, totalSalaryPaise)
  final int remainingSalaryForPercentagesPaise;

  /// Whether fixed allocations exceed total salary
  final bool isFixedExceedingSalary;

  /// For backward compatibility with existing tests/views
  int get remainingUnallocatedPaise =>
      remainingDecimalPaise + unallocatedPortionPaise;

  AllocationCalculationResult({
    required this.categoryAmountsPaise,
    required this.categoryDetails,
    required this.totalAllocatedPaise,
    required this.remainingDecimalPaise,
    required this.unallocatedPortionPaise,
    required this.totalPercentage,
    required this.isValid100Percent,
    this.totalFixedAllocationsPaise = 0,
    this.remainingSalaryForPercentagesPaise = 0,
    this.isFixedExceedingSalary = false,
  });
}

class AllocationCalculator {
  /// Tolerance for 100% check to handle floating point representation
  static const double epsilon = 0.0001;

  /// Calculate the total percentage of percentage-based categories with high precision
  static double calculateTotalPercentage(List<BudgetCategoryModel> categories) {
    if (categories.isEmpty) return 0.0;
    final percentageCategories = categories.where((c) => !c.isFixed);
    if (percentageCategories.isEmpty) return 0.0;
    final rawSum = percentageCategories.fold(0.0, (sum, cat) => sum + cat.percentage);
    return double.parse(rawSum.toStringAsFixed(4));
  }

  /// Checks if the total percentage equals 100%
  static bool isExact100Percent(double totalPercentage) {
    return (totalPercentage - 100.0).abs() <= epsilon;
  }

  /// Calculates the distribution of [totalSalaryPaise] across [categories].
  ///
  /// Calculation Rules:
  /// 1. Calculate & deduct all Fixed Amount allocations first from the original salary.
  /// 2. Calculate remaining available salary = (totalSalaryPaise - totalFixedPaise).
  /// 3. Apply percentage allocations ONLY to the remaining available salary.
  ///    - If no fixed allocations exist, remaining salary == total original salary.
  ///    - If remaining salary is 0 (or negative), percentage category amounts are 0.
  /// 4. Whole rupee portion is allocated for each percentage category; decimals are gathered into remainingDecimalPaise.
  static AllocationCalculationResult calculateAllocations({
    required int totalSalaryPaise,
    required List<BudgetCategoryModel> categories,
  }) {
    if (categories.isEmpty || totalSalaryPaise <= 0) {
      return AllocationCalculationResult(
        categoryAmountsPaise: {},
        categoryDetails: {},
        totalAllocatedPaise: 0,
        remainingDecimalPaise: 0,
        unallocatedPortionPaise: totalSalaryPaise > 0 ? totalSalaryPaise : 0,
        totalPercentage: 0.0,
        isValid100Percent: false,
        totalFixedAllocationsPaise: 0,
        remainingSalaryForPercentagesPaise: 0,
        isFixedExceedingSalary: false,
      );
    }

    // Step 1: Calculate Total Fixed Allocations
    int totalFixedPaise = 0;
    for (var cat in categories) {
      if (cat.isFixed) {
        totalFixedPaise += cat.fixedAmountPaise;
      }
    }

    final bool isFixedExceeding = totalFixedPaise > totalSalaryPaise;

    // Step 2: Remaining Available Salary for Percentage Allocations
    final int remainingSalaryPaise =
        (totalSalaryPaise - totalFixedPaise).clamp(0, totalSalaryPaise);

    final percentageCategories = categories.where((c) => !c.isFixed).toList();
    final totalPercentage = calculateTotalPercentage(categories);
    final hasPercentageCategories = percentageCategories.isNotEmpty;
    final is100 = hasPercentageCategories
        ? isExact100Percent(totalPercentage)
        : (totalFixedPaise == totalSalaryPaise);

    final Map<String, int> amountsPaise = {};
    final Map<String, CategoryAllocationDetail> details = {};

    int totalWholeRupeesPaise = 0;
    int totalDecimalPaise = 0;

    // Step 3: Process Fixed Allocations first
    for (var cat in categories) {
      if (cat.isFixed) {
        final fixedPaise = cat.fixedAmountPaise;
        final wholeRupees = fixedPaise ~/ 100;
        final wholePaise = wholeRupees * 100;
        final decimalPaise = fixedPaise - wholePaise;
        final decimalRupees = double.parse(
          (decimalPaise / 100.0).toStringAsFixed(2),
        );
        final exactRupees = double.parse(
          (fixedPaise / 100.0).toStringAsFixed(2),
        );

        amountsPaise[cat.id] = fixedPaise;
        totalWholeRupeesPaise += fixedPaise;

        details[cat.id] = CategoryAllocationDetail(
          categoryId: cat.id,
          categoryName: cat.name,
          percentage: 0.0,
          exactRupees: exactRupees,
          wholeRupees: wholeRupees,
          decimalRupees: decimalRupees,
          decimalPaise: decimalPaise,
        );
      }
    }

    // Step 4: Process Percentage Categories using remainingSalaryPaise
    for (var cat in categories) {
      if (!cat.isFixed) {
        if (cat.percentage <= 0 || remainingSalaryPaise <= 0) {
          amountsPaise[cat.id] = 0;
          details[cat.id] = CategoryAllocationDetail(
            categoryId: cat.id,
            categoryName: cat.name,
            percentage: cat.percentage,
            exactRupees: 0.0,
            wholeRupees: 0,
            decimalRupees: 0.0,
            decimalPaise: 0,
          );
        } else {
          // Precise exact paise calculation based strictly on remaining available salary
          final exactPaise = ((remainingSalaryPaise * cat.percentage) / 100.0).round();

          // Whole rupee portion (Floor to integer rupees - NEVER round up)
          final wholeRupees = exactPaise ~/ 100;
          final wholePaise = wholeRupees * 100;

          // Decimal portion
          final decimalPaise = exactPaise - wholePaise;
          final decimalRupees = double.parse(
            (decimalPaise / 100.0).toStringAsFixed(2),
          );
          final exactRupees = double.parse(
            (exactPaise / 100.0).toStringAsFixed(2),
          );

          amountsPaise[cat.id] = wholePaise;
          totalWholeRupeesPaise += wholePaise;
          totalDecimalPaise += decimalPaise;

          details[cat.id] = CategoryAllocationDetail(
            categoryId: cat.id,
            categoryName: cat.name,
            percentage: cat.percentage,
            exactRupees: exactRupees,
            wholeRupees: wholeRupees,
            decimalRupees: decimalRupees,
            decimalPaise: decimalPaise,
          );
        }
      }
    }

    // If 100% percentage allocation, reconcile any 1-paise floating discrepancy into the decimal remainder
    if (is100 && hasPercentageCategories && remainingSalaryPaise > 0) {
      // Sum of percentage whole rupees and decimals should equal remainingSalaryPaise
      int percentageWholeRupeesPaise = 0;
      for (var cat in percentageCategories) {
        percentageWholeRupeesPaise += (amountsPaise[cat.id] ?? 0);
      }
      final discrepancy =
          remainingSalaryPaise - (percentageWholeRupeesPaise + totalDecimalPaise);
      if (discrepancy != 0) {
        totalDecimalPaise += discrepancy;
      }
    }

    // Account for any previously allocated remainder per category, ensuring the total
    // allocated can NEVER exceed totalSalaryPaise.
    // If the salary or category configurations changed such that totalExtraRemainderPaise exceeds
    // the available decimal remainder, cap it strictly at totalDecimalPaise.
    final int allowedExtraPaise = totalExtraRemainderPaiseCap(
      totalDecimalPaise: totalDecimalPaise,
      categories: categories,
    );

    int extraAppliedPaise = 0;
    if (allowedExtraPaise > 0) {
      for (var cat in categories) {
        if (cat.allocatedRemainderPaise > 0) {
          // Proportionally apply or clamp extra remainder up to allowedExtraPaise
          final remainingAllowance = allowedExtraPaise - extraAppliedPaise;
          if (remainingAllowance <= 0) break;
          final extra = cat.allocatedRemainderPaise <= remainingAllowance
              ? cat.allocatedRemainderPaise
              : remainingAllowance;
          amountsPaise[cat.id] = (amountsPaise[cat.id] ?? 0) + extra;
          extraAppliedPaise += extra;
        }
      }
    }

    // Net remaining decimal paise after deducting allocated remainders
    final netRemainingDecimalPaise =
        (totalDecimalPaise - extraAppliedPaise).clamp(0, totalDecimalPaise);

    // netTotalAllocatedPaise can NEVER exceed totalSalaryPaise:
    // Total Fixed Amount + Total Percentage Amount (whole + allocated decimals) <= Original Salary
    final rawTotalAllocatedPaise = totalWholeRupeesPaise + extraAppliedPaise;
    final netTotalAllocatedPaise = rawTotalAllocatedPaise > totalSalaryPaise
        ? totalSalaryPaise
        : rawTotalAllocatedPaise;

    final unallocatedPortion = (is100 && !isFixedExceeding)
        ? (remainingSalaryPaise == 0 && totalFixedPaise == totalSalaryPaise
            ? 0
            : (totalSalaryPaise - (netTotalAllocatedPaise + netRemainingDecimalPaise)).clamp(0, totalSalaryPaise))
        : (totalSalaryPaise - (netTotalAllocatedPaise + netRemainingDecimalPaise))
              .clamp(0, totalSalaryPaise);

    return AllocationCalculationResult(
      categoryAmountsPaise: amountsPaise,
      categoryDetails: details,
      totalAllocatedPaise: netTotalAllocatedPaise,
      remainingDecimalPaise: netRemainingDecimalPaise,
      unallocatedPortionPaise: unallocatedPortion,
      totalPercentage: totalPercentage,
      isValid100Percent: is100,
      totalFixedAllocationsPaise: totalFixedPaise,
      remainingSalaryForPercentagesPaise: remainingSalaryPaise,
      isFixedExceedingSalary: isFixedExceeding,
    );
  }

  /// Calculates the maximum allowed extra remainder that can be distributed to categories
  /// without exceeding the available decimal remainder for the current calculation.
  static int totalExtraRemainderPaiseCap({
    required int totalDecimalPaise,
    required List<BudgetCategoryModel> categories,
  }) {
    if (totalDecimalPaise <= 0) return 0;
    int requested = 0;
    for (var cat in categories) {
      requested += cat.allocatedRemainderPaise;
    }
    return requested <= totalDecimalPaise ? requested : totalDecimalPaise;
  }
}
