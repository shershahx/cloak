import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/vpn_state.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/vpn_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final vpnState = ref.watch(vpnStateNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text('Settings', style: AppTypography.h2),
              ),
            ),

            // Protection Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'Protection',
                children: [
                  _SettingsSwitch(
                    title: 'Block Ads',
                    subtitle: 'Block advertising domains',
                    icon: Icons.ad_units,
                    iconColor: AppColors.categoryAds,
                    value: settings.blockAds,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).setBlockAds(value);
                      _showRestartHint(context, vpnState.isConnected);
                    },
                  ),
                  _SettingsSwitch(
                    title: 'Block Trackers',
                    subtitle: 'Block tracking and analytics',
                    icon: Icons.visibility_off,
                    iconColor: AppColors.categoryTracking,
                    value: settings.blockTrackers,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).setBlockTrackers(value);
                      _showRestartHint(context, vpnState.isConnected);
                    },
                  ),
                  _SettingsSwitch(
                    title: 'Block Annoyances',
                    subtitle: 'Block cookie popups and annoyances',
                    icon: Icons.notifications_off,
                    iconColor: AppColors.categoryAnnoyances,
                    value: settings.blockAnnoyances,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).setBlockAnnoyances(value);
                      _showRestartHint(context, vpnState.isConnected);
                    },
                  ),
                ],
              ),
            ),

            // DNS Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'DNS Server',
                children: [
                  _SettingsTile(
                    title: 'DNS Provider',
                    subtitle: _getDnsName(settings.dnsServer),
                    icon: Icons.dns,
                    iconColor: AppColors.primary,
                    onTap: () {
                      _showDnsPicker(context, ref, settings.dnsServer);
                    },
                  ),
                ],
              ),
            ),

            // General Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'General',
                children: [
                  _SettingsSwitch(
                    title: 'Auto-start',
                    subtitle: 'Start protection on device boot',
                    icon: Icons.power_settings_new,
                    iconColor: AppColors.success,
                    value: settings.autoStart,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).setAutoStart(value);
                    },
                  ),
                  _SettingsTile(
                    title: 'App Allowlist',
                    subtitle: '${settings.allowedApps.length} apps bypass protection',
                    icon: Icons.apps,
                    iconColor: AppColors.accent,
                    onTap: () {
                      // TODO: Navigate to allowlist
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // About Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    title: 'Blocklist Info',
                    subtitle: '${AppConstants.totalBlockedDomains.toString()} domains • ${AppConstants.blocklistVersion}',
                    icon: Icons.list_alt,
                    iconColor: AppColors.textMuted,
                    onTap: () {
                      _showBlocklistInfo(context);
                    },
                  ),
                  _SettingsTile(
                    title: 'Version',
                    subtitle: '1.0.0',
                    icon: Icons.info_outline,
                    iconColor: AppColors.textMuted,
                    onTap: null,
                  ),
                  _SettingsTile(
                    title: 'Open Source',
                    subtitle: 'Community-maintained blocklists',
                    icon: Icons.code,
                    iconColor: AppColors.textMuted,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Blocklist derived from community sources')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  String _getDnsName(String ip) {
    return AppConstants.dnsServers.entries
        .firstWhere(
          (e) => e.value == ip,
          orElse: () => MapEntry(ip, ip),
        )
        .key;
  }

  void _showRestartHint(BuildContext context, bool isConnected) {
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restart protection to apply changes'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBlocklistInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Blocklist Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Total Domains', AppConstants.totalBlockedDomains.toString()),
            _InfoRow('Version', AppConstants.blocklistVersion),
            _InfoRow('Source', 'Community Lists'),
            const SizedBox(height: 12),
            Text(
              'This blocklist contains domains from community-maintained ad, tracking, and annoyance filters.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDnsPicker(BuildContext context, WidgetRef ref, String currentDns) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Select DNS Server', style: AppTypography.h4),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AppConstants.dnsServers.entries.map((entry) {
                    final isSelected = entry.value == currentDns;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary.withOpacity(0.7) : AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : Icon(Icons.circle_outlined, color: AppColors.textMuted.withOpacity(0.3)),
                        onTap: () {
                          ref.read(appSettingsProvider.notifier).setDnsServer(entry.value);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.divider,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTypography.labelLarge),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTypography.labelLarge),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
