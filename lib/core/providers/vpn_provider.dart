import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vpn_state.dart';
import '../models/blocking_stats.dart';
import '../models/dns_query.dart';
import '../services/vpn_service.dart';
import 'settings_provider.dart';

/// Provider for VPN service instance
final vpnServiceProvider = Provider<VpnService>((ref) {
  return VpnService.instance;
});

/// Provider for current VPN state
final vpnStateProvider = StreamProvider<VpnState>((ref) {
  final vpnService = ref.watch(vpnServiceProvider);
  return vpnService.vpnStateStream;
});

/// Provider for current VPN state with default value
final vpnStateNotifierProvider =
    StateNotifierProvider<VpnStateNotifier, VpnState>((ref) {
  final vpnService = ref.watch(vpnServiceProvider);
  // Read settings only when needed, don't watch (prevents recreation)
  final notifier = VpnStateNotifier(vpnService, ref);
  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
});

class VpnStateNotifier extends StateNotifier<VpnState> {
  final VpnService _vpnService;
  final Ref _ref;
  StreamSubscription<VpnState>? _subscription;

  VpnStateNotifier(this._vpnService, this._ref) : super(VpnState.disconnected) {
    _init();
  }

  void _init() {
    // Listen to VPN state changes with subscription we can cancel
    _subscription = _vpnService.vpnStateStream.listen((newState) {
      if (mounted) {
        state = newState;
      }
    });

    // Check initial state
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final isRunning = await _vpnService.isVpnRunning();
    if (mounted) {
      state = isRunning ? VpnState.connected : VpnState.disconnected;
    }
  }

  Future<bool> toggleVpn() async {
    if (state.isConnected) {
      return await stopVpn();
    } else {
      return await startVpn();
    }
  }

  Future<bool> startVpn() async {
    if (!mounted) return false;
    state = VpnState.connecting;
    
    // Read settings at the time of starting
    final settings = _ref.read(appSettingsProvider);
    
    final success = await _vpnService.startVpn(
      dnsServer: settings.dnsServer,
      blockAds: settings.blockAds,
      blockTrackers: settings.blockTrackers,
      blockAnnoyances: settings.blockAnnoyances,
    );
    if (!success && mounted) {
      state = VpnState.disconnected;
    }
    return success;
  }

  Future<bool> stopVpn() async {
    if (!mounted) return false;
    state = VpnState.disconnecting;
    final success = await _vpnService.stopVpn();
    if (!success && mounted) {
      state = VpnState.connected;
    }
    return success;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

/// Provider for blocking statistics
final blockingStatsProvider =
    StateNotifierProvider<BlockingStatsNotifier, BlockingStats>((ref) {
  final vpnService = ref.watch(vpnServiceProvider);
  final notifier = BlockingStatsNotifier(vpnService);
  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
});

class BlockingStatsNotifier extends StateNotifier<BlockingStats> {
  final VpnService _vpnService;
  StreamSubscription<BlockingStats>? _subscription;

  BlockingStatsNotifier(this._vpnService) : super(BlockingStats.empty) {
    _init();
  }

  void _init() {
    // Listen to stats updates with subscription we can cancel
    _subscription = _vpnService.statsStream.listen((newStats) {
      if (mounted) {
        state = newStats;
      }
    });

    // Load initial stats
    _loadInitialStats();
  }

  Future<void> _loadInitialStats() async {
    final stats = await _vpnService.getStats();
    if (mounted) {
      state = stats;
    }
  }

  void refresh() {
    _loadInitialStats();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

/// Provider for DNS query log
final dnsQueryLogProvider =
    StateNotifierProvider<DnsQueryLogNotifier, List<DnsQuery>>((ref) {
  final vpnService = ref.watch(vpnServiceProvider);
  final notifier = DnsQueryLogNotifier(vpnService);
  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
});

class DnsQueryLogNotifier extends StateNotifier<List<DnsQuery>> {
  final VpnService _vpnService;
  StreamSubscription<DnsQuery>? _subscription;
  static const int _maxLogSize = 500;

  DnsQueryLogNotifier(this._vpnService) : super([]) {
    _init();
  }

  void _init() {
    _subscription = _vpnService.dnsQueryStream.listen((query) {
      if (mounted) {
        // Add to front of list, maintain max size
        state = [query, ...state.take(_maxLogSize - 1)];
      }
    });
  }

  void clear() {
    state = [];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
