import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  final String id;
  final String name;
  final String position;
  final String phone;
  final String email;

  const ContactEntity({
    required this.id,
    required this.name,
    required this.position,
    required this.phone,
    required this.email,
  });

  factory ContactEntity.fromJson(Map<String, dynamic> json) => ContactEntity(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        position: json['position'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
      );

  ContactEntity copyWith({
    String? id,
    String? name,
    String? position,
    String? phone,
    String? email,
  }) {
    return ContactEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position,
        'phone': phone,
        'email': email,
      };

  @override
  List<Object?> get props => [id, name, position, phone, email];
}
