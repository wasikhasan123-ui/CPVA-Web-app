import '../../domain/entities/executive_member_entity.dart';

class ExecutiveMemberModel extends ExecutiveMemberEntity {
  const ExecutiveMemberModel({
    required super.id,
    required super.name,
    super.nameBn = '',
    required super.designation,
    super.designationBn = '',
    required super.mobile,
    super.photoUrl = '',
  });

  factory ExecutiveMemberModel.fromJson(Map<String, dynamic> json) {
    return ExecutiveMemberModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nameBn: (json['nameBn'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      designationBn: (json['designationBn'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameBn': nameBn,
      'designation': designation,
      'designationBn': designationBn,
      'mobile': mobile,
      'photoUrl': photoUrl,
    };
  }

  factory ExecutiveMemberModel.fromEntity(ExecutiveMemberEntity e) {
    return ExecutiveMemberModel(
      id: e.id,
      name: e.name,
      nameBn: e.nameBn,
      designation: e.designation,
      designationBn: e.designationBn,
      mobile: e.mobile,
      photoUrl: e.photoUrl,
    );
  }
}
