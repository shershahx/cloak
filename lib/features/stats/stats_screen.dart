import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/vpn_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

/// Statistics screen with detailed blocking info
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(blockingStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(
                  'Statistics',
                  style: AppTypography.h2,
                ),
              ),
            ),

            // Main Stats Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.accent.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Blocked',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatNumber(stats.totalBlocked),
                        style: AppTypography.statNumber.copyWith(
                          fontSize: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'threats stopped',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Category Breakdown Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  'Breakdown by Category',
                  style: AppTypography.h4,
                ),
              ),
            ),

            // Category Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _CategoryCard(
                      title: 'Ads',
                      count: stats.adsBlocked,
                      icon: Icons.ad_units,
                      color: AppColors.categoryAds,
                      percentage: _calculatePercentage(
                        stats.adsBlocked,
                        stats.totalBlocked,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      title: 'Trackers',
                      count: stats.trackersBlocked,
                      icon: Icons.visibility_off,
                      color: AppColors.categoryTracking,
                      percentage: _calculatePercentage(
                        stats.trackersBlocked,
                        stats.totalBlocked,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      title: 'Annoyances',
                      count: stats.annoyancesBlocked,
                      icon: Icons.notifications_off,
                      color: AppColors.categoryAnnoyances,
                      percentage: _calculatePercentage(
                        stats.annoyancesBlocked,
                        stats.totalBlocked,
                      ),
                    ),
                  ],
                ),
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  double _calculatePercentage(int part, int total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final double percentage;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCount(count),
                style: AppTypography.h4.copyWith(color: color),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
