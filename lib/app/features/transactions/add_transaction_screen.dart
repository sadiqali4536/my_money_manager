import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  final String? targetAccountId;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.targetAccountId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final FinancialController controller = Get.find<FinancialController>();

  late TransactionType _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _sourceAccountId;
  String? _destinationAccountId;
  String _paymentMethod = 'UPI';
  DateTime _transactionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;

    if (controller.accountSummaries.isNotEmpty) {
      if (widget.targetAccountId != null) {
        if (_selectedType == TransactionType.expense || _selectedType == TransactionType.transfer) {
          _sourceAccountId = widget.targetAccountId;
          final otherAcc = controller.accountSummaries
              .firstWhereOrNull((AccountLedgerSummary a) => a.account.id != widget.targetAccountId);
          _destinationAccountId = otherAcc?.account.id;
        } else {
          _destinationAccountId = widget.targetAccountId;
        }
      } else {
        _sourceAccountId = controller.accountSummaries.first.account.id;
        if (controller.accountSummaries.length > 1) {
          _destinationAccountId = controller.accountSummaries[1].account.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Selector Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip(TransactionType.expense, 'Expense', AppColors.expense),
                  _buildTypeChip(TransactionType.addMoney, 'Add Money', AppColors.secondary),
                  _buildTypeChip(TransactionType.additionalIncome, 'Income', AppColors.success),
                  _buildTypeChip(TransactionType.transfer, 'Transfer', AppColors.info),
                  _buildTypeChip(TransactionType.refund, 'Refund', AppColors.neutral),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transaction Amount', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _getTypeColor(),
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _getTypeColor(),
                      ),
                      hintText: '0.00',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transaction Details Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Paid For',
                hintText: 'e.g. Grocery store, Petrol, Salary bonus',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),

            const SizedBox(height: 12),

            // Account Selection Logic based on Type
            if (_selectedType == TransactionType.expense || _selectedType == TransactionType.transfer) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _sourceAccountId,
                decoration: const InputDecoration(
                  labelText: 'From Account (Envelope)',
                  prefixIcon: Icon(Icons.outbox_rounded),
                ),
                items: controller.accountSummaries.map((AccountLedgerSummary s) {
                  return DropdownMenuItem<String>(
                    value: s.account.id,
                    child: Text(
                      '${s.account.name} (Bal: ${CurrencyHelper.formatPaise(s.currentBalancePaise, hideDecimals: true)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _sourceAccountId = val),
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedType == TransactionType.transfer ||
                _selectedType == TransactionType.addMoney ||
                _selectedType == TransactionType.additionalIncome ||
                _selectedType == TransactionType.refund) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _destinationAccountId,
                decoration: InputDecoration(
                  labelText: _selectedType == TransactionType.transfer ? 'To Account' : 'Credit Into Account',
                  prefixIcon: const Icon(Icons.move_to_inbox_rounded),
                ),
                items: controller.accountSummaries.map((AccountLedgerSummary s) {
                  return DropdownMenuItem<String>(
                    value: s.account.id,
                    child: Text(
                      s.account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _destinationAccountId = val),
              ),
              const SizedBox(height: 12),
            ],

            // Payment Mode & Date Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      prefixIcon: Icon(Icons.payment_rounded),
                    ),
                    items: ['UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Cash']
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _paymentMethod = val ?? 'UPI'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickTransactionDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        DateHelper.formatDate(_transactionDate),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Notes / Remarks (Optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _getTypeColor()),
                onPressed: _saveTransaction,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: const Text('Save Transaction & Update Balances', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(TransactionType type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: color.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: isSelected ? color : AppColors.textSecondaryLight,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(color: isSelected ? color : AppColors.dividerLight),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedType = type);
          }
        },
      ),
    );
  }

  Color _getTypeColor() {
    switch (_selectedType) {
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.addMoney:
        return AppColors.secondary;
      case TransactionType.additionalIncome:
      case TransactionType.refund:
        return AppColors.success;
      case TransactionType.transfer:
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _pickTransactionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    final amountRupees = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amountRupees <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount greater than ₹0.',
          snackPosition: SnackPosition.TOP);
      return;
    }

    final title = _titleController.text.trim().isEmpty ? _selectedType.nameString : _titleController.text.trim();
    final amountPaise = CurrencyHelper.rupeesToPaise(amountRupees);

    // Overdraft check for expense
    if (_selectedType == TransactionType.expense && _sourceAccountId != null) {
      final srcSummary = controller.accountSummaries
          .firstWhereOrNull((AccountLedgerSummary s) => s.account.id == _sourceAccountId);
      if (srcSummary != null && amountPaise > srcSummary.currentBalancePaise) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Budget Overdraft Warning'),
            content: Text(
                'This expense of ${CurrencyHelper.formatPaise(amountPaise)} exceeds the available envelope balance of ${CurrencyHelper.formatPaise(srcSummary.currentBalancePaise)}.\n\nDo you want to proceed with negative envelope balance?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Allow Overdraft'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    try {
      await controller.addTransaction(
        type: _selectedType,
        amountPaise: amountPaise,
        sourceAccountId: _sourceAccountId,
        destinationAccountId: _destinationAccountId,
        title: title,
        description: _descController.text.trim(),
        paymentMethod: _paymentMethod,
        transactionDate: _transactionDate,
      );

      Get.snackbar(
        'Transaction Recorded',
        'Account balances updated successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Get.snackbar(
        'Error Saving Transaction',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.expense,
        colorText: Colors.white,
      );
    }
  }
}
