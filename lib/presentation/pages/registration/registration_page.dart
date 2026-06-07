import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/registration_remote_datasource.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _bvcRegNoController = TextEditingController();
  final _dvmInstituteController = TextEditingController();
  final _specializationController = TextEditingController();
  final _workTypeController = TextEditingController();
  final _instituteController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentAmountController = TextEditingController(text: '2000');
  final _transactionIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String _gender = '';
  String _bloodGroup = '';
  String _paymentMethod = '';
  bool _submitting = false;

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final _paymentMethods = ['bKash', 'Nagad', 'Rocket'];

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _bvcRegNoController.dispose();
    _dvmInstituteController.dispose();
    _specializationController.dispose();
    _workTypeController.dispose();
    _instituteController.dispose();
    _addressController.dispose();
    _paymentAmountController.dispose();
    _transactionIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);

    fb_auth.User? createdUser;
    bool applicationSubmitted = false;
    Object? verificationError;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final credential =
          await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Could not create Firebase Auth user.');
      }

      final app = MembershipApplication(
        id: 'APP-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: email,
        gender: _gender,
        fatherName: _fatherNameController.text.trim(),
        motherName: _motherNameController.text.trim(),
        bloodGroup: _bloodGroup,
        bvcRegNo: _bvcRegNoController.text.trim(),
        dvmInstitute: _dvmInstituteController.text.trim(),
        specialization: _specializationController.text.trim(),
        workType: _workTypeController.text.trim(),
        instituteName: _instituteController.text.trim(),
        address: _addressController.text.trim(),
        paymentAmount: _paymentAmountController.text.trim(),
        paymentMethod: _paymentMethod,
        transactionId: _transactionIdController.text.trim(),
        password: '',
        authUid: createdUser.uid,
        submittedAt: DateTime.now().toIso8601String(),
      );

      await sl<RegistrationRemoteDataSource>().submitApplication(app);
      applicationSubmitted = true;

      try {
        await createdUser.sendEmailVerification();
      } catch (e) {
        verificationError = e;
      }

      await fb_auth.FirebaseAuth.instance.signOut();

      if (!mounted) return;

      final message = verificationError == null
          ? 'Registration submitted. Please verify your email. Admin will approve your application.'
          : 'Registration submitted, but verification email could not be sent. Please try logging in later and request verification again, or contact admin.';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 48,
          ),
          title: const Text('Application Submitted!'),
          content: Text(message),
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
    } on fb_auth.FirebaseAuthException catch (e) {
      if (!applicationSubmitted && createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_firebaseRegistrationErrorMessage(e)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (!applicationSubmitted && createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
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

  String _firebaseRegistrationErrorMessage(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email already has an account. Please login or use Forgot Password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password signup is not enabled in Firebase.';
      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Membership'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoBanner(),
              const SizedBox(height: 20),
              _buildSection('Personal Information', Icons.person_outline, [
                _field(_nameController, 'Full Name *', Icons.person_outline, _req),
                const SizedBox(height: 12),
                _field(_mobileController, 'Mobile Number *', Icons.phone_outlined,
                    _reqPhone,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _field(_emailController, 'Email *', Icons.email_outlined,
                    _reqEmail,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildPasswordField(
                    _passwordController, 'Password *', _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                    _reqPassword),
                const SizedBox(height: 12),
                _buildPasswordField(
                    _confirmPasswordController,
                    'Confirm Password *',
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                    _reqConfirmPassword),
                const SizedBox(height: 12),
                _field(_fatherNameController, "Father's Name",
                    Icons.person_outline, null),
                const SizedBox(height: 12),
                _field(_motherNameController, "Mother's Name",
                    Icons.person_outline, null),
                const SizedBox(height: 12),
                _buildGenderDropdown(),
                const SizedBox(height: 12),
                _buildBloodGroupDropdown(),
              ]),
              const SizedBox(height: 16),
              _buildSection('Professional Information', Icons.school_outlined, [
                _field(_bvcRegNoController, 'Membership / BVC Reg No *',
                    Icons.badge_outlined, _req),
                const SizedBox(height: 12),
                _field(_dvmInstituteController, 'DVM Institute',
                    Icons.school_outlined, null),
                const SizedBox(height: 12),
                _field(_specializationController, 'Specialization',
                    Icons.science_outlined, null),
                const SizedBox(height: 12),
                _field(_workTypeController, 'Work Type', Icons.work_outline, null),
                const SizedBox(height: 12),
                _field(_instituteController, 'Institute / Clinic Name',
                    Icons.business_outlined, null),
                const SizedBox(height: 12),
                _field(_addressController, 'Address', Icons.location_on_outlined,
                    null,
                    lines: 2),
              ]),
              const SizedBox(height: 16),
              _buildSection('Membership Payment', Icons.payment_outlined, [
                Text(
                  'Membership Fee: BDT 2,000',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                    _paymentAmountController, 'Amount (BDT) *', Icons.money, _req,
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 12),
                _field(_transactionIdController, 'Transaction ID *',
                    Icons.receipt_long_outlined, _req),
                const SizedBox(height: 8),
                _paymentInfoBox(),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting ? 'Submitting...' : 'Submit Application',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String? _req(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _reqPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    if (v.startsWith('+') || v.startsWith('880')) {
      return 'Use 01XXXXXXXXX format (not +880)';
    }
    final clean = v.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length < 11 || !clean.startsWith('01')) {
      return 'Enter a valid 11-digit mobile number';
    }
    return null;
  }

  String? _reqPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _reqEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _reqConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Widget _buildPasswordField(
    TextEditingController ctrl,
    String label,
    bool obscure,
    VoidCallback onToggle,
    String? Function(String?)? validator,
  ) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.03),
              AppColors.primary.withValues(alpha: 0.01),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fill in your details and complete payment. After admin approval you can login with your mobile number.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Send BDT ${_paymentAmountController.text.isEmpty ? "2,000" : _paymentAmountController.text} '
              'to 01813059794 via bKash/Nagad/Rocket and enter the Transaction ID above.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.info.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon,
      String? Function(String?)? validator,
      {TextInputType? keyboard, int lines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _gender.isEmpty ? null : _gender,
      decoration: const InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.wc_outlined, color: AppColors.primary),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (v) => setState(() => _gender = v ?? ''),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _bloodGroup.isEmpty ? null : _bloodGroup,
      decoration: const InputDecoration(
        labelText: 'Blood Group',
        prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.primary),
      ),
      items: _bloodGroups
          .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
          .toList(),
      onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _paymentMethod.isEmpty ? null : _paymentMethod,
      decoration: const InputDecoration(
        labelText: 'Payment Method *',
        prefixIcon:
            Icon(Icons.payment_outlined, color: AppColors.primary),
      ),
      items: _paymentMethods
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) => setState(() => _paymentMethod = v ?? ''),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please select a payment method';
        return null;
      },
    );
  }
}
