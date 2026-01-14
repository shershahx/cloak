/// Model for a single DNS query log entry
class DnsQuery {
  final String domain;
  final bool blocked;
  final String? category; // 'ads', 'tracking', 'annoyances', null for allowed
  final DateTime timestamp;
  final String? appPackage; // Which app made the request

  const DnsQuery({
    required this.domain,
    required this.blocked,
    this.category,
    required this.timestamp,
    this.appPackage,
  });

  factory DnsQuery.fromJson(Map<String, dynamic> json) {
    // Safely convert timestamp (Kotlin Long -> Dart int)
    final timestamp = json['timestamp'];
    final timestampMs = timestamp is int ? timestamp : (timestamp as num?)?.toInt() ?? 0;
    
    return DnsQuery(
      domain: json['domain'] as String? ?? 'unknown',
      blocked: json['blocked'] as bool? ?? false,
      category: json['category'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      appPackage: json['appPackage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'blocked': blocked,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'appPackage': appPackage,
    };
  }

  @override
  String toString() {
    return 'DnsQuery(domain: $domain, blocked: $blocked, category: $category)';
  }
}
