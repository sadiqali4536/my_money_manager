enum AllocationType { percentage, fixed }

class BudgetCategoryModel {
  final String id;
  final String name;
  final double percentage; // e.g. 20.0 for 20%
  final String accountId; // Links to associated AccountModel
  final int sortOrder;
  final AllocationType allocationType;
  final int fixedAmountPaise; // Fixed allocation amount in paise if allocationType == fixed
  final int allocatedRemainderPaise; // Extra remainder allocated from decimal leftovers

  BudgetCategoryModel({
    required this.id,
    required this.name,
    required this.percentage,
    required this.accountId,
    this.sortOrder = 0,
    this.allocationType = AllocationType.percentage,
    this.fixedAmountPaise = 0,
    this.allocatedRemainderPaise = 0,
  });

  bool get isFixed => allocationType == AllocationType.fixed;
  double get fixedAmountRupees => fixedAmountPaise / 100.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'percentage': percentage,
      'accountId': accountId,
      'sortOrder': sortOrder,
      'allocationType': allocationType.name,
      'fixedAmountPaise': fixedAmountPaise,
      'allocatedRemainderPaise': allocatedRemainderPaise,
    };
  }

  factory BudgetCategoryModel.fromMap(Map<String, dynamic> map) {
    return BudgetCategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      percentage: (map['percentage'] as num).toDouble(),
      accountId: map['accountId'] as String,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      allocationType: map['allocationType'] == 'fixed'
          ? AllocationType.fixed
          : AllocationType.percentage,
      fixedAmountPaise: (map['fixedAmountPaise'] as num?)?.toInt() ?? 0,
      allocatedRemainderPaise: (map['allocatedRemainderPaise'] as num?)?.toInt() ?? 0,
    );
  }

  BudgetCategoryModel copyWith({
    String? id,
    String? name,
    double? percentage,
    String? accountId,
    int? sortOrder,
    AllocationType? allocationType,
    int? fixedAmountPaise,
    int? allocatedRemainderPaise,
  }) {
    return BudgetCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      accountId: accountId ?? this.accountId,
      sortOrder: sortOrder ?? this.sortOrder,
      allocationType: allocationType ?? this.allocationType,
      fixedAmountPaise: fixedAmountPaise ?? this.fixedAmountPaise,
      allocatedRemainderPaise: allocatedRemainderPaise ?? this.allocatedRemainderPaise,
    );
  }
}

class MonthlyBudgetSnapshot {
  final String id;
  final String monthKey; // 'YYYY-MM'
  final int salaryPaise;
  final String
  allocationsJson; // Store snapshots of category allocation percentages & amounts
  final DateTime createdAt;

  MonthlyBudgetSnapshot({
    required this.id,
    required this.monthKey,
    required this.salaryPaise,
    required this.allocationsJson,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthKey': monthKey,
      'salaryPaise': salaryPaise,
      'allocationsJson': allocationsJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MonthlyBudgetSnapshot.fromMap(Map<String, dynamic> map) {
    return MonthlyBudgetSnapshot(
      id: map['id'] as String,
      monthKey: map['monthKey'] as String,
      salaryPaise: (map['salaryPaise'] as num).toInt(),
      allocationsJson: map['allocationsJson'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
