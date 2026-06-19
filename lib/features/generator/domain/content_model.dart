import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType {
  feedPost,
  carousel,
  reel,
  story;

  String toJson() => name;
  static MediaType fromJson(String value) {
    return MediaType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MediaType.feedPost,
    );
  }

  String get displayName {
    switch (this) {
      case MediaType.feedPost:
        return 'Feed Post';
      case MediaType.carousel:
        return 'Carousel';
      case MediaType.reel:
        return 'Reel Script';
      case MediaType.story:
        return 'Story';
    }
  }
}

enum ContentStatus {
  draft,
  scheduled,
  published,
  failed;

  String toJson() => name;
  static ContentStatus fromJson(String value) {
    return ContentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentStatus.draft,
    );
  }
}

class ContentItem {
  final String id;
  final String title;
  final String body;
  final String caption;
  final List<String> hashtags;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final DateTime createdAt;
  final ContentStatus status;
  final String? errorMessage;

  ContentItem({
    required this.id,
    required this.title,
    required this.body,
    required this.caption,
    required this.hashtags,
    required this.mediaUrls,
    required this.mediaType,
    required this.createdAt,
    required this.status,
    this.errorMessage,
  });

  ContentItem copyWith({
    String? id,
    String? title,
    String? body,
    String? caption,
    List<String>? hashtags,
    List<String>? mediaUrls,
    MediaType? mediaType,
    DateTime? createdAt,
    ContentStatus? status,
    String? errorMessage,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory ContentItem.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ContentItem(
      id: docId ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      caption: json['caption'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      mediaType: MediaType.fromJson(json['mediaType'] ?? ''),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      status: ContentStatus.fromJson(json['status'] ?? ''),
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'caption': caption,
      'hashtags': hashtags,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toJson(),
      'errorMessage': errorMessage,
    };
  }
}
