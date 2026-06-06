import 'package:equatable/equatable.dart';

class NewsEntity extends Equatable {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final String date;
  final String category;

  const NewsEntity({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.date,
    required this.category,
  });

  factory NewsEntity.fromJson(Map<String, dynamic> json) => NewsEntity(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        summary: json['summary'] ?? '',
        content: json['content'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        date: json['date'] ?? '',
        category: json['category'] ?? '',
      );

  NewsEntity copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? date,
    String? category,
  }) {
    return NewsEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'content': content,
        'imageUrl': imageUrl,
        'date': date,
        'category': category,
      };

  @override
  List<Object?> get props => [id, title, summary, date];
}
