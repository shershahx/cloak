import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/vpn_state.dart';
import '../../core/providers/vpn_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import 'widgets/shield_button.dart';
import 'widgets/quick_stats_card.dart';
import 'widgets/recent_activity.dart';

/// Home screen with main VPN toggle
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnState = ref.watch(vpnStateNotifierProvider);
    final stats = ref.watch(blockingStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloak',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Privacy Shield',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: vpnState.isConnected
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: vpnState.isConnected
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: vpnState.isConnected
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vpnState.displayName,
                            style: AppTypography.labelMedium.copyWith(
                              color: vpnState.isConnected
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shield Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ShieldButton(
                  vpnState: vpnState,
                  onTap: () {
                    ref.read(vpnStateNotifierProvider.notifier).toggleVpn();
                  },
                ),
              ),
            ),

            // Status Text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      vpnState.displayName,
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vpnState.description,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: QuickStatsCard(stats: stats),
              ),
            ),

            // Recent Activity Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: AppTypography.h4),
                    TextButton(
                      onPressed: () {
                        context.go('/logs');
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Activity List
            const SliverToBoxAdapter(
              child: RecentActivity(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}
