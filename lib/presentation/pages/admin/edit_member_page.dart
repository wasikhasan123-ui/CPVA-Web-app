import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/member_remote_datasource.dart';
import '../../../data/models/member_model.dart';
import '../../../domain/entities/member_entity.dart';

class EditMemberPage extends StatefulWidget {
  final MemberEntity? member;

  const EditMemberPage({super.key, this.member});

  @override
  State<EditMemberPage> createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctrls = {};

  static const _fields = <String, String>{
    'name': 'Full Name *',
    'fatherName': "Father's Name",
    'motherName': "Mother's Name",
    'gender': 'Gender',
    'permanentAddress': 'Permanent Address',
    'mailingAddress': 'Mailing Address',
    'mobile': 'Mobile *',
    'email': 'Email',
    'emergencyContact': 'Emergency Contact',
    'bvcRegNo': 'BVC Reg. No',
    'dateOfBirth': 'Date of Birth (DD/MM/YYYY)',
    'bloodGroup': 'Blood Group',
    'dvmInstitute': 'DVM / BSc Institute',
    'msc': 'MSc (Subject/Institute)',
    'phd': 'PhD (Institute)',
    'experience': 'Experience (years)',
    'specialization': 'Specialization',
    'workType': 'Work Type',
    'instituteName': 'Institute / Organization',
    'interests': 'Interests',
    'photoUrl': 'Photo URL',
    'licenseUrl': 'BVC License URL',
  };

  @override
  void initState() {
    super.initState();
    for (final key in _fields.keys) {
      _ctrls[key] = TextEditingController(
        text: _getInitialValue(key) ?? '',
      );
    }
  }

  String? _getInitialValue(String key) {
    if (widget.member == null) return null;
    switch (key) {
      case 'name':
        return widget.member!.name;
      case 'fatherName':
        return widget.member!.fatherName;
      case 'motherName':
        return widget.member!.motherName;
      case 'gender':
        return widget.member!.gender;
      case 'permanentAddress':
        return widget.member!.permanentAddress;
      case 'mailingAddress':
        return widget.member!.mailingAddress;
      case 'mobile':
        return widget.member!.mobile;
      case 'email':
        return widget.member!.email;
      case 'emergencyContact':
        return widget.member!.emergencyContact;
      case 'bvcRegNo':
        return widget.member!.bvcRegNo;
      case 'dateOfBirth':
        return widget.member!.dateOfBirth;
      case 'bloodGroup':
        return widget.member!.bloodGroup;
      case 'dvmInstitute':
        return widget.member!.dvmInstitute;
      case 'msc':
        return widget.member!.msc;
      case 'phd':
        return widget.member!.phd;
      case 'experience':
        return widget.member!.experience;
      case 'specialization':
        return widget.member!.specialization;
      case 'workType':
        return widget.member!.workType;
      case 'instituteName':
        return widget.member!.instituteName;
      case 'interests':
        return widget.member!.interests;
      case 'photoUrl':
        return widget.member!.photoUrl;
      case 'licenseUrl':
        return widget.member!.licenseUrl;
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _ctrls['name']!.text.trim();
    final mobile = _ctrls['mobile']!.text.trim();
    if (name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and Mobile are required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final id = widget.member?.id ??
        'new_${DateTime.now().millisecondsSinceEpoch}';
    final member = MemberModel(
      id: id,
      name: name,
      nameBn: widget.member?.nameBn ?? '',
      fatherName: _ctrls['fatherName']!.text.trim(),
      motherName: _ctrls['motherName']!.text.trim(),
      gender: _ctrls['gender']!.text.trim(),
      permanentAddress: _ctrls['permanentAddress']!.text.trim(),
      mailingAddress: _ctrls['mailingAddress']!.text.trim(),
      mobile: mobile,
      email: _ctrls['email']!.text.trim(),
      emergencyContact: _ctrls['emergencyContact']!.text.trim(),
      bvcRegNo: _ctrls['bvcRegNo']!.text.trim(),
      dateOfBirth: _ctrls['dateOfBirth']!.text.trim(),
      bloodGroup: _ctrls['bloodGroup']!.text.trim(),
      dvmInstitute: _ctrls['dvmInstitute']!.text.trim(),
      msc: _ctrls['msc']!.text.trim(),
      phd: _ctrls['phd']!.text.trim(),
      experience: _ctrls['experience']!.text.trim(),
      specialization: _ctrls['specialization']!.text.trim(),
      workType: _ctrls['workType']!.text.trim(),
      instituteName: _ctrls['instituteName']!.text.trim(),
      interests: _ctrls['interests']!.text.trim(),
      photoUrl: _ctrls['photoUrl']!.text.trim(),
      licenseUrl: _ctrls['licenseUrl']!.text.trim(),
    );

    try {
      await sl<MemberRemoteDataSource>().saveMember(member);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Member' : 'Add Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFields([
              'name',
              'fatherName',
              'motherName',
              'gender',
              'dateOfBirth',
              'bloodGroup',
            ]),
            const SizedBox(height: 16),
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFields([
              'mobile',
              'email',
              'emergencyContact',
              'permanentAddress',
              'mailingAddress',
            ]),
            const SizedBox(height: 16),
            const Text(
              'Professional',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFields([
              'bvcRegNo',
              'dvmInstitute',
              'msc',
              'phd',
              'experience',
              'specialization',
            ]),
            const SizedBox(height: 16),
            const Text(
              'Work',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFields([
              'workType',
              'instituteName',
              'interests',
            ]),
            const SizedBox(height: 16),
            const Text(
              'Documents (URLs)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFields([
              'photoUrl',
              'licenseUrl',
            ]),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Update Member' : 'Add Member'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields(List<String> keys) {
    return keys
        .map((k) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _ctrls[k],
                decoration: InputDecoration(
                  labelText: _fields[k]!,
                ),
                keyboardType: k == 'mobile' || k == 'emergencyContact'
                    ? TextInputType.phone
                    : k == 'email'
                        ? TextInputType.emailAddress
                        : k == 'experience'
                            ? TextInputType.number
                            : TextInputType.text,
                maxLines: k == 'permanentAddress' || k == 'mailingAddress'
                    ? 2
                    : 1,
                validator: (v) {
                  if (k == 'name' && (v == null || v.trim().isEmpty)) {
                    return 'Name is required';
                  }
                  if (k == 'mobile' && (v == null || v.trim().isEmpty)) {
                    return 'Mobile is required';
                  }
                  return null;
                },
              ),
            ))
        .toList();
  }
}
