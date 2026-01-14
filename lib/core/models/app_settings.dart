/// User settings model
class AppSettings {
  final String dnsServer;
  final bool blockAds;
  final bool blockTrackers;
  final bool blockAnnoyances;
  final bool autoStart;
  final bool showNotifications;
  final List<String> allowedApps;

  const AppSettings({
    this.dnsServer = '8.8.8.8',
    this.blockAds = true,
    this.blockTrackers = true,
    this.blockAnnoyances = true,
    this.autoStart = false,
    this.showNotifications = true,
    this.allowedApps = const [],
  });

  /// Default settings
  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    String? dnsServer,
    bool? blockAds,
    bool? blockTrackers,
    bool? blockAnnoyances,
    bool? autoStart,
    bool? showNotifications,
    List<String>? allowedApps,
  }) {
    return AppSettings(
      dnsServer: dnsServer ?? this.dnsServer,
      blockAds: blockAds ?? this.blockAds,
      blockTrackers: blockTrackers ?? this.blockTrackers,
      blockAnnoyances: blockAnnoyances ?? this.blockAnnoyances,
      autoStart: autoStart ?? this.autoStart,
      showNotifications: showNotifications ?? this.showNotifications,
      allowedApps: allowedApps ?? this.allowedApps,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      dnsServer: json['dnsServer'] as String? ?? '8.8.8.8',
      blockAds: json['blockAds'] as bool? ?? true,
      blockTrackers: json['blockTrackers'] as bool? ?? true,
      blockAnnoyances: json['blockAnnoyances'] as bool? ?? true,
      autoStart: json['autoStart'] as bool? ?? false,
      showNotifications: json['showNotifications'] as bool? ?? true,
      allowedApps: (json['allowedApps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dnsServer': dnsServer,
      'blockAds': blockAds,
      'blockTrackers': blockTrackers,
      'blockAnnoyances': blockAnnoyances,
      'autoStart': autoStart,
      'showNotifications': showNotifications,
      'allowedApps': allowedApps,
    };
  }
}
