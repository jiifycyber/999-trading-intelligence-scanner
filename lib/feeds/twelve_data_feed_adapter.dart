import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/tick.dart';
import 'feed_adapter.dart';

class TwelveDataFeedAdapter implements FeedAdapter {
  final StreamController<Tick> _controller = StreamController<Tick>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _connected = false;

  @override
  String get name => 'TWELVE DATA LIVE';

  @override
  bool get isConnected => _connected;

  @override
  Stream<Tick> get ticks => _controller.stream;

  @override
  Future<void> connect() async {
    await disconnect();

    final channel = WebSocketChannel.connect(
      Uri.parse(
        'wss://base-seminar-marco-jill.trycloudflare.com/stream',
      ),
    );

    _channel = channel;

    await channel.ready;

    _connected = true;

    // FastAPI bridge keeps this socket registered
    // while it waits for incoming client messages.
    channel.sink.add('READY');

    _subscription = channel.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(
            message.toString(),
          );

          if (decoded is! Map) return;

          if (decoded['type'] != 'tick') {
            return;
          }

          final symbol = (decoded['symbol'] ?? '')
              .toString()
              .replaceAll('/', '')
              .replaceAll('-', '')
              .toUpperCase();

          final price = double.tryParse(
            (decoded['price'] ?? '').toString(),
          );

          double? timestamp = double.tryParse(
            (decoded['timestamp'] ?? '').toString(),
          );

          if (symbol.isEmpty || price == null) {
            return;
          }

          // Tick model expects Unix SECONDS.
          // Convert milliseconds if a provider
          // ever sends them.
          timestamp ??= DateTime.now().millisecondsSinceEpoch / 1000.0;

          if (timestamp > 100000000000) {
            timestamp /= 1000.0;
          }

          _controller.add(
            Tick(
              symbol: symbol,
              timestamp: timestamp,
              price: price,
              source: 'TWELVE_DATA',
            ),
          );
        } catch (_) {
          // Ignore malformed/non-price messages.
        }
      },
      onError: (_) {
        _connected = false;
      },
      onDone: () {
        _connected = false;
      },
      cancelOnError: false,
    );
  }

  @override
  Future<void> disconnect() async {
    _connected = false;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
