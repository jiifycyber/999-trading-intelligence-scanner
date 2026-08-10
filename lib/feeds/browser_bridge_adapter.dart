import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tick.dart';
import 'feed_adapter.dart';

class BrowserBridgeAdapter implements FeedAdapter {
  BrowserBridgeAdapter({
    this.url = 'ws://127.0.0.1:8765',
  });

  final String url;
  final _controller = StreamController<Tick>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;

  @override
  String get name => 'Browser Quote Bridge';

  @override
  Stream<Tick> get ticks => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _subscription = _channel!.stream.listen(
      _onMessage,
      onDone: () => _connected = false,
      onError: (_) => _connected = false,
    );
    _connected = true;
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      if (data is! Map) return;
      final symbol = data['symbol'];
      final timestamp = data['timestamp'];
      final price = data['price'];
      if (symbol is String && timestamp is num && price is num) {
        _controller.add(Tick(
          symbol: symbol,
          timestamp: timestamp.toDouble(),
          price: price.toDouble(),
          source: name,
        ));
      }
    } catch (_) {
      // Ignore malformed/non-quote messages.
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _connected = false;
  }
}
