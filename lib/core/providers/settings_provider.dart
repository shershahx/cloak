import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main.dart');
});

/// Provider for app settings with persistence
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(prefs);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  static const _keyBlockAds = 'block_ads';
  static const _keyBlockTrackers = 'block_trackers';
  static const _keyBlockAnnoyances = 'block_annoyances';
  static const _keyDnsServer = 'dns_server';
  static const _keyAutoStart = 'auto_start';
  static const _keyAllowedApps = 'allowed_apps';

  AppSettingsNotifier(this._prefs) : super(_loadFromPrefs(_prefs));

  static AppSettings _loadFromPrefs(SharedPreferences prefs) {
    return AppSettings(
      blockAds: prefs.getBool(_keyBlockAds) ?? true,
      blockTrackers: prefs.getBool(_keyBlockTrackers) ?? true,
      blockAnnoyances: prefs.getBool(_keyBlockAnnoyances) ?? true,
      dnsServer: prefs.getString(_keyDnsServer) ?? '8.8.8.8',
      autoStart: prefs.getBool(_keyAutoStart) ?? false,
      allowedApps: prefs.getStringList(_keyAllowedApps) ?? [],
    );
  }

  Future<void> setBlockAds(bool value) async {
    await _prefs.setBool(_keyBlockAds, value);
    state = state.copyWith(blockAds: value);
  }

  Future<void> setBlockTrackers(bool value) async {
    await _prefs.setBool(_keyBlockTrackers, value);
    state = state.copyWith(blockTrackers: value);
  }

  Future<void> setBlockAnnoyances(bool value) async {
    await _prefs.setBool(_keyBlockAnnoyances, value);
    state = state.copyWith(blockAnnoyances: value);
  }

  Future<void> setDnsServer(String value) async {
    await _prefs.setString(_keyDnsServer, value);
    state = state.copyWith(dnsServer: value);
  }

  Future<void> setAutoStart(bool value) async {
    await _prefs.setBool(_keyAutoStart, value);
    state = state.copyWith(autoStart: value);
  }

  Future<void> addAllowedApp(String packageName) async {
    final newList = [...state.allowedApps, packageName];
    await _prefs.setStringList(_keyAllowedApps, newList);
    state = state.copyWith(allowedApps: newList);
  }

  Future<void> removeAllowedApp(String packageName) async {
    final newList = state.allowedApps.where((a) => a != packageName).toList();
    await _prefs.setStringList(_keyAllowedApps, newList);
    state = state.copyWith(allowedApps: newList);
  }
}
