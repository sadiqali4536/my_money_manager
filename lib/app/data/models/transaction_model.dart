import 'package:flutter/material.dart';

enum TransactionType {
  salary,               // Monthly salary income credited
  additionalIncome,     // Bonus, freelance, gift
  expense,              // Expense from an account
  addMoney,             // Additional money added to a specific category account
  transfer,             // Transfer between two category accounts
  savingsContribution,  // Savings deposit towards goal / emergency fund
  savingsWithdrawal,    // Withdrawal from savings goal
  investmentContribution,// Investment deposit (SIP/MF/FD)
  refund,               // Refund credited back into an account
  adjustment,           // Reconciliation balance adjustment
}

extension TransactionTypeExtension on TransactionType {
  String get nameString {
    switch (this) {
      case TransactionType.salary:
        return 'Salary Income';
      case TransactionType.additionalIncome:
        return 'Additional Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.addMoney:
        return 'Add Money';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.savingsContribution:
        return 'Savings Deposit';
      case TransactionType.savingsWithdrawal:
        return 'Savings Withdrawal';
      case TransactionType.investmentContribution:
        return 'Investment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.adjustment:
        return 'Balance Adjustment';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.salary:
        return Icons.account_balance_wallet_rounded;
      case TransactionType.additionalIncome:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.addMoney:
        return Icons.add_circle_outline_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.savingsContribution:
        return Icons.savings_outlined;
      case TransactionType.savingsWithdrawal:
        return Icons.outbox_rounded;
      case TransactionType.investmentContribution:
        return Icons.trending_up_rounded;
      case TransactionType.refund:
        return Icons.replay_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }

  bool get isIncomeCategory =>
      this == TransactionType.salary ||
      this == TransactionType.additionalIncome;

  bool get isExpenseCategory => this == TransactionType.expense;

  bool get isAddMoneyCategory => this == TransactionType.addMoney;

  bool get isTransferCategory => this == TransactionType.transfer;
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final int amountPaise;
  final String? sourceAccountId;       // For expense, transfer source, investment/savings source
  final String? destinationAccountId;  // For transfer destination, addMoney target, income target
  final String? categoryId;            // Associated budget category
  final String title;
  final String? description;
  final String? paymentMethod;         // Cash, UPI, Card, NetBanking
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attachmentPath;
  final int balanceAfterPaise;          // Account balance snapshot after this operation

  TransactionModel({
    required this.id,
    required this.type,
    required this.amountPaise,
    this.sourceAccountId,
    this.destinationAccountId,
    this.categoryId,
    required this.title,
    this.description,
    this.paymentMethod = 'UPI',
    required this.transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.attachmentPath,
    this.balanceAfterPaise = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amountPaise': amountPaise,
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachmentPath': attachmentPath,
      'balanceAfterPaise': balanceAfterPaise,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amountPaise: (map['amountPaise'] as num).toInt(),
      sourceAccountId: map['sourceAccountId'] as String?,
      destinationAccountId: map['destinationAccountId'] as String?,
      categoryId: map['categoryId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      attachmentPath: map['attachmentPath'] as String?,
      balanceAfterPaise: (map['balanceAfterPaise'] as num?)?.toInt() ?? 0,
    );
  }

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    int? amountPaise,
    String? sourceAccountId,
    String? destinationAccountId,
    String? categoryId,
    String? title,
    String? description,
    String? paymentMethod,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? attachmentPath,
    int? balanceAfterPaise,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amountPaise: amountPaise ?? this.amountPaise,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      balanceAfterPaise: balanceAfterPaise ?? this.balanceAfterPaise,
    );
  }
}

