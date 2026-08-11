import 'dart:async';
import 'dart:math';
import '../models/tick.dart';
import 'feed_adapter.dart';

class DemoFeedAdapter implements FeedAdapter {
  final _controller = StreamController<Tick>.broadcast();
  Timer? _timer;
  final _rng = Random();
  bool _connected = false;

  final Map<String, double> _prices = {
    'EURUSD_otc': 1.19212,
    'USDJPY': 158.242,
    'AEDCNY_otc': 1.92870,
    'AUDJPY_otc': 103.521,
    'GBPUSD_otc': 1.27420,
    'BTCUSD': 68120.0,
  };

  @override
  String get name => 'Demo Feed';

  @override
  Stream<Tick> get ticks => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      for (final entry in _prices.entries.toList()) {
        final scale = entry.key == 'BTCUSD'
            ? 12.0
            : (entry.key.contains('JPY') ? 0.008 : 0.00008);
        final next = entry.value + (_rng.nextDouble() - .48) * scale;
        _prices[entry.key] = next;
        _controller.add(Tick(
          symbol: entry.key,
          timestamp: now,
          price: next,
          source: name,
        ));
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _connected = false;
  }
}
