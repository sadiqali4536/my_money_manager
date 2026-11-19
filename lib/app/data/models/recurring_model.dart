enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class RecurringTransactionModel {
  final String id;
  final String title;
  final int amountPaise;
  final String typeName; // 'income', 'expense', 'savings', 'investment'
  final String accountId;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final String? notes;

  RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.amountPaise,
    required this.typeName,
    required this.accountId,
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amountPaise': amountPaise,
      'typeName': typeName,
      'accountId': accountId,
      'frequency': frequency.name,
      'nextDueDate': nextDueDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amountPaise: (map['amountPaise'] as num).toInt(),
      typeName: map['typeName'] as String,
      accountId: map['accountId'] as String,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      nextDueDate: DateTime.parse(map['nextDueDate'] as String),
      isActive: (map['isActive'] as int?) == 1,
      notes: map['notes'] as String?,
    );
  }
}

