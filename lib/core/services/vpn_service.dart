import 'dart:async';
import 'package:flutter/services.dart';

import '../constants/channel_constants.dart';
import '../models/vpn_state.dart';
import '../models/dns_query.dart';
import '../models/blocking_stats.dart';

/// Service for communicating with the native VPN service via MethodChannel
class VpnService {
  static const _channel = MethodChannel(ChannelConstants.vpnChannel);
  static const _eventChannel = EventChannel(ChannelConstants.eventChannel);

  static VpnService? _instance;
  static VpnService get instance => _instance ??= VpnService._();

  VpnService._();

  // Stream controllers for events from native
  final _vpnStateController = StreamController<VpnState>.broadcast();
  final _dnsQueryController = StreamController<DnsQuery>.broadcast();
  final _statsController = StreamController<BlockingStats>.broadcast();

  Stream<VpnState> get vpnStateStream => _vpnStateController.stream;
  Stream<DnsQuery> get dnsQueryStream => _dnsQueryController.stream;
  Stream<BlockingStats> get statsStream => _statsController.stream;

  bool _isInitialized = false;

  /// Initialize the VPN service and set up event listeners
  Future<void> initialize() async {
    if (_isInitialized) return;

    _eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        _vpnStateController.add(VpnState.error);
      },
    );

    _isInitialized = true;
  }

  /// Handle events from the native side
  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    try {
      final type = event['type'] as String?;
      final data = event['data'];

      switch (type) {
        case ChannelConstants.eventVpnStateChanged:
          final state = _parseVpnState(data as String? ?? 'disconnected');
          _vpnStateController.add(state);
          break;

        case ChannelConstants.eventDnsQuery:
          if (data is Map<String, dynamic>) {
            final query = DnsQuery.fromJson(data);
            _dnsQueryController.add(query);
          } else if (data is Map) {
            final query = DnsQuery.fromJson(Map<String, dynamic>.from(data));
            _dnsQueryController.add(query);
          }
          break;

        case ChannelConstants.eventStatsUpdate:
          if (data is Map<String, dynamic>) {
            final stats = BlockingStats.fromJson(data);
            _statsController.add(stats);
          } else if (data is Map) {
            final stats = BlockingStats.fromJson(Map<String, dynamic>.from(data));
            _statsController.add(stats);
          }
          break;

        case ChannelConstants.eventError:
          _vpnStateController.add(VpnState.error);
          break;
      }
    } catch (e) {
      print('Error handling event: $e');
    }
  }

  /// Parse VPN state string from native
  VpnState _parseVpnState(String state) {
    switch (state.toLowerCase()) {
      case 'connected':
        return VpnState.connected;
      case 'connecting':
        return VpnState.connecting;
      case 'disconnecting':
        return VpnState.disconnecting;
      case 'permission_denied':
        return VpnState.permissionDenied;
      case 'error':
        return VpnState.error;
      default:
        return VpnState.disconnected;
    }
  }

  /// Prepare VPN (request permission if needed)
  Future<bool> prepareVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        ChannelConstants.methodPrepareVpn,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to prepare VPN: ${e.message}');
      return false;
    }
  }

  /// Start the VPN service
  Future<bool> startVpn({
    String dnsServer = '8.8.8.8',
    bool blockAds = true,
    bool blockTrackers = true,
    bool blockAnnoyances = true,
  }) async {
    try {
      _vpnStateController.add(VpnState.connecting);

      final result = await _channel.invokeMethod<bool>(
        ChannelConstants.methodStartVpn,
        {
          ChannelConstants.argDnsServer: dnsServer,
          ChannelConstants.argBlockAds: blockAds,
          ChannelConstants.argBlockTrackers: blockTrackers,
          ChannelConstants.argBlockAnnoyances: blockAnnoyances,
        },
      );

      if (result == true) {
        _vpnStateController.add(VpnState.connected);
      } else {
        _vpnStateController.add(VpnState.disconnected);
      }

      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start VPN: ${e.message}');
      _vpnStateController.add(VpnState.error);
      return false;
    }
  }

  /// Stop the VPN service
  Future<bool> stopVpn() async {
    try {
      _vpnStateController.add(VpnState.disconnecting);

      final result = await _channel.invokeMethod<bool>(
        ChannelConstants.methodStopVpn,
      );

      _vpnStateController.add(VpnState.disconnected);
      return result ?? true;
    } on PlatformException catch (e) {
      print('Failed to stop VPN: ${e.message}');
      _vpnStateController.add(VpnState.error);
      return false;
    }
  }

  /// Check if VPN is currently running
  Future<bool> isVpnRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        ChannelConstants.methodIsVpnRunning,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check VPN status: ${e.message}');
      return false;
    }
  }

  /// Get current blocking stats
  Future<BlockingStats> getStats() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        ChannelConstants.methodGetStats,
      );

      if (result != null) {
        return BlockingStats.fromJson(Map<String, dynamic>.from(result));
      }
      return BlockingStats.empty;
    } on PlatformException catch (e) {
      print('Failed to get stats: ${e.message}');
      return BlockingStats.empty;
    }
  }

  /// Add an app to the allowlist (bypass VPN)
  Future<bool> addToAllowlist(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        ChannelConstants.methodAddToAllowlist,
        {ChannelConstants.argPackageName: packageName},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to add to allowlist: ${e.message}');
      return false;
    }
  }

  /// Remove an app from the allowlist
  Future<bool> removeFromAllowlist(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        ChannelConstants.methodRemoveFromAllowlist,
        {ChannelConstants.argPackageName: packageName},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to remove from allowlist: ${e.message}');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _vpnStateController.close();
    _dnsQueryController.close();
    _statsController.close();
  }
}
