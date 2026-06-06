import 'package:equatable/equatable.dart';

class GalleryEntity extends Equatable {
  final String id;
  final String title;
  final String type;
  final String imageUrl;
  final String date;

  const GalleryEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.imageUrl,
    required this.date,
  });

  factory GalleryEntity.fromJson(Map<String, dynamic> json) => GalleryEntity(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? 'photo',
        imageUrl: json['imageUrl'] ?? '',
        date: json['date'] ?? '',
      );

  GalleryEntity copyWith({
    String? id,
    String? title,
    String? type,
    String? imageUrl,
    String? date,
  }) {
    return GalleryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'imageUrl': imageUrl,
        'date': date,
      };

  @override
  List<Object?> get props => [id, title, type, imageUrl, date];
}
