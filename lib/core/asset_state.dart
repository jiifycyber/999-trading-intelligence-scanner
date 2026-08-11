import '../models/candle.dart';
import '../models/tick.dart';

class AssetState {
  AssetState(this.symbol);

  final String symbol;
  final List<Tick> ticks = [];
  final List<Candle> candles1s = [];
  final List<Candle> candles5s = [];
  final List<Candle> candles15s = [];
  final List<Candle> candles60s = [];

  void addTick(Tick tick) {
    ticks.add(tick);
    if (ticks.length > 5000) {
      ticks.removeRange(0, ticks.length - 5000);
    }
    _add(candles1s, tick, 1);
    _add(candles5s, tick, 5);
    _add(candles15s, tick, 15);
    _add(candles60s, tick, 60);
  }

  void _add(List<Candle> candles, Tick tick, int seconds) {
    final bucket = (tick.timestamp / seconds).floor();
    if (candles.isEmpty || candles.last.bucket != bucket) {
      candles.add(Candle(bucket: bucket, price: tick.price));
      if (candles.length > 1000) candles.removeAt(0);
    } else {
      candles.last.add(tick.price);
    }
  }
}
