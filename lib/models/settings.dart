class Settings {
  final String defaultCurrency;
  final String longPressAction; // 'lock' | 'delete' | 'discount'
  final bool hapticFeedbackEnabled;
  final String googleClientId;
  final int backupIntervalMinutes;
  final String theme; // 'light' | 'dark'

  Settings({
    this.defaultCurrency = 'CUP',
    this.longPressAction = 'lock',
    this.hapticFeedbackEnabled = true,
    this.googleClientId = '',
    this.backupIntervalMinutes = 30,
    this.theme = 'dark',
  });

  Settings copyWith({
    String? defaultCurrency,
    String? longPressAction,
    bool? hapticFeedbackEnabled,
    String? googleClientId,
    int? backupIntervalMinutes,
    String? theme,
  }) {
    return Settings(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      longPressAction: longPressAction ?? this.longPressAction,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      googleClientId: googleClientId ?? this.googleClientId,
      backupIntervalMinutes: backupIntervalMinutes ?? this.backupIntervalMinutes,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCurrency': defaultCurrency,
      'longPressAction': longPressAction,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'googleClientId': googleClientId,
      'backupIntervalMinutes': backupIntervalMinutes,
      'theme': theme,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      defaultCurrency: json['defaultCurrency'] as String? ?? 'CUP',
      longPressAction: json['longPressAction'] as String? ?? 'lock',
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
      googleClientId: json['googleClientId'] as String? ?? '',
      backupIntervalMinutes: (json['backupIntervalMinutes'] as num?)?.toInt() ?? 30,
      theme: json['theme'] as String? ?? 'dark',
    );
  }
}
