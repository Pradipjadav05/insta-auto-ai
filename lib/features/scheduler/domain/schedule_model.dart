import 'package:cloud_firestore/cloud_firestore.dart';
import '../../generator/domain/content_model.dart';

class ScheduleItem {
  final String id;
  final String contentId;
  final DateTime scheduledTime;
  final ContentStatus status;
  final DateTime? publishedTime;
  final int attempts;
  final String? lastError;

  ScheduleItem({
    required this.id,
    required this.contentId,
    required this.scheduledTime,
    required this.status,
    this.publishedTime,
    this.attempts = 0,
    this.lastError,
  });

  ScheduleItem copyWith({
    String? id,
    String? contentId,
    DateTime? scheduledTime,
    ContentStatus? status,
    DateTime? publishedTime,
    int? attempts,
    String? lastError,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      publishedTime: publishedTime ?? this.publishedTime,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ScheduleItem(
      id: docId ?? json['id'] ?? '',
      contentId: json['contentId'] ?? '',
      scheduledTime: json['scheduledTime'] is Timestamp
          ? (json['scheduledTime'] as Timestamp).toDate()
          : DateTime.tryParse(json['scheduledTime'] ?? '') ?? DateTime.now(),
      status: ContentStatus.fromJson(json['status'] ?? ''),
      publishedTime: json['publishedTime'] is Timestamp
          ? (json['publishedTime'] as Timestamp).toDate()
          : json['publishedTime'] != null
              ? DateTime.tryParse(json['publishedTime'])
              : null,
      attempts: json['attempts'] ?? 0,
      lastError: json['lastError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status.toJson(),
      'publishedTime': publishedTime != null ? Timestamp.fromDate(publishedTime!) : null,
      'attempts': attempts,
      'lastError': lastError,
    };
  }
}
