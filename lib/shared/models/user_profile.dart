import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String phone;
  final String? avatarUrl;
  final List<String> fcmTokens;
  final List<String> stokvels;
  final DateTime createdAt;
  final UserSettings settings;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.phone,
    this.avatarUrl,
    this.fcmTokens = const [],
    this.stokvels = const [],
    required this.createdAt,
    this.settings = const UserSettings(),
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []),
      stokvels: List<String>.from(json['stokvels'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const UserSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'fcmTokens': fcmTokens,
      'stokvels': stokvels,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings.toJson(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    List<String>? stokvels,
    UserSettings? settings,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      phone: phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmTokens: fcmTokens,
      stokvels: stokvels ?? this.stokvels,
      createdAt: createdAt,
      settings: settings ?? this.settings,
    );
  }
}

class UserSettings {
  final bool darkMode;
  final String language;
  final bool notificationsEnabled;

  const UserSettings({
    this.darkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      darkMode: json['darkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
