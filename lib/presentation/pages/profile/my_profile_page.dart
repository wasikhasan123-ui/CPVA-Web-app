import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/photo_service.dart';
import '../../../domain/entities/member_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/section_state.dart';
import '../../widgets/member_avatar.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  bool _hasCustom = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _refreshCustomFlag();
  }

  void _refreshCustomFlag() {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return;
    sl<PhotoService>(instanceName: 'member')
        .hasCustomPhoto(state.user.id)
        .then((v) {
      if (mounted) {
        setState(() {
          _hasCustom = v;
          _checking = false;
        });
      }
    });
  }

  Future<void> _onChangePhoto(MemberEntity member) async {
    final src = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSourceChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSourceChoice.camera),
            ),
            if (_hasCustom)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  'Remove my custom photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, ImageSourceChoice.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    final svc = sl<PhotoService>(instanceName: 'member');
    try {
      if (src == ImageSourceChoice.remove) {
        await svc.removeCustomPhoto(member.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom photo removed')),
          );
        }
      } else if (src == ImageSourceChoice.gallery) {
        await svc.pickFromGallery(ownerId: member.id);
      } else {
        await svc.takePhoto(ownerId: member.id);
      }
      _refreshCustomFlag();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const LoadingState();
          }
          final member = state.user;
          return RefreshIndicator(
            onRefresh: () async => _refreshCustomFlag(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(member),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Personal Information',
                    Icons.person,
                    [
                      _buildRow('Full Name', member.name),
                      _buildRow("Father's Name", member.fatherName),
                      _buildRow("Mother's Name", member.motherName),
                      _buildRow('Gender', member.gender),
                      _buildRow('Date of Birth', member.dateOfBirth),
                      _buildRow('Blood Group', member.bloodGroup),
                      _buildRow('BVC Reg. No', member.bvcRegNo),
                      _buildRow('Member ID', member.memberId),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Contact Information',
                    Icons.contact_phone,
                    [
                      _buildRow('Mobile', member.mobile),
                      _buildRow('Email', member.email),
                      _buildRow('Emergency Contact',
                          member.emergencyContact.isEmpty
                              ? 'N/A'
                              : member.emergencyContact),
                      _buildRow('Permanent Address', member.permanentAddress),
                      _buildRow('Mailing Address', member.mailingAddress),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Professional Information',
                    Icons.school,
                    [
                      _buildRow('DVM / BSc Institute', member.dvmInstitute),
                      _buildRow('MSc', member.msc.isEmpty ? 'N/A' : member.msc),
                      _buildRow('PhD', member.phd.isEmpty ? 'N/A' : member.phd),
                      _buildRow('Experience', member.experience),
                      _buildRow('Specialization', member.specialization),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Work Information',
                    Icons.work,
                    [
                      _buildRow('Work Type', member.workType),
                      _buildRow('Institute/Organization', member.instituteName),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Documents',
                    Icons.description,
                    [
                      _buildDocRow(
                        'Profile Photo',
                        member.photoUrl,
                        context,
                      ),
                      _buildDocRow(
                        'BVC License',
                        member.licenseUrl,
                        context,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Interests',
                    Icons.sports_soccer,
                    [
                      _buildRow('Games/Hobbies', member.interests),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/change-password');
                      },
                      icon: const Icon(Icons.lock_reset,
                          color: AppColors.primary),
                      label: const Text(
                        'Change Password',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(const LogoutRequested());
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(MemberEntity member) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _checking ? null : () => _onChangePhoto(member),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MemberAvatar(
                    memberId: member.id,
                    photoUrl: member.photoUrl,
                    initials: member.initials,
                    radius: 50,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasCustom ? Icons.edit : Icons.camera_alt,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasCustom
                  ? 'Your custom photo is shown here'
                  : 'Tap the camera icon to add your photo',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.memberId,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'VERIFIED MEMBER',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocRow(String label, String url, BuildContext context) {
    final hasUrl = url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: hasUrl
                ? InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(label),
                          content: SelectableText(url),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.link, color: AppColors.primary, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'View Document',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text(
                    'N/A',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

enum ImageSourceChoice { gallery, camera, remove }
