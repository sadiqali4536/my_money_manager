import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/financial_controller.dart';
import '../../data/models/recurring_model.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  final FinancialController controller = Get.find<FinancialController>();

  RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Bills & Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Recurring Rule',
            onPressed: () => _showAddRecurringDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = controller.recurringTransactions;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_repeat_rounded, size: 54, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No recurring rules or reminders set up yet.',
                    style: TextStyle(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddRecurringDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Rule (e.g. Rent, Electricity, SIP)'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final rec = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(rec.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rec.frequency.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount: ${CurrencyHelper.formatPaise(rec.amountPaise)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          'Next Due: ${DateHelper.formatDate(rec.nextDueDate)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => controller.deleteRecurring(rec.id),
                          child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                          onPressed: () async {
                            await controller.executeRecurringTransaction(rec);
                            Get.snackbar(
                              'Payment Executed',
                              '${rec.title} of ${CurrencyHelper.formatPaise(rec.amountPaise)} recorded into transactions.',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: AppColors.success,
                              colorText: Colors.white,
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Record as Paid', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddRecurringDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String typeName = 'expense';
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly;
    String? accountId = controller.accountSummaries.isNotEmpty ? controller.accountSummaries.first.account.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Recurring Bill / Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Bill / Transaction Title', hintText: 'e.g. House Rent, WiFi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: RecurrenceFrequency.values
                        .map((f) => DropdownMenuItem(value: f, child: Text(f.name.capitalizeFirst!)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => frequency = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: accountId,
                    decoration: const InputDecoration(labelText: 'Envelope Account'),
                    items: controller.accountSummaries.map((s) {
                      return DropdownMenuItem(value: s.account.id, child: Text(s.account.name));
                    }).toList(),
                    onChanged: (val) => accountId = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final rupees = double.tryParse(amountCtrl.text) ?? 0.0;
                  if (titleCtrl.text.trim().isNotEmpty && rupees > 0 && accountId != null) {
                    controller.addRecurringTransaction(
                      title: titleCtrl.text.trim(),
                      amountPaise: CurrencyHelper.rupeesToPaise(rupees),
                      typeName: typeName,
                      accountId: accountId!,
                      frequency: frequency,
                      nextDueDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create Rule'),
              ),
            ],
          );
        },
      ),
    );
  }
}

