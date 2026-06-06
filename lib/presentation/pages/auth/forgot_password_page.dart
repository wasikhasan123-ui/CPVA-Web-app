import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/email_service.dart';
import '../../blocs/auth/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailSetup() async {
    final isReady = await sl<EmailService>().isReady();
    if (!isReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Email service is not configured yet. Please ask admin to set up EmailJS in Admin Panel > Settings.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email service is configured and ready.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _sendCode() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          PasswordResetRequested(_emailController.text.trim()),
        );
  }

  void _verifyCode() {
    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
          PasswordResetCodeVerified(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
          ),
        );
  }

  void _resetPassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
          PasswordResetCompleted(
            email: _emailController.text.trim(),
            newPassword: _newPasswordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetCodeSent) {
            setState(() => _step = 2);
            if (state.devCode.isNotEmpty) {
              _codeController.text = state.devCode;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Verification code sent to ${state.email}. Check your inbox.'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is AuthPasswordResetCodeVerified) {
            setState(() => _step = 3);
          } else if (state is AuthPasswordResetSuccess) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                icon: const Icon(Icons.check_circle,
                    color: AppColors.success, size: 48),
                title: const Text('Password Reset!'),
                content: const Text(
                    'Your password has been reset successfully. You can now login with your new password.'),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  if (_step == 1) _buildStep1(state),
                  if (_step == 2) _buildStep2(state),
                  if (_step == 3) _buildStep3(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'Email'),
        _stepLine(_step >= 2),
        _stepDot(2, 'Code'),
        _stepLine(_step >= 3),
        _stepDot(3, 'New Password'),
      ],
    );
  }

  Widget _stepDot(int n, String label) {
    final active = _step >= n;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? AppColors.primary : AppColors.border,
          child: active
              ? Text('$n',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildStep1(AuthState state) {
    return Column(
      children: [
        const Icon(Icons.email, size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Enter Your Email',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'We will send a 6-digit verification code to your registered email address.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email, color: AppColors.primary),
            hintText: 'your@email.com',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(v.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: state is AuthLoading ? null : _sendCode,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: state is AuthLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Send Verification Code'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _checkEmailSetup,
          child: const Text('Check email service status'),
        ),
      ],
    );
  }

  Widget _buildStep2(AuthState state) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read, size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Enter Verification Code',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'A 6-digit code was sent to ${_emailController.text.trim()}. Check your inbox and spam folder.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: const InputDecoration(
            labelText: '6-Digit Code',
            counterText: '',
            hintText: '000000',
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: state is AuthLoading ? null : _verifyCode,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: state is AuthLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Verify Code'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: state is AuthLoading
              ? null
              : () => context
                  .read<AuthBloc>()
                  .add(PasswordResetRequested(_emailController.text.trim())),
          child: const Text('Resend Code'),
        ),
      ],
    );
  }

  Widget _buildStep3(AuthState state) {
    return Column(
      children: [
        const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Set New Password',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your new password. Must be at least 6 characters.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureNew = !_obscureNew),
              child: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppColors.primary),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: state is AuthLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: state is AuthLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Reset Password'),
        ),
      ],
    );
  }
}
