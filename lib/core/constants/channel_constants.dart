/// MethodChannel constants for Flutter ↔ Kotlin communication
class ChannelConstants {
  ChannelConstants._();

  // Channel Names
  static const String vpnChannel = 'com.cloakshield.cloak/vpn';
  static const String eventChannel = 'com.cloakshield.cloak/vpn_events';

  // Methods: Flutter → Kotlin
  static const String methodStartVpn = 'startVpn';
  static const String methodStopVpn = 'stopVpn';
  static const String methodIsVpnRunning = 'isVpnRunning';
  static const String methodGetStats = 'getStats';
  static const String methodAddToAllowlist = 'addToAllowlist';
  static const String methodRemoveFromAllowlist = 'removeFromAllowlist';
  static const String methodGetAllowlist = 'getAllowlist';
  static const String methodUpdateBlocklists = 'updateBlocklists';
  static const String methodPrepareVpn = 'prepareVpn';

  // Events: Kotlin → Flutter
  static const String eventVpnStateChanged = 'onVpnStateChanged';
  static const String eventDnsQuery = 'onDnsQuery';
  static const String eventStatsUpdate = 'onStatsUpdate';
  static const String eventError = 'onError';

  // Arguments
  static const String argDnsServer = 'dnsServer';
  static const String argPackageName = 'packageName';
  static const String argBlockAds = 'blockAds';
  static const String argBlockTrackers = 'blockTrackers';
  static const String argBlockAnnoyances = 'blockAnnoyances';
}
