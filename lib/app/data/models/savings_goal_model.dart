class SavingsGoalModel {
  final String id;
  final String name;
  final int targetAmountPaise;
  final int currentSavedPaise;
  final DateTime? targetDate;
  final String? accountId;
  final bool isEmergencyFund;
  final String iconKey;
  final int colorValue;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmountPaise,
    this.currentSavedPaise = 0,
    this.targetDate,
    this.accountId,
    this.isEmergencyFund = false,
    this.iconKey = 'savings',
    this.colorValue = 0xFF10B981,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercentage {
    if (targetAmountPaise <= 0) return 0.0;
    final progress = (currentSavedPaise / targetAmountPaise);
    return progress > 1.0 ? 1.0 : (progress < 0 ? 0.0 : progress);
  }

  int get remainingTargetPaise {
    final diff = targetAmountPaise - currentSavedPaise;
    return diff < 0 ? 0 : diff;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmountPaise': targetAmountPaise,
      'currentSavedPaise': currentSavedPaise,
      'targetDate': targetDate?.toIso8601String(),
      'accountId': accountId,
      'isEmergencyFund': isEmergencyFund ? 1 : 0,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmountPaise: (map['targetAmountPaise'] as num).toInt(),
      currentSavedPaise: (map['currentSavedPaise'] as num?)?.toInt() ?? 0,
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate'] as String) : null,
      accountId: map['accountId'] as String?,
      isEmergencyFund: (map['isEmergencyFund'] as int?) == 1,
      iconKey: map['iconKey'] as String? ?? 'savings',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF10B981,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    int? targetAmountPaise,
    int? currentSavedPaise,
    DateTime? targetDate,
    String? accountId,
    bool? isEmergencyFund,
    String? iconKey,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountPaise: targetAmountPaise ?? this.targetAmountPaise,
      currentSavedPaise: currentSavedPaise ?? this.currentSavedPaise,
      targetDate: targetDate ?? this.targetDate,
      accountId: accountId ?? this.accountId,
      isEmergencyFund: isEmergencyFund ?? this.isEmergencyFund,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

