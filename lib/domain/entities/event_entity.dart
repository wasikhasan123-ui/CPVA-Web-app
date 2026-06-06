import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  final String id;
  final String title;
  final String date;
  final String time;
  final String venue;
  final String imageUrl;
  final String description;
  final bool isUpcoming;

  const EventEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.imageUrl,
    required this.description,
    required this.isUpcoming,
  });

  factory EventEntity.fromJson(Map<String, dynamic> json) => EventEntity(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        venue: json['venue'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        description: json['description'] ?? '',
        isUpcoming: json['isUpcoming'] ?? true,
      );

  EventEntity copyWith({
    String? id,
    String? title,
    String? date,
    String? time,
    String? venue,
    String? imageUrl,
    String? description,
    bool? isUpcoming,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isUpcoming: isUpcoming ?? this.isUpcoming,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'venue': venue,
        'imageUrl': imageUrl,
        'description': description,
        'isUpcoming': isUpcoming,
      };

  @override
  List<Object?> get props =>
      [id, title, date, time, venue, description, isUpcoming];
}
