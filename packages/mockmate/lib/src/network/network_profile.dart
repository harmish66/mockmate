/// Presets representing real-world network condition profiles.
enum NetworkPreset {
  excellent,
  good,
  average,
  poor,
  offline,
  custom;

  String get displayName {
    switch (this) {
      case NetworkPreset.excellent:
        return 'Excellent (5G / Fiber)';
      case NetworkPreset.good:
        return 'Good (4G / WiFi)';
      case NetworkPreset.average:
        return 'Average (3G)';
      case NetworkPreset.poor:
        return 'Poor (2G / High Latency)';
      case NetworkPreset.offline:
        return 'Offline';
      case NetworkPreset.custom:
        return 'Custom Profile';
    }
  }
}

/// Configurable network profile defining latency and failure rates.
class NetworkProfile {
  const NetworkProfile({
    required this.name,
    required this.preset,
    this.minLatency = Duration.zero,
    this.maxLatency = Duration.zero,
    this.failureRate = 0.0,
    this.isOffline = false,
    this.timeout,
  });

  /// Preset: Excellent network (very low latency, 0% failure).
  static const NetworkProfile excellent = NetworkProfile(
    name: 'Excellent',
    preset: NetworkPreset.excellent,
    minLatency: Duration(milliseconds: 5),
    maxLatency: Duration(milliseconds: 25),
    failureRate: 0.0,
  );

  /// Preset: Good network (typical broadband/4G, 0% failure).
  static const NetworkProfile good = NetworkProfile(
    name: 'Good',
    preset: NetworkPreset.good,
    minLatency: Duration(milliseconds: 40),
    maxLatency: Duration(milliseconds: 90),
    failureRate: 0.0,
  );

  /// Preset: Average network (3G, slight jitter, 1% failure).
  static const NetworkProfile average = NetworkProfile(
    name: 'Average',
    preset: NetworkPreset.average,
    minLatency: Duration(milliseconds: 150),
    maxLatency: Duration(milliseconds: 350),
    failureRate: 0.01,
  );

  /// Preset: Poor network (2G / spotty connection, 5% failure).
  static const NetworkProfile poor = NetworkProfile(
    name: 'Poor',
    preset: NetworkPreset.poor,
    minLatency: Duration(milliseconds: 500),
    maxLatency: Duration(milliseconds: 1500),
    failureRate: 0.05,
  );

  /// Preset: Completely offline.
  static const NetworkProfile offline = NetworkProfile(
    name: 'Offline',
    preset: NetworkPreset.offline,
    isOffline: true,
  );

  final String name;
  final NetworkPreset preset;
  final Duration minLatency;
  final Duration maxLatency;
  final double failureRate;
  final bool isOffline;
  final Duration? timeout;

  String get displayName => preset.displayName;

  NetworkProfile copyWith({
    String? name,
    NetworkPreset? preset,
    Duration? minLatency,
    Duration? maxLatency,
    double? failureRate,
    bool? isOffline,
    Duration? timeout,
  }) {
    return NetworkProfile(
      name: name ?? this.name,
      preset: preset ?? this.preset,
      minLatency: minLatency ?? this.minLatency,
      maxLatency: maxLatency ?? this.maxLatency,
      failureRate: failureRate ?? this.failureRate,
      isOffline: isOffline ?? this.isOffline,
      timeout: timeout ?? this.timeout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'preset': preset.name,
      'minLatencyMs': minLatency.inMilliseconds,
      'maxLatencyMs': maxLatency.inMilliseconds,
      'failureRate': failureRate,
      'isOffline': isOffline,
      'timeoutMs': timeout?.inMilliseconds,
    };
  }
}
