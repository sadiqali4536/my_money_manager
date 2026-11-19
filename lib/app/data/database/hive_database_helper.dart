import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/investment_model.dart';
import '../models/recurring_model.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';

class HiveDatabaseHelper {
  static final HiveDatabaseHelper instance = HiveDatabaseHelper._init();
  HiveDatabaseHelper._init();

  static const String accountsBoxName = 'accounts_box';
  static const String budgetCategoriesBoxName = 'budget_categories_box';
  static const String transactionsBoxName = 'transactions_box';
  static const String monthlyBudgetsBoxName = 'monthly_budgets_box';
  static const String savingsGoalsBoxName = 'savings_goals_box';
  static const String investmentsBoxName = 'investments_box';
  static const String recurringTransactionsBoxName = 'recurring_transactions_box';
  static const String metaBoxName = 'meta_box';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<Map>(accountsBoxName),
      Hive.openBox<Map>(budgetCategoriesBoxName),
      Hive.openBox<Map>(transactionsBoxName),
      Hive.openBox<Map>(monthlyBudgetsBoxName),
      Hive.openBox<Map>(savingsGoalsBoxName),
      Hive.openBox<Map>(investmentsBoxName),
      Hive.openBox<Map>(recurringTransactionsBoxName),
      Hive.openBox(metaBoxName),
    ]);

    _isInitialized = true;

    final meta = Hive.box(metaBoxName);
    final isSeeded = meta.get('is_seeded', defaultValue: false) as bool;
    if (!isSeeded) {
      await seedDefaults();
      await meta.put('is_seeded', true);
    }
  }

  Box<Map> get accountsBox => Hive.box<Map>(accountsBoxName);
  Box<Map> get budgetCategoriesBox => Hive.box<Map>(budgetCategoriesBoxName);
  Box<Map> get transactionsBox => Hive.box<Map>(transactionsBoxName);
  Box<Map> get monthlyBudgetsBox => Hive.box<Map>(monthlyBudgetsBoxName);
  Box<Map> get savingsGoalsBox => Hive.box<Map>(savingsGoalsBoxName);
  Box<Map> get investmentsBox => Hive.box<Map>(investmentsBoxName);
  Box<Map> get recurringTransactionsBox => Hive.box<Map>(recurringTransactionsBoxName);

  Future<void> seedDefaults() async {
    // No hardcoded categories - categories will only appear when created by the user
  }

  Future<void> resetAllData() async {
    await accountsBox.clear();
    await budgetCategoriesBox.clear();
    await transactionsBox.clear();
    await monthlyBudgetsBox.clear();
    await savingsGoalsBox.clear();
    await investmentsBox.clear();
    await recurringTransactionsBox.clear();
  }
}

