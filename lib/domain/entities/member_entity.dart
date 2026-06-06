import 'package:equatable/equatable.dart';

class MemberEntity extends Equatable {
  final String id;
  final String name;
  final String nameBn;
  final String fatherName;
  final String motherName;
  final String gender;
  final String permanentAddress;
  final String mailingAddress;
  final String mobile;
  final String email;
  final String emergencyContact;
  final String bvcRegNo;
  final String dateOfBirth;
  final String bloodGroup;
  final String dvmInstitute;
  final String msc;
  final String phd;
  final String experience;
  final String specialization;
  final String workType;
  final String instituteName;
  final String interests;
  final String photoUrl;
  final String licenseUrl;
  final String password;

  const MemberEntity({
    required this.id,
    required this.name,
    this.nameBn = '',
    this.fatherName = '',
    this.motherName = '',
    this.gender = '',
    this.permanentAddress = '',
    this.mailingAddress = '',
    this.mobile = '',
    this.email = '',
    this.emergencyContact = '',
    this.bvcRegNo = '',
    this.dateOfBirth = '',
    this.bloodGroup = '',
    this.dvmInstitute = '',
    this.msc = '',
    this.phd = '',
    this.experience = '',
    this.specialization = '',
    this.workType = '',
    this.instituteName = '',
    this.interests = '',
    this.photoUrl = '',
    this.licenseUrl = '',
    this.password = '',
  });

  String get memberId => 'CPVA-$bvcRegNo';
  String get displayName => nameBn.isNotEmpty ? nameBn : name;
  String get mobileClean => mobile.replaceAll(RegExp(r'[^\d]'), '');
  bool get isAdmin => mobileClean == '01853548853';
  bool get isActive => true;
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mobile,
        email,
        bvcRegNo,
      ];
}
