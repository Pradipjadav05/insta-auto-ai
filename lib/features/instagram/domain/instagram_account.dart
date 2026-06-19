import 'package:cloud_firestore/cloud_firestore.dart';

class InstagramAccount {
  final bool isConnected;
  final String pageId;
  final String pageName;
  final String accessToken;
  final String instagramBusinessAccountId;
  final String username;
  final String profilePictureUrl;
  final DateTime? connectedAt;

  InstagramAccount({
    required this.isConnected,
    required this.pageId,
    required this.pageName,
    required this.accessToken,
    required this.instagramBusinessAccountId,
    required this.username,
    required this.profilePictureUrl,
    this.connectedAt,
  });

  factory InstagramAccount.empty() {
    return InstagramAccount(
      isConnected: false,
      pageId: '',
      pageName: '',
      accessToken: '',
      instagramBusinessAccountId: '',
      username: '',
      profilePictureUrl: '',
    );
  }

  InstagramAccount copyWith({
    bool? isConnected,
    String? pageId,
    String? pageName,
    String? accessToken,
    String? instagramBusinessAccountId,
    String? username,
    String? profilePictureUrl,
    DateTime? connectedAt,
  }) {
    return InstagramAccount(
      isConnected: isConnected ?? this.isConnected,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      accessToken: accessToken ?? this.accessToken,
      instagramBusinessAccountId: instagramBusinessAccountId ?? this.instagramBusinessAccountId,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  factory InstagramAccount.fromJson(Map<String, dynamic> json) {
    return InstagramAccount(
      isConnected: json['isConnected'] ?? false,
      pageId: json['pageId'] ?? '',
      pageName: json['pageName'] ?? '',
      accessToken: json['accessToken'] ?? '',
      instagramBusinessAccountId: json['instagramBusinessAccountId'] ?? '',
      username: json['username'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      connectedAt: json['connectedAt'] is Timestamp
          ? (json['connectedAt'] as Timestamp).toDate()
          : json['connectedAt'] != null
              ? DateTime.tryParse(json['connectedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'pageId': pageId,
      'pageName': pageName,
      'accessToken': accessToken,
      'instagramBusinessAccountId': instagramBusinessAccountId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'connectedAt': connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
    };
  }
}
