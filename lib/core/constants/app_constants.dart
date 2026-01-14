/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Cloak';
  static const String appTagline = 'Privacy Shield';
  static const String appDescription = 'System-wide ad and tracker blocker';

  // Blocklist Info
  static const int totalBlockedDomains = 108500;
  static const String blocklistVersion = '2026.01.14';
  static const String blocklistSource = 'Community Lists';

  // DNS Servers
  static const Map<String, String> dnsServers = {
    'Google': '8.8.8.8',
    'Cloudflare': '1.1.1.1',
    'Quad9': '9.9.9.9',
    'OpenDNS': '208.67.222.222',
  };

  // Default Settings
  static const String defaultDnsServer = '8.8.8.8';
  static const bool defaultBlockAds = true;
  static const bool defaultBlockTrackers = true;
  static const bool defaultBlockAnnoyances = true;

  // Storage Keys
  static const String keyVpnEnabled = 'vpn_enabled';
  static const String keyDnsServer = 'dns_server';
  static const String keyBlockAds = 'block_ads';
  static const String keyBlockTrackers = 'block_trackers';
  static const String keyBlockAnnoyances = 'block_annoyances';
  static const String keyAllowedApps = 'allowed_apps';
  static const String keyTotalBlocked = 'total_blocked';
  static const String keyFirstLaunch = 'first_launch';
}
