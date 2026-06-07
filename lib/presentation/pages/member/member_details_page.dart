import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/member_entity.dart';
import '../../widgets/member_avatar.dart';

class MemberDetailsPage extends StatelessWidget {
  final MemberEntity member;

  const MemberDetailsPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    MemberAvatar(
                      memberId: member.id,
                      photoUrl: member.photoUrl.isNotEmpty ? member.photoUrl : null,
                      initials: member.initials,
                      radius: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      member.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      member.memberId,
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'VERIFIED MEMBER',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('Personal Information', [
              _buildInfoRow(Icons.person, "Father's Name", member.fatherName),
              _buildInfoRow(Icons.person_outline, "Mother's Name",
                  member.motherName),
              _buildInfoRow(Icons.wc, 'Gender', member.gender),
              _buildInfoRow(
                  Icons.cake, 'Date of Birth', member.dateOfBirth),
              _buildInfoRow(
                  Icons.bloodtype, 'Blood Group', member.bloodGroup),
              _buildInfoRow(
                  Icons.badge, 'BVC Reg. No', member.bvcRegNo),
            ]),
            const SizedBox(height: 16),
            _buildSection('Contact Information', [
              _buildInfoRow(Icons.phone, 'Mobile', member.mobile),
              _buildInfoRow(Icons.email, 'Email', member.email),
              _buildInfoRow(Icons.contact_emergency, 'Emergency Contact',
                  member.emergencyContact),
              _buildInfoRow(Icons.home, 'Permanent Address',
                  member.permanentAddress),
              _buildInfoRow(Icons.mail, 'Mailing Address',
                  member.mailingAddress),
            ]),
            const SizedBox(height: 16),
            _buildSection('Professional Information', [
              _buildInfoRow(Icons.school, 'DVM / BSc Institute',
                  member.dvmInstitute),
              _buildInfoRow(Icons.school_outlined, 'MSc',
                  member.msc.isEmpty ? 'N/A' : member.msc),
              _buildInfoRow(Icons.school, 'PhD',
                  member.phd.isEmpty ? 'N/A' : member.phd),
              _buildInfoRow(Icons.work_history, 'Experience',
                  member.experience),
              _buildInfoRow(Icons.medical_information, 'Specialization',
                  member.specialization),
            ]),
            const SizedBox(height: 16),
            _buildSection('Work Information', [
              _buildInfoRow(
                  Icons.work, 'Work Type', member.workType),
              _buildInfoRow(Icons.business, 'Institute / Organization',
                  member.instituteName),
            ]),
            const SizedBox(height: 16),
            _buildSection('Other', [
              _buildInfoRow(
                  Icons.sports_soccer, 'Interests', member.interests),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Container(
        width: double.infinity,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final display = value.isEmpty ? 'N/A' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  display,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
