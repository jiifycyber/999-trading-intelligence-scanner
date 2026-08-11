class Tick {
  final String symbol;
  final double timestamp;
  final double price;
  final String source;

  const Tick({
    required this.symbol,
    required this.timestamp,
    required this.price,
    required this.source,
  });

  DateTime get time =>
      DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).round());

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'timestamp': timestamp,
        'price': price,
        'source': source,
      };
}
