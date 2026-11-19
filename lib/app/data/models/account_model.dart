import 'package:flutter/material.dart';

class AccountModel {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final int openingBalancePaise;
  final bool isDefault;
  final int sortOrder;

  AccountModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.openingBalancePaise = 0,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'openingBalancePaise': openingBalancePaise,
      'isDefault': isDefault ? 1 : 0,
      'sortOrder': sortOrder,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconKey: map['iconKey'] as String,
      colorValue: (map['colorValue'] as num).toInt(),
      openingBalancePaise: (map['openingBalancePaise'] as num?)?.toInt() ?? 0,
      isDefault: (map['isDefault'] as int?) == 1,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    int? openingBalancePaise,
    bool? isDefault,
    int? sortOrder,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  IconData get iconData {
    switch (iconKey) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'movie':
        return Icons.movie_filter_rounded;
      case 'more_horiz':
        return Icons.layers_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color => Color(colorValue);
}

class AccountLedgerSummary {
  final AccountModel account;
  final int openingBalancePaise;
  final int allocatedPaise;
  final int additionalAddedPaise;
  final int creditsPaise;
  final int expensesPaise;
  final int transfersReceivedPaise;
  final int transfersSentPaise;
  final int adjustmentsPaise;
  final int currentBalancePaise;

  AccountLedgerSummary({
    required this.account,
    required this.openingBalancePaise,
    required this.allocatedPaise,
    required this.additionalAddedPaise,
    required this.creditsPaise,
    required this.expensesPaise,
    required this.transfersReceivedPaise,
    required this.transfersSentPaise,
    required this.adjustmentsPaise,
    required this.currentBalancePaise,
  });

  /// Current Balance = Opening + Allocated + AdditionalAdded + Credits + TransfersReceived - Expenses - TransfersSent + Adjustments
}

