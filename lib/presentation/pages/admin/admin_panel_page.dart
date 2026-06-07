import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/imgbb_service.dart';
import '../../../data/datasources/member_remote_datasource.dart';
import '../../../data/datasources/registration_remote_datasource.dart';
import '../../../data/datasources/remote/firestore_service.dart';
import '../../../data/datasources/remote/password_service.dart';
import '../../../data/datasources/remote/remote_content_datasource.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'services/member_csv_importer.dart';
import 'widgets/admin_dashboard_tab.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RegistrationRemoteDataSource get _dataSource =>
      sl<RegistrationRemoteDataSource>();
  List<MembershipApplication> _pending = [];
  List<MembershipApplication> _processed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    final pending = await _dataSource.getPendingApplications();
    final all = await _dataSource.getAllApplications();
    final processed =
        all.where((a) => a.status != 'pending').toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    setState(() {
      _pending = pending;
      _processed = processed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: [
            const Tab(
              icon: Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pending.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Processed'),
            const Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                AdminDashboardTab(
                  onRefresh: _loadApplications,
                ),
                _pending.isEmpty
                    ? _buildEmptyState(
                        Icons.inbox, 'No Pending Applications',
                        'New membership applications will appear here.')
                    : RefreshIndicator(
                        onRefresh: _loadApplications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pending.length,
                          itemBuilder: (context, i) =>
                              _buildPendingCard(_pending[i]),
                        ),
                      ),
                _processed.isEmpty
                    ? _buildEmptyState(
                        Icons.check_circle_outline, 'No Processed Applications',
                        'Approved/rejected applications will appear here.')
                    : RefreshIndicator(
                        onRefresh: _loadApplications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _processed.length,
                          itemBuilder: (context, i) =>
                              _buildProcessedCard(_processed[i]),
                        ),
                      ),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading:
                const Icon(Icons.email, color: AppColors.primary, size: 32),
            title: const Text('Email Service Settings',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Configure Resend.com to send password reset emails'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/admin/email-settings'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('About Resend',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Resend.com is a free email API service. Sign up at resend.com to get a free API key (100 emails/day free tier). The email service is used to send 6-digit password reset codes to members.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.phone_android,
                color: AppColors.primary, size: 32),
            title: const Text('Fix Mobile Numbers (One-time)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Convert +880XXXXXXXXXX mobiles to 01XXXXXXXXXX format'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _fixMobileNumbers,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.cloud,
                color: Colors.blue, size: 32),
            title: const Text('Imgbb API Key',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Required to upload photos to gallery. Get free key at api.imgbb.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _setImgbbApiKey,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.upload_file,
                color: Colors.green, size: 32),
            title: const Text('Import from Spreadsheet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Bulk-add members from a CSV file (admin only)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _importFromCsv,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.restore,
              color: AppColors.error,
              size: 32,
            ),
            title: const Text(
              'Restore Original Members',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Recover old member directory and profile photos from bundled app data',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _restoreOriginalMembers,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.delete_forever,
                color: AppColors.error, size: 32),
            title: const Text('Delete All Members',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.error)),
            subtitle: const Text(
                'Permanently delete every member and their password. Use before re-importing the full CSV.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _deleteAllMembers,
          ),
        ),
      ],
    );
  }

  Future<void> _setImgbbApiKey() async {
    final currentKey = await sl<ImgbbService>().getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Imgbb API Key'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Get a free API key from https://api.imgbb.com (no credit card needed).',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Key is stored locally on this device only.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await sl<ImgbbService>().setApiKey(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imgbb API key saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _importFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes!;
    final content = utf8.decode(bytes);
    if (content.trim().isEmpty) return;

    final importResult = await MemberCsvImporter().import(content);
    final imported = importResult.imported;

    print(
      'CSV import finished. Imported: ${importResult.imported}, skipped existing: ${importResult.skippedExisting}, skipped invalid: ${importResult.skippedInvalid}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $imported members'),
          backgroundColor:
              imported > 0 ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteAllMembers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Delete ALL members?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This permanently removes every member document and every password.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Type DELETE in capital letters to confirm.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                if (controller.text.trim() == 'DELETE') {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final firestore = sl<FirestoreService>();
    final passwordService = sl<PasswordService>();

    int deleted = 0;
    int failed = 0;
    String? errorMessage;

    try {
      final docs = await firestore.getCollection('members');
      print('DeleteAll: found ${docs.length} members');
      for (final doc in docs) {
        final id = doc['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        try {
          await firestore.deleteDocument('members', id);
          try {
            await passwordService.deletePassword(id);
          } catch (_) {}
          deleted++;
        } catch (e) {
          failed++;
          print('DeleteAll: failed to delete $id: $e');
        }
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Deleted $deleted members${failed > 0 ? ' ($failed failed)' : ''}',
          ),
          backgroundColor: errorMessage == null && failed == 0
              ? AppColors.success
              : AppColors.error,
        ),
      );
    }
  }

  Future<void> _restoreOriginalMembers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Original Members?'),
        content: const Text(
          'This will delete the current cloud member directory and restore the original members from assets/data/members.json.\n\n'
          'Use this to recover from a bad CSV import. Old profile image URLs from the bundled data will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Restoring original members...'),
        duration: Duration(minutes: 5),
      ),
    );

    try {
      await sl<MemberRemoteDataSource>().resetAdminChanges();

      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Original members restored successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _fixMobileNumbers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fix Mobile Numbers?'),
        content: const Text(
          'This will update any member mobiles in the +880XXXXXXXXXX format to 01XXXXXXXXXX in the cloud database. Run this once if you have legacy data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run Fix'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final fixes = {
      '+8801714367786': '01714367786',
      '+8801639053165': '01639053165',
    };

    if (!mounted) return;
    setState(() => _loading = true);

    int updated = 0;
    final firestore = sl<FirestoreService>();
    for (final entry in fixes.entries) {
      try {
        final remote = await firestore.getCollection('members');
        for (final doc in remote) {
          if (doc['mobile']?.toString() == entry.key) {
            await firestore.updateDocument('members', doc['id'].toString(), {
              'mobile': entry.value,
            });
            updated++;
          }
        }
      } catch (e) {
        // ignore
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated $updated member mobile number(s) in cloud.'),
        backgroundColor: updated > 0 ? AppColors.success : AppColors.warning,
      ),
    );
  }

  Future<void> _reseedGallery() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-seed Gallery?'),
        content: const Text(
          'This will DELETE all current gallery items in the cloud and re-upload from the bundled default data. '
          'Use this if delete is not working. Any photos you added manually will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Re-seed'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      await sl<RemoteContentDataSource>(instanceName: 'gallery')
          .forceReseedFromJson('gallery', 'gallery');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery re-seeded. Refresh Gallery page.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-seed failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPendingCard(MembershipApplication app) {
    final date = _fmtDate(app.submittedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Mobile: ${app.mobile}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      if (app.bvcRegNo.isNotEmpty)
                        Text('Reg No: ${app.bvcRegNo}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pending',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Gender', app.gender),
                  _detailRow('DVM Institute', app.dvmInstitute),
                  _detailRow('Specialization', app.specialization),
                  _detailRow('Work Type', app.workType),
                  _detailRow('Institute', app.instituteName),
                  _detailRow('Blood Group', app.bloodGroup),
                  _detailRow('Address', app.address),
                  _detailRow('Submitted', date),
                  if (app.paymentMethod.isNotEmpty) ...[
                    const Divider(height: 12),
                    _detailRow('Payment', 'BDT ${app.paymentAmount}'),
                    _detailRow('Method', app.paymentMethod),
                    _detailRow('Trans ID', app.transactionId),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDetails(app),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectApp(app),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveApp(app),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessedCard(MembershipApplication app) {
    final isApproved = app.status == 'approved';
    final statusColor = isApproved ? Colors.green : AppColors.error;
    final statusLabel = isApproved ? 'Approved' : 'Rejected';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      Text('Mobile: ${app.mobile}',
                          style: const TextStyle(fontSize: 12)),
                      if (app.bvcRegNo.isNotEmpty)
                        Text('Reg No: ${app.bvcRegNo}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor)),
                      if (app.rejectionReason != null &&
                          app.rejectionReason!.isNotEmpty)
                        Text('Reason: ${app.rejectionReason}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.error)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
              ],
            ),
            if (isApproved) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _resetMemberPassword(app),
                    icon: const Icon(Icons.key, size: 16, color: Colors.orange),
                    label: const Text('Reset Password',
                        style: TextStyle(color: Colors.orange)),
                  ),
                  IconButton(
                    onPressed: () => _deleteProcessed(app),
                    icon: const Icon(Icons.delete, color: AppColors.error, size: 18),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resetMemberPassword(MembershipApplication app) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reset Member Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Member: ${app.name}'),
              Text('Mobile: ${app.mobile}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => obscureNew = !obscureNew),
                    child: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                    child: Icon(
                      obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final result = await sl<AuthRepository>().setPasswordForMember(
            app.id,
            newPasswordController.text,
          );
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Password reset for ${app.name}. They can now login with the new password.'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }

  Future<void> _deleteProcessed(MembershipApplication app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text('Remove ${app.name} from processed list permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _dataSource.deleteApplication(app.id);
      await _loadApplications();
    }
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy, hh:mm a').format(d);
    } catch (_) {
      return iso;
    }
  }

  void _viewDetails(MembershipApplication app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(app.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pending Application',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange)),
                ),
                const SizedBox(height: 20),
                _buildDetailSection('Personal Information', [
                  _detailFullRow('Full Name', app.name),
                  _detailFullRow('Mobile', app.mobile),
                  _detailFullRow('Email', app.email),
                  _detailFullRow('Gender', app.gender),
                  _detailFullRow("Father's Name", app.fatherName),
                  _detailFullRow("Mother's Name", app.motherName),
                  _detailFullRow('Blood Group', app.bloodGroup),
                  _detailFullRow('Address', app.address),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('Membership', [
                  _detailFullRow('BVC Reg No', app.bvcRegNo),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('Professional Information', [
                  _detailFullRow('DVM Institute', app.dvmInstitute),
                  _detailFullRow('Specialization', app.specialization),
                  _detailFullRow('Work Type', app.workType),
                  _detailFullRow('Institute Name', app.instituteName),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('Payment Information', [
                  _detailFullRow('Amount', 'BDT ${app.paymentAmount}'),
                  _detailFullRow('Method', app.paymentMethod),
                  _detailFullRow('Transaction ID', app.transactionId),
                ]),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectApp(app);
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveApp(app);
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _detailFullRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveApp(MembershipApplication app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${app.name}'),
            Text('Mobile: ${app.mobile}'),
            if (app.bvcRegNo.isNotEmpty) Text('Reg No: ${app.bvcRegNo}'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment:',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('BDT ${app.paymentAmount} via ${app.paymentMethod}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Transaction ID: ${app.transactionId}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataSource.approveApplication(app.id);
      await _createMemberFromApplication(app);
      if (app.password.isNotEmpty) {
        await sl<AuthRepository>().setPasswordForMember(
          _memberDocId(app),
          app.password,
        );
      }
      await _loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${app.name} approved and added as member! They can now login.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  String _memberDocId(MembershipApplication app) {
    return app.mobile.trim().replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> _createMemberFromApplication(MembershipApplication app) async {
    try {
      final docId = _memberDocId(app);
      final firestore = sl<FirestoreService>();
      final memberData = {
        'id': docId,
        'name': app.name,
        'nameBn': '',
        'fatherName': app.fatherName,
        'motherName': app.motherName,
        'gender': app.gender,
        'permanentAddress': app.address,
        'mailingAddress': app.address,
        'mobile': app.mobile,
        'email': app.email,
        'emergencyContact': '',
        'bvcRegNo': app.bvcRegNo,
        'dateOfBirth': '',
        'bloodGroup': app.bloodGroup,
        'dvmInstitute': app.dvmInstitute,
        'msc': '',
        'phd': '',
        'experience': '',
        'specialization': app.specialization,
        'workType': app.workType,
        'instituteName': app.instituteName,
        'interests': '',
        'photoUrl': '',
        'licenseUrl': '',
        'password': '',
        'joinedAt': DateTime.now().toIso8601String(),
      };
      await firestore.setDocument('members', docId, memberData);
    } catch (e) {
      // ignore - app may not be running on web
    }
  }

  Future<void> _rejectApp(MembershipApplication app) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${app.name}'),
            Text('Mobile: ${app.mobile}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataSource.rejectApplication(
          app.id, reasonController.text.trim());
      await _loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${app.name} application rejected.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
