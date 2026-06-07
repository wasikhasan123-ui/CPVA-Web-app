import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  String? _selectedMethod;
  final _txIdController = TextEditingController();
  String _status = 'Unpaid';

  @override
  void dispose() {
    _txIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Annual Renewal Fee',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'BDT 500',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: 30 June 2026',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusChip(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pay via',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethod('bKash', '01813059794', Colors.pink),
            _buildPaymentMethod('Nagad', '01813059794', Colors.orange),
            _buildPaymentMethod('Rocket', '01813059794', Colors.purple),
            if (_selectedMethod != null) ...[
              const SizedBox(height: 16),
              const Text(
                'After payment, submit your transaction details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _txIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  hintText: 'e.g. 8N5KQR9',
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Screenshot upload coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.upload),
                label: const Text('Upload Payment Screenshot'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit for Verification'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Verified':
        color = AppColors.success;
        break;
      case 'Pending Verification':
        color = Colors.orange;
        break;
      case 'Rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String name, String number, Color color) {
    final selected = _selectedMethod == name;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? color : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.account_balance_wallet, color: color),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Send Money to: $number'),
        trailing: selected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.chevron_right),
        onTap: () => setState(() => _selectedMethod = name),
      ),
    );
  }

  void _submit() {
    if (_txIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter transaction ID')),
      );
      return;
    }
    setState(() => _status = 'Pending Verification');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submitted for verification'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
