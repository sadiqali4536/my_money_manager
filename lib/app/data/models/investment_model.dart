enum InvestmentType {
  mutualFund,
  sip,
  fixedDeposit,
  recurringDeposit,
  stocks,
  gold,
  other,
}

extension InvestmentTypeExtension on InvestmentType {
  String get displayName {
    switch (this) {
      case InvestmentType.mutualFund:
        return 'Mutual Fund (Lump Sum)';
      case InvestmentType.sip:
        return 'Systematic Investment (SIP)';
      case InvestmentType.fixedDeposit:
        return 'Fixed Deposit (FD)';
      case InvestmentType.recurringDeposit:
        return 'Recurring Deposit (RD)';
      case InvestmentType.stocks:
        return 'Stocks / Equities';
      case InvestmentType.gold:
        return 'Gold / Sovereign Gold';
      case InvestmentType.other:
        return 'Other Investment';
    }
  }
}

class InvestmentModel {
  final String id;
  final String name;
  final InvestmentType type;
  final int totalInvestedPaise;
  final int currentValuePaise; // Manually updated valuation
  final DateTime startDate;
  final String? notes;
  final String? accountId;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.totalInvestedPaise,
    required this.currentValuePaise,
    required this.startDate,
    this.notes,
    this.accountId,
  });

  int get profitLossPaise => currentValuePaise - totalInvestedPaise;

  double get returnPercentage {
    if (totalInvestedPaise <= 0) return 0.0;
    return (profitLossPaise / totalInvestedPaise) * 100.0;
  }

  bool get isProfitable => profitLossPaise >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'totalInvestedPaise': totalInvestedPaise,
      'currentValuePaise': currentValuePaise,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
      'accountId': accountId,
    };
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: InvestmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvestmentType.mutualFund,
      ),
      totalInvestedPaise: (map['totalInvestedPaise'] as num).toInt(),
      currentValuePaise: (map['currentValuePaise'] as num).toInt(),
      startDate: DateTime.parse(map['startDate'] as String),
      notes: map['notes'] as String?,
      accountId: map['accountId'] as String?,
    );
  }

  InvestmentModel copyWith({
    String? id,
    String? name,
    InvestmentType? type,
    int? totalInvestedPaise,
    int? currentValuePaise,
    DateTime? startDate,
    String? notes,
    String? accountId,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      totalInvestedPaise: totalInvestedPaise ?? this.totalInvestedPaise,
      currentValuePaise: currentValuePaise ?? this.currentValuePaise,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
    );
  }
}

