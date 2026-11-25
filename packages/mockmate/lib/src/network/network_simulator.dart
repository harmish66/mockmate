import 'dart:async';
import 'dart:math';
import 'package:mockmate/src/network/network_exceptions.dart';
import 'package:mockmate/src/network/network_profile.dart';

/// Abstraction to control delays so unit tests can execute instantly.
abstract class DelayProvider {
  Future<void> delay(Duration duration);
}

/// Default delay provider using system [Future.delayed].
class RealDelayProvider implements DelayProvider {
  const RealDelayProvider();

  @override
  Future<void> delay(Duration duration) {
    if (duration <= Duration.zero) return Future.value();
    return Future.delayed(duration);
  }
}

/// Instant delay provider for testing that does not wait.
class ZeroDelayProvider implements DelayProvider {
  const ZeroDelayProvider();

  @override
  Future<void> delay(Duration duration) => Future.value();
}

/// Simulates network latency, timeouts, and network failures.
class NetworkSimulator {
  NetworkSimulator({
    NetworkProfile? profile,
    DelayProvider? delayProvider,
    int? randomSeed,
  })  : _profile = profile ?? NetworkProfile.excellent,
        _delayProvider = delayProvider ?? const RealDelayProvider(),
        _random = Random(randomSeed);

  NetworkProfile _profile;
  DelayProvider _delayProvider;
  final Random _random;
  bool _enabled = true;

  /// Current network profile.
  NetworkProfile get profile => _profile;

  /// Whether network simulation is currently active.
  bool get isEnabled => _enabled;

  /// Delay provider used for latency simulation.
  DelayProvider get delayProvider => _delayProvider;

  /// Updates delay provider (e.g. switch to ZeroDelayProvider in test suites).
  void setDelayProvider(DelayProvider provider) {
    _delayProvider = provider;
  }

  /// Enables or disables network simulation.
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Sets the active network profile.
  void setProfile(NetworkProfile profile) {
    _profile = profile;
  }

  /// Sets offline mode on or off.
  void setOffline(bool offline) {
    _profile = _profile.copyWith(isOffline: offline);
  }

  /// Simulates network execution according to the current profile.
  /// Throws [MockOfflineException], [MockTimeoutException], or [MockNetworkException] if failure conditions trigger.
  Future<void> simulate() async {
    if (!_enabled) return;

    if (_profile.isOffline) {
      throw const MockOfflineException(
          'Simulated offline condition: connection rejected');
    }

    // Check timeout
    if (_profile.timeout != null && _profile.timeout! > Duration.zero) {
      final minMs = _profile.minLatency.inMilliseconds;
      final maxMs = _profile.maxLatency.inMilliseconds;
      final lat = minMs == maxMs
          ? minMs
          : minMs + _random.nextInt(max(1, maxMs - minMs + 1));
      if (lat >= _profile.timeout!.inMilliseconds) {
        await _delayProvider.delay(_profile.timeout!);
        throw MockTimeoutException(
          'Request exceeded simulated timeout of ${_profile.timeout!.inMilliseconds}ms',
        );
      }
    }

    // Check failure rate
    if (_profile.failureRate > 0) {
      final roll = _random.nextDouble();
      if (roll < _profile.failureRate) {
        throw const MockNetworkException(
            'Simulated random connection reset error',
            statusCode: 503);
      }
    }

    // Simulate latency
    final minMs = _profile.minLatency.inMilliseconds;
    final maxMs = _profile.maxLatency.inMilliseconds;
    if (maxMs > 0) {
      final latMs = minMs == maxMs
          ? minMs
          : minMs + _random.nextInt(max(1, maxMs - minMs + 1));
      if (latMs > 0) {
        await _delayProvider.delay(Duration(milliseconds: latMs));
      }
    }
  }

  /// Helper to run an action with simulated network.
  Future<T> run<T>(Future<T> Function() action) async {
    await simulate();
    return action();
  }
}
