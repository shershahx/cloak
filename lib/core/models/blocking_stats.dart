/// Model for blocking statistics
class BlockingStats {
  final int totalBlocked;
  final int totalAllowed;
  final int adsBlocked;
  final int trackersBlocked;
  final int annoyancesBlocked;
  final int todayBlocked;
  final DateTime? lastUpdated;

  const BlockingStats({
    this.totalBlocked = 0,
    this.totalAllowed = 0,
    this.adsBlocked = 0,
    this.trackersBlocked = 0,
    this.annoyancesBlocked = 0,
    this.todayBlocked = 0,
    this.lastUpdated,
  });

  /// Empty stats for initial state
  static const BlockingStats empty = BlockingStats();

  /// Calculate blocking percentage
  double get blockingPercentage {
    final total = totalBlocked + totalAllowed;
    if (total == 0) return 0;
    return (totalBlocked / total) * 100;
  }

  /// Create a copy with updated values
  BlockingStats copyWith({
    int? totalBlocked,
    int? totalAllowed,
    int? adsBlocked,
    int? trackersBlocked,
    int? annoyancesBlocked,
    int? todayBlocked,
    DateTime? lastUpdated,
  }) {
    return BlockingStats(
      totalBlocked: totalBlocked ?? this.totalBlocked,
      totalAllowed: totalAllowed ?? this.totalAllowed,
      adsBlocked: adsBlocked ?? this.adsBlocked,
      trackersBlocked: trackersBlocked ?? this.trackersBlocked,
      annoyancesBlocked: annoyancesBlocked ?? this.annoyancesBlocked,
      todayBlocked: todayBlocked ?? this.todayBlocked,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory BlockingStats.fromJson(Map<String, dynamic> json) {
    return BlockingStats(
      totalBlocked: _toInt(json['totalBlocked']),
      totalAllowed: _toInt(json['totalAllowed']),
      adsBlocked: _toInt(json['adsBlocked']),
      trackersBlocked: _toInt(json['trackersBlocked']),
      annoyancesBlocked: _toInt(json['annoyancesBlocked']),
      todayBlocked: _toInt(json['todayBlocked']),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_toInt(json['lastUpdated']))
          : null,
    );
  }

  /// Safely convert dynamic to int (handles Kotlin Long)
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBlocked': totalBlocked,
      'totalAllowed': totalAllowed,
      'adsBlocked': adsBlocked,
      'trackersBlocked': trackersBlocked,
      'annoyancesBlocked': annoyancesBlocked,
      'todayBlocked': todayBlocked,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'BlockingStats(totalBlocked: $totalBlocked, todayBlocked: $todayBlocked)';
  }
}
