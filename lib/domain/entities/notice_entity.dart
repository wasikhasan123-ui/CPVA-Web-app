import 'package:equatable/equatable.dart';

class NoticeEntity extends Equatable {
  final String id;
  final String title;
  final String category;
  final String date;
  final String description;
  final String attachmentUrl;
  final bool isPinned;

  const NoticeEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.attachmentUrl,
    required this.isPinned,
  });

  factory NoticeEntity.fromJson(Map<String, dynamic> json) => NoticeEntity(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        category: json['category'] ?? '',
        date: json['date'] ?? '',
        description: json['description'] ?? '',
        attachmentUrl: json['attachmentUrl'] ?? '',
        isPinned: json['isPinned'] ?? false,
      );

  NoticeEntity copyWith({
    String? id,
    String? title,
    String? category,
    String? date,
    String? description,
    String? attachmentUrl,
    bool? isPinned,
  }) {
    return NoticeEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date,
        'description': description,
        'attachmentUrl': attachmentUrl,
        'isPinned': isPinned,
      };

  @override
  List<Object?> get props => [id, title, category, date, description, isPinned];
}
