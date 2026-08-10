import 'dart:math';

class Candle {
  final int bucket;
  double open;
  double high;
  double low;
  double close;
  int ticks;

  Candle({
    required this.bucket,
    required double price,
  })  : open = price,
        high = price,
        low = price,
        close = price,
        ticks = 1;

  void add(double value) {
    high = max(high, value);
    low = min(low, value);
    close = value;
    ticks++;
  }

  double get body => close - open;
  double get range => max(1e-12, high - low);
  double get bodyRatio => body.abs() / range;
}
