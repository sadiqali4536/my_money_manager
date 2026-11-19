import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/savings_goal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_money_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconKey TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        openingBalancePaise INTEGER NOT NULL DEFAULT 0,
        isDefault INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Budget Categories Table
    await db.execute('''
      CREATE TABLE budget_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        percentage REAL NOT NULL,
        accountId TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // 3. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amountPaise INTEGER NOT NULL,
        sourceAccountId TEXT,
        destinationAccountId TEXT,
        categoryId TEXT,
        title TEXT NOT NULL,
        description TEXT,
        paymentMethod TEXT,
        transactionDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        attachmentPath TEXT,
        balanceAfterPaise INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. Monthly Budget Snapshot Table
    await db.execute('''
      CREATE TABLE monthly_budgets (
        id TEXT PRIMARY KEY,
        monthKey TEXT NOT NULL UNIQUE,
        salaryPaise INTEGER NOT NULL,
        allocationsJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 5. Savings Goals Table
    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        targetAmountPaise INTEGER NOT NULL,
        currentSavedPaise INTEGER NOT NULL DEFAULT 0,
        targetDate TEXT,
        accountId TEXT,
        isEmergencyFund INTEGER NOT NULL DEFAULT 0,
        iconKey TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 6. Investments Table
    await db.execute('''
      CREATE TABLE investments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        totalInvestedPaise INTEGER NOT NULL,
        currentValuePaise INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        notes TEXT,
        accountId TEXT
      )
    ''');

    // 7. Recurring Transactions Table
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amountPaise INTEGER NOT NULL,
        typeName TEXT NOT NULL,
        accountId TEXT NOT NULL,
        frequency TEXT NOT NULL,
        nextDueDate TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');

    // Seed Initial Default Accounts & Allocation Categories
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    final defaultAccounts = [
      AccountModel(
        id: 'acc_food',
        name: 'Food & Groceries',
        iconKey: 'restaurant',
        colorValue: 0xFF3B82F6,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 1,
      ),
      AccountModel(
        id: 'acc_travel',
        name: 'Travel & Commute',
        iconKey: 'directions_car',
        colorValue: 0xFF10B981,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 2,
      ),
      AccountModel(
        id: 'acc_emergency',
        name: 'Emergency Fund',
        iconKey: 'shield',
        colorValue: 0xFFF59E0B,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 3,
      ),
      AccountModel(
        id: 'acc_investments',
        name: 'Investments',
        iconKey: 'trending_up',
        colorValue: 0xFF8B5CF6,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 4,
      ),
      AccountModel(
        id: 'acc_daily_savings',
        name: 'Daily Savings / Goals',
        iconKey: 'savings',
        colorValue: 0xFFEC4899,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 5,
      ),
      AccountModel(
        id: 'acc_entertainment',
        name: 'Entertainment',
        iconKey: 'movie',
        colorValue: 0xFF06B6D4,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 6,
      ),
      AccountModel(
        id: 'acc_other',
        name: 'Other / Buffer',
        iconKey: 'more_horiz',
        colorValue: 0xFF64748B,
        openingBalancePaise: 0,
        isDefault: true,
        sortOrder: 7,
      ),
    ];

    for (var acc in defaultAccounts) {
      await db.insert('accounts', acc.toMap());
    }

    // Default Budget percentages (Total = 100%)
    final defaultBudgets = [
      BudgetCategoryModel(
        id: 'cat_food',
        name: 'Food & Groceries',
        percentage: 20.0,
        accountId: 'acc_food',
        sortOrder: 1,
      ),
      BudgetCategoryModel(
        id: 'cat_travel',
        name: 'Travel',
        percentage: 15.0,
        accountId: 'acc_travel',
        sortOrder: 2,
      ),
      BudgetCategoryModel(
        id: 'cat_emergency',
        name: 'Emergency Fund',
        percentage: 20.0,
        accountId: 'acc_emergency',
        sortOrder: 3,
      ),
      BudgetCategoryModel(
        id: 'cat_investments',
        name: 'Investments',
        percentage: 15.0,
        accountId: 'acc_investments',
        sortOrder: 4,
      ),
      BudgetCategoryModel(
        id: 'cat_daily_savings',
        name: 'Daily Savings / Goals',
        percentage: 10.0,
        accountId: 'acc_daily_savings',
        sortOrder: 5,
      ),
      BudgetCategoryModel(
        id: 'cat_entertainment',
        name: 'Entertainment',
        percentage: 10.0,
        accountId: 'acc_entertainment',
        sortOrder: 6,
      ),
      BudgetCategoryModel(
        id: 'cat_other',
        name: 'Other / Buffer',
        percentage: 10.0,
        accountId: 'acc_other',
        sortOrder: 7,
      ),
    ];

    for (var cat in defaultBudgets) {
      await db.insert('budget_categories', cat.toMap());
    }

    // Default Emergency Fund Goal
    final defaultEmergencyGoal = SavingsGoalModel(
      id: 'goal_emergency_fund',
      name: 'Emergency Buffer (6 Months)',
      targetAmountPaise: 15000000, // ₹1,50,000.00
      currentSavedPaise: 0,
      accountId: 'acc_emergency',
      isEmergencyFund: true,
      iconKey: 'shield',
      colorValue: 0xFFF59E0B,
    );
    await db.insert('savings_goals', defaultEmergencyGoal.toMap());
  }

  Future<void> resetAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('monthly_budgets');
    await db.delete('savings_goals');
    await db.delete('investments');
    await db.delete('recurring_transactions');
    await db.delete('budget_categories');
    await db.delete('accounts');
    await _seedDefaultData(db);
  }
}

