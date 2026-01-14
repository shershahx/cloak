import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dns_query.dart';
import '../../../core/providers/vpn_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

/// Recent DNS activity list
class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queries = ref.watch(dnsQueryLogProvider);

    if (queries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.hourglass_empty,
                color: AppColors.textMuted,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No activity yet',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'DNS queries will appear here when the shield is active',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show only the first 5 queries
    final recentQueries = queries.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: recentQueries.length,
          separatorBuilder: (context, index) => Divider(
            color: AppColors.divider,
            height: 1,
            indent: 56,
          ),
          itemBuilder: (context, index) {
            return _ActivityItem(query: recentQueries[index]);
          },
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final DnsQuery query;

  const _ActivityItem({required this.query});

  @override
  Widget build(BuildContext context) {
    final isBlocked = query.blocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isBlocked
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isBlocked ? Icons.close : Icons.check,
              size: 18,
              color: isBlocked ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query.domain,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (query.category != null)
                  Text(
                    query.category!.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: _getCategoryColor(query.category!),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            isBlocked ? 'Blocked' : 'Allowed',
            style: AppTypography.labelSmall.copyWith(
              color: isBlocked ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ads':
        return AppColors.categoryAds;
      case 'tracking':
        return AppColors.categoryTracking;
      case 'annoyances':
        return AppColors.categoryAnnoyances;
      default:
        return AppColors.textMuted;
    }
  }
}
