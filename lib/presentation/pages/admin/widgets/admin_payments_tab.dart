import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/payment_remote_datasource.dart';
import '../../../../data/models/payment_submission_model.dart';

class AdminPaymentsTab extends StatelessWidget {
  const AdminPaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentSubmission>>(
      stream: sl<PaymentRemoteDataSource>().streamAllPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load payments: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final payments = snapshot.data ?? const <PaymentSubmission>[];

        if (payments.isEmpty) {
          return const Center(
            child: Text('No payment submissions yet'),
          );
        }

        final pending =
            payments.where((p) => p.status == 'pending').toList();
        final reviewed =
            payments.where((p) => p.status != 'pending').toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _sectionTitle('Pending Payments', pending.length),
            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No pending payments'),
              )
            else
              ...pending.map((p) => _PaymentCard(payment: p)),
            const SizedBox(height: 16),
            _sectionTitle('Reviewed Payments', reviewed.length),
            if (reviewed.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No reviewed payments'),
              )
            else
              ...reviewed.map((p) => _PaymentCard(payment: p)),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentSubmission payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (payment.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => Colors.orange,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child:
                      Icon(Icons.payments, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${payment.paymentMethod} • BDT ${payment.amount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(payment.status, statusColor),
              ],
            ),
            const SizedBox(height: 12),
            _row('Mobile', payment.memberMobile),
            _row('Email', payment.memberEmail),
            if (payment.transactionId.isNotEmpty)
              _row('Transaction ID', payment.transactionId),
            _row('Submitted', payment.submittedAt),
            if (payment.rejectionReason.isNotEmpty)
              _row('Reason', payment.rejectionReason),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (payment.screenshotUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openUrl(context, payment.screenshotUrl),
                    icon: const Icon(Icons.image),
                    label: const Text('View Screenshot'),
                  ),
                if (payment.status == 'pending') ...[
                  FilledButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    final label = switch (status) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending',
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Payment?'),
        content: Text(
          'Approve payment from ${payment.memberName} for BDT ${payment.amount}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await sl<PaymentRemoteDataSource>().updateStatus(
      paymentId: payment.id,
      status: 'approved',
      reviewedBy:
          fb_auth.FirebaseAuth.instance.currentUser?.email ?? 'admin',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment approved'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Example: transaction not found',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    await sl<PaymentRemoteDataSource>().updateStatus(
      paymentId: payment.id,
      status: 'rejected',
      reviewedBy:
          fb_auth.FirebaseAuth.instance.currentUser?.email ?? 'admin',
      rejectionReason: reason,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid screenshot URL'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open screenshot'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
