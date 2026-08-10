import 'dart:async';

import '../models/tick.dart';
import 'feed_adapter.dart';

class FailoverFeedAdapter implements FeedAdapter {
  final FeedAdapter primary;
  final FeedAdapter fallback;

  final StreamController<Tick> _controller = StreamController<Tick>.broadcast();

  StreamSubscription<Tick>? _subscription;

  FeedAdapter? _active;

  bool _connected = false;

  FailoverFeedAdapter({
    required this.primary,
    required this.fallback,
  });

  @override
  String get name => 'Failover: ${primary.name} → ${fallback.name}';

  @override
  Stream<Tick> get ticks => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    await _connectPrimary();
  }

  Future<void> _connectPrimary() async {
    try {
      await primary.connect();

      _active = primary;
      _connected = true;

      _subscription = primary.ticks.listen(
        _controller.add,
        onError: (_) => _switchToFallback(),
        onDone: _switchToFallback,
      );
    } catch (_) {
      await _switchToFallback();
    }
  }

  Future<void> _switchToFallback() async {
    if (_active == fallback) {
      return;
    }

    await _subscription?.cancel();

    try {
      await primary.disconnect();
    } catch (_) {}

    await fallback.connect();

    _active = fallback;
    _connected = true;

    _subscription = fallback.ticks.listen(
      _controller.add,
      onError: (_) {
        _connected = false;
      },
      onDone: () {
        _connected = false;
      },
    );
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();

    await primary.disconnect();

    await fallback.disconnect();

    _connected = false;
    _active = null;
  }
}
