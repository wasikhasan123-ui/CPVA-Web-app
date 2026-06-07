import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/imgbb_service.dart';
import '../../../data/datasources/payment_remote_datasource.dart';
import '../../../data/models/payment_submission_model.dart';
import '../../blocs/auth/auth_bloc.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  static const String _paymentNumber = '01813059794';
  static const String _renewalAmount = '500';

  String? _selectedMethod;
  final _txIdController = TextEditingController();
  String _paymentScreenshotUrl = '';
  bool _uploadingScreenshot = false;
  bool _submitting = false;

  @override
  void dispose() {
    _txIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    final authUid = user.authUid.isNotEmpty
        ? user.authUid
        : (firebaseUser?.uid ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: StreamBuilder<List<PaymentSubmission>>(
        stream: sl<PaymentRemoteDataSource>().streamPaymentsForUser(authUid),
        builder: (context, snapshot) {
          final latestPayment =
              (snapshot.data != null && snapshot.data!.isNotEmpty)
                  ? snapshot.data!.first
                  : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _feeCard(latestPayment),
                const SizedBox(height: 16),
                const Text(
                  'Pay via',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethod('bKash', Colors.pink),
                _buildPaymentMethod('Nagad', Colors.orange),
                _buildPaymentMethod('Rocket', Colors.purple),
                if (_selectedMethod != null) ...[
                  const SizedBox(height: 16),
                  _submissionCard(user, authUid),
                ],
                if (latestPayment != null) ...[
                  const SizedBox(height: 16),
                  _latestPaymentCard(latestPayment),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _feeCard(PaymentSubmission? latestPayment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.primary.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Annual Renewal Fee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'BDT $_renewalAmount',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Due: 30 June 2026',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusChip(latestPayment?.status ?? 'unpaid'),
          ],
        ),
      ),
    );
  }

  Widget _submissionCard(dynamic user, String authUid) {
    final uploaded = _paymentScreenshotUrl.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit Payment Proof',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send Money to $_paymentNumber via $_selectedMethod, then upload screenshot or enter transaction ID.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _txIdController,
              decoration: const InputDecoration(
                labelText: 'Transaction ID (optional if screenshot uploaded)',
                hintText: 'e.g. 8N5KQR9',
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 12),
            _uploadCard(uploaded),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(user, authUid),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.verified),
                label: Text(
                  _submitting
                      ? 'Submitting...'
                      : 'Submit for Verification',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard(bool uploaded) {
    return InkWell(
      onTap: _uploadingScreenshot ? null : _pickAndUploadScreenshot,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded
              ? AppColors.success.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded
                ? AppColors.success.withValues(alpha: 0.45)
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _uploadingScreenshot
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      uploaded ? Icons.check_circle : Icons.upload_file,
                      color: uploaded ? AppColors.success : AppColors.primary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uploaded
                        ? 'Payment screenshot uploaded'
                        : 'Upload payment screenshot',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    uploaded
                        ? 'Tap to replace screenshot'
                        : 'Tap to choose image. Drag-and-drop style upload area.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (uploaded)
              IconButton(
                tooltip: 'Remove screenshot',
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () {
                  setState(() => _paymentScreenshotUrl = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _latestPaymentCard(PaymentSubmission payment) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Payment Submission',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _infoRow('Amount', 'BDT ${payment.amount}'),
            _infoRow('Method', payment.paymentMethod),
            if (payment.transactionId.isNotEmpty)
              _infoRow('Transaction ID', payment.transactionId),
            _infoRow('Status', payment.status.toUpperCase()),
            if (payment.rejectionReason.isNotEmpty)
              _infoRow('Reason', payment.rejectionReason),
            if (payment.screenshotUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openUrl(payment.screenshotUrl),
                icon: const Icon(Icons.image),
                label: const Text('View Screenshot'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String rawStatus) {
    final status = rawStatus.toLowerCase();

    late Color color;
    late String label;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'Verified';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending Verification';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Rejected';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String name, Color color) {
    final selected = _selectedMethod == name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? color : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.account_balance_wallet, color: color),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Send Money to: $_paymentNumber'),
        trailing: selected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.chevron_right),
        onTap: () => setState(() => _selectedMethod = name),
      ),
    );
  }

  Future<void> _pickAndUploadScreenshot() async {
    if (_uploadingScreenshot) return;

    setState(() => _uploadingScreenshot = true);

    try {
      final url = await sl<ImgbbService>().pickAndUpload();

      if (url == null || url.isEmpty) return;
      if (!mounted) return;

      setState(() => _paymentScreenshotUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment screenshot uploaded'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot upload failed: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingScreenshot = false);
      }
    }
  }

  Future<void> _submit(dynamic user, String authUid) async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select payment method')),
      );
      return;
    }

    final txId = _txIdController.text.trim();

    if (txId.isEmpty && _paymentScreenshotUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter transaction ID or upload screenshot'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (authUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not identify logged-in user. Please login again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch}';

      final payment = PaymentSubmission(
        id: paymentId,
        memberId: user.id,
        memberAuthUid: authUid,
        memberName: user.name,
        memberMobile: user.mobile,
        memberEmail: user.email,
        amount: _renewalAmount,
        paymentMethod: _selectedMethod!,
        transactionId: txId,
        screenshotUrl: _paymentScreenshotUrl,
        type: 'renewal',
        status: 'pending',
        submittedAt: DateTime.now().toIso8601String(),
      );

      await sl<PaymentRemoteDataSource>().submitPayment(payment);

      if (!mounted) return;

      setState(() {
        _txIdController.clear();
        _paymentScreenshotUrl = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted for verification'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment submit failed: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open screenshot'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
