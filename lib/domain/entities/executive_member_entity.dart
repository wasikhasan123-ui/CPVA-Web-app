import 'package:equatable/equatable.dart';

class ExecutiveMemberEntity extends Equatable {
  final String id;
  final String name;
  final String nameBn;
  final String designation;
  final String designationBn;
  final String mobile;
  final String photoUrl;

  const ExecutiveMemberEntity({
    required this.id,
    required this.name,
    this.nameBn = '',
    required this.designation,
    this.designationBn = '',
    required this.mobile,
    this.photoUrl = '',
  });

  String get mobileClean => mobile.replaceAll(RegExp(r'[^\d]'), '');

  String get displayName => nameBn.isNotEmpty ? nameBn : name;
  String get displayDesignation =>
      designationBn.isNotEmpty ? designationBn : designation;

  String get initials {
    final parts = name
        .replaceAll(RegExp(r'^(Dr|Md|Mr|Mrs|Ms|Prof|Dr\.|Md\.|Mr\.|Mrs\.|Ms\.|Prof\.)\s*', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  ExecutiveMemberEntity copyWith({
    String? id,
    String? name,
    String? nameBn,
    String? designation,
    String? designationBn,
    String? mobile,
    String? photoUrl,
  }) {
    return ExecutiveMemberEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      designation: designation ?? this.designation,
      designationBn: designationBn ?? this.designationBn,
      mobile: mobile ?? this.mobile,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, nameBn, designation, designationBn, mobile, photoUrl];
}
