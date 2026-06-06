import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/email_service.dart';

class EmailSettingsPage extends StatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  State<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends State<EmailSettingsPage> {
  final _serviceIdController = TextEditingController();
  final _templateIdController = TextEditingController();
  final _publicKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _loading = true;
  bool _saving = false;
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serviceIdController.dispose();
    _templateIdController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final service = sl<EmailService>();
    final serviceId = await service.getServiceId() ?? '';
    final templateId = await service.getTemplateId() ?? '';
    final publicKey = await service.getPublicKey() ?? '';
    setState(() {
      _serviceIdController.text = serviceId;
      _templateIdController.text = templateId;
      _publicKeyController.text = publicKey;
      _configured = serviceId.isNotEmpty &&
          templateId.isNotEmpty &&
          publicKey.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_serviceIdController.text.trim().isEmpty ||
        _templateIdController.text.trim().isEmpty ||
        _publicKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All three fields are required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final service = sl<EmailService>();
      await service.setServiceId(_serviceIdController.text.trim());
      await service.setTemplateId(_templateIdController.text.trim());
      await service.setPublicKey(_publicKeyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email service settings saved!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _configured = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Settings?'),
        content: const Text(
            'This will remove all EmailJS configuration. You can re-enter them later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    final service = sl<EmailService>();
    await service.setServiceId('');
    await service.setTemplateId('');
    await service.setPublicKey('');
    setState(() {
      _serviceIdController.text = '';
      _templateIdController.text = '';
      _publicKeyController.text = '';
      _configured = false;
      _saving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All settings cleared'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _testEmail() async {
    final testController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Test Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter an email address to send a test verification code:'),
            const SizedBox(height: 12),
            TextField(
              controller: testController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Test Email',
                prefixIcon: Icon(Icons.email),
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
            child: const Text('Send Test'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (testController.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      await sl<EmailService>().sendVerificationCode(
        toEmail: testController.text.trim(),
        code: '123456',
        memberName: 'Test User',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test email sent to ${testController.text}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Service Settings'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _configured
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _configured ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _configured ? Icons.check_circle : Icons.warning,
                          color: _configured ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _configured
                                ? 'Email service is configured and ready.'
                                : 'Email service not configured. Set up below to enable password reset emails.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'EmailJS Configuration',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Get these from emailjs.com (free account, 200 emails/month)',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _serviceIdController,
                    decoration: const InputDecoration(
                      labelText: 'Service ID',
                      prefixIcon:
                          Icon(Icons.cloud, color: AppColors.primary),
                      hintText: 'e.g. service_abc123',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _templateIdController,
                    decoration: const InputDecoration(
                      labelText: 'Template ID',
                      prefixIcon:
                          Icon(Icons.description, color: AppColors.primary),
                      hintText: 'e.g. template_xyz789',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _publicKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'Public Key',
                      prefixIcon:
                          const Icon(Icons.key, color: AppColors.primary),
                      hintText: 'Account → API Keys in emailjs.com',
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscureKey = !_obscureKey),
                        child: Icon(
                          _obscureKey
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _saving || !_configured ? null : _testEmail,
                          icon: const Icon(Icons.send),
                          label: const Text('Send Test Email'),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _clearAll,
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: AppColors.error,
                          side:
                              const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to set up EmailJS:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue),
                        ),
                        SizedBox(height: 8),
                        Text('1. Sign up free at emailjs.com',
                            style: TextStyle(fontSize: 12)),
                        Text(
                            '2. Email Services → Add New Service → connect Gmail/Outlook',
                            style: TextStyle(fontSize: 12)),
                        SizedBox(height: 6),
                        Text(
                          '3. Email Templates → Create New Template:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                            '   • "To Email" field: type {{to_email}} (or {{email}})',
                            style: TextStyle(fontSize: 12)),
                        Text(
                            '   • Subject: CPVA Password Reset Code',
                            style: TextStyle(fontSize: 12)),
                        Text(
                            '   • Body: Your code is {{code}}',
                            style: TextStyle(fontSize: 12)),
                        SizedBox(height: 4),
                        Text(
                            '4. Account → API Keys → copy your Public Key',
                            style: TextStyle(fontSize: 12)),
                        Text(
                            '5. Paste all 3 IDs above and Save',
                            style: TextStyle(fontSize: 12)),
                        SizedBox(height: 8),
                        Text(
                          'Free tier: 200 emails/month. No domain verification needed.',
                          style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
