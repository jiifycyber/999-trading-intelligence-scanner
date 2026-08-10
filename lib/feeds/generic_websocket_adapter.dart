import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tick.dart';
import 'feed_adapter.dart';

typedef QuoteDecoder = Tick? Function(dynamic message);

class GenericWebSocketAdapter implements FeedAdapter {
  GenericWebSocketAdapter({
    required this.providerName,
    required this.url,
    required this.decoder,
    this.onConnected,
  });

  final String providerName;
  final String url;
  final QuoteDecoder decoder;
  final Future<void> Function(WebSocketChannel channel)? onConnected;

  final _controller = StreamController<Tick>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;

  @override
  String get name => providerName;

  @override
  Stream<Tick> get ticks => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _channel = WebSocketChannel.connect(Uri.parse(url));
    if (onConnected != null) await onConnected!(_channel!);
    _subscription = _channel!.stream.listen((message) {
      final tick = decoder(message);
      if (tick != null) _controller.add(tick);
    }, onDone: () {
      _connected = false;
    }, onError: (_) {
      _connected = false;
    });
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _connected = false;
  }

  static Tick? decodeSimpleJson(
    dynamic message, {
    required String source,
    String symbolKey = 'symbol',
    String timestampKey = 'timestamp',
    String priceKey = 'price',
  }) {
    try {
      final data = jsonDecode(message.toString());
      if (data is! Map) return null;
      final symbol = data[symbolKey];
      final timestamp = data[timestampKey];
      final price = data[priceKey];
      if (symbol is String && timestamp is num && price is num) {
        return Tick(
          symbol: symbol,
          timestamp: timestamp.toDouble(),
          price: price.toDouble(),
          source: source,
        );
      }
    } catch (_) {}
    return null;
  }
}
