class AppSettings {
  final String adminEmail;
  final String geminiApiKey;
  final String openaiApiKey;
  final String openaiModel;

  AppSettings({
    required this.adminEmail,
    required this.geminiApiKey,
    required this.openaiApiKey,
    required this.openaiModel,
  });

  factory AppSettings.empty() {
    return AppSettings(
      adminEmail: 'admin@instaauto.ai',
      geminiApiKey: '',
      openaiApiKey: '',
      openaiModel: 'gpt-4o',
    );
  }

  AppSettings copyWith({
    String? adminEmail,
    String? geminiApiKey,
    String? openaiApiKey,
    String? openaiModel,
  }) {
    return AppSettings(
      adminEmail: adminEmail ?? this.adminEmail,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      openaiModel: openaiModel ?? this.openaiModel,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      adminEmail: json['adminEmail'] ?? 'admin@instaauto.ai',
      geminiApiKey: json['geminiApiKey'] ?? '',
      openaiApiKey: json['openaiApiKey'] ?? '',
      openaiModel: json['openaiModel'] ?? 'gpt-4o',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adminEmail': adminEmail,
      'geminiApiKey': geminiApiKey,
      'openaiApiKey': openaiApiKey,
      'openaiModel': openaiModel,
    };
  }
}
