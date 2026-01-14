import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/dns_query.dart';
import '../../core/providers/vpn_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

/// Filter options for logs
enum LogFilter { all, blocked, allowed }

final logFilterProvider = StateProvider<LogFilter>((ref) => LogFilter.all);

/// Logs screen showing DNS query history
class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queries = ref.watch(dnsQueryLogProvider);
    final filter = ref.watch(logFilterProvider);

    final filteredQueries = queries.where((q) {
      switch (filter) {
        case LogFilter.all:
          return true;
        case LogFilter.blocked:
          return q.blocked;
        case LogFilter.allowed:
          return !q.blocked;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Activity Log', style: AppTypography.h2),
                  IconButton(
                    onPressed: () {
                      ref.read(dnsQueryLogProvider.notifier).clear();
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Clear logs',
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'All',
                      isActive: filter == LogFilter.all,
                      onTap: () => ref.read(logFilterProvider.notifier).state =
                          LogFilter.all,
                    ),
                    _FilterTab(
                      label: 'Blocked',
                      isActive: filter == LogFilter.blocked,
                      onTap: () => ref.read(logFilterProvider.notifier).state =
                          LogFilter.blocked,
                      color: AppColors.error,
                    ),
                    _FilterTab(
                      label: 'Allowed',
                      isActive: filter == LogFilter.allowed,
                      onTap: () => ref.read(logFilterProvider.notifier).state =
                          LogFilter.allowed,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${filteredQueries.length} entries',
                style: AppTypography.bodySmall,
              ),
            ),

            const SizedBox(height: 8),

            // Log List
            Expanded(
              child: filteredQueries.isEmpty
                  ? _EmptyState(filter: filter)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredQueries.length,
                      itemBuilder: (context, index) {
                        return _LogEntry(query: filteredQueries[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (color ?? AppColors.primary).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: isActive ? (color ?? AppColors.primary) : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final LogFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    switch (filter) {
      case LogFilter.all:
        message = 'No DNS queries yet.\nEnable the shield to start logging.';
        icon = Icons.hourglass_empty;
        break;
      case LogFilter.blocked:
        message = 'No blocked queries yet.';
        icon = Icons.block;
        break;
      case LogFilter.allowed:
        message = 'No allowed queries yet.';
        icon = Icons.check_circle_outline;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final DnsQuery query;

  const _LogEntry({required this.query});

  @override
  Widget build(BuildContext context) {
    final isBlocked = query.blocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isBlocked
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBlocked ? Icons.close : Icons.check,
              size: 20,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (query.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(query.category!)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          query.category!.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: _getCategoryColor(query.category!),
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _formatTime(query.timestamp),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
