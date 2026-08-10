import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../feeds/feed_adapter.dart';
import '../models/scan_result.dart';
import '../models/tick.dart';
import 'asset_state.dart';

class ScannerEngine extends ChangeNotifier {
  final Map<String, AssetState> _assets = {};
  final Map<String, ScanResult> _results = {};
  FeedAdapter? _feed;
  StreamSubscription<Tick>? _feedSub;

  int totalTicks = 0;
  DateTime? lastTickAt;
  String status = 'Disconnected';

  List<ScanResult> get rankedResults {
    final list = _results.values.toList();
    list.sort((a, b) {
      final freshA = a.ageMs <= 2500 ? 1 : 0;
      final freshB = b.ageMs <= 2500 ? 1 : 0;
      if (freshA != freshB) return freshB.compareTo(freshA);
      return b.score.compareTo(a.score);
    });
    return list;
  }

  int get assetCount => _assets.length;
  String get feedName => _feed?.name ?? 'None';
  bool get connected => _feed?.isConnected ?? false;

  Future<void> useFeed(FeedAdapter adapter) async {
    await disconnect();
    _feed = adapter;
    status = 'Connecting to ${adapter.name}...';
    notifyListeners();

    await adapter.connect();
    _feedSub = adapter.ticks.listen(
      ingestTick,
      onError: (e) {
        status = 'Feed error';
        notifyListeners();
      },
      onDone: () {
        status = 'Disconnected';
        notifyListeners();
      },
    );
    status = 'Connected';
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _feedSub?.cancel();
    _feedSub = null;
    await _feed?.disconnect();
    status = 'Disconnected';
    notifyListeners();
  }

  void ingestTick(Tick tick) {
    totalTicks++;
    lastTickAt = DateTime.now();

    final state = _assets.putIfAbsent(
      tick.symbol,
      () => AssetState(tick.symbol),
    );
    state.addTick(tick);
    _results[tick.symbol] = _scan(state, tick);
    notifyListeners();
  }

  void clear() {
    _assets.clear();
    _results.clear();
    totalTicks = 0;
    lastTickAt = null;
    notifyListeners();
  }

  ScanResult _scan(AssetState state, Tick lastTick) {
    final closes = state.candles1s.map((c) => c.close).toList();
    final ema9 = _ema(closes, 9);
    final ema21 = _ema(closes, 21);
    final rsi = _rsi(closes, 14);

    double velocity = 0;
    if (state.ticks.length >= 2) {
      final start = state.ticks[max(0, state.ticks.length - 8)];
      final end = state.ticks.last;
      final dt = max(.001, end.timestamp - start.timestamp);
      velocity = (end.price - start.price) / dt;
    }

    int call = 0;
    int put = 0;
    final reasons = <String>[];

    if (ema9 > ema21) {
      call += 24;
      reasons.add('EMA9 > EMA21');
    } else if (ema9 < ema21) {
      put += 24;
      reasons.add('EMA9 < EMA21');
    }

    if (velocity > 0) {
      call += 18;
      reasons.add('tick velocity up');
    } else if (velocity < 0) {
      put += 18;
      reasons.add('tick velocity down');
    }

    if (rsi >= 52 && rsi < 74) {
      call += 14;
      reasons.add('RSI confirms upside');
    } else if (rsi <= 48 && rsi > 26) {
      put += 14;
      reasons.add('RSI confirms downside');
    } else if (rsi >= 74 || rsi <= 26) {
      reasons.add('RSI extreme');
    }

    if (state.candles5s.length >= 3) {
      final r = state.candles5s.sublist(state.candles5s.length - 3);
      final move = r.last.close - r.first.open;
      if (move > 0) {
        call += 18;
        reasons.add('5s momentum up');
      } else if (move < 0) {
        put += 18;
        reasons.add('5s momentum down');
      }
    }

    if (state.candles15s.isNotEmpty) {
      final c = state.candles15s.last;
      if (c.bodyRatio > .55) {
        if (c.body > 0) {
          call += 12;
          reasons.add('strong 15s bullish body');
        } else if (c.body < 0) {
          put += 12;
          reasons.add('strong 15s bearish body');
        }
      }
    }

    final recent1s = state.candles1s.isNotEmpty ? state.candles1s.last : null;
    if (recent1s != null && recent1s.ticks >= 2) {
      if (call > put) {
        call += 8;
      } else if (put > call) {
        put += 8;
      }
      reasons.add('active tick flow');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final ageMs = max(0, now - lastTick.time.millisecondsSinceEpoch);

    SignalSide side = SignalSide.wait;
    int score = min(100, max(call, put));
    final spread = (call - put).abs();

    if (ageMs > 2500) {
      side = SignalSide.wait;
      score = min(score, 40);
      reasons.add('stale feed');
    } else if (score >= 64 && spread >= 18) {
      side = call > put ? SignalSide.call : SignalSide.put;
    } else {
      side = SignalSide.wait;
      score = min(score, 63);
      reasons.add('waiting for confirmation');
    }

    return ScanResult(
      symbol: state.symbol,
      side: side,
      score: score,
      price: lastTick.price,
      source: lastTick.source,
      reason: reasons.take(5).join(' • '),
      ema9: ema9,
      ema21: ema21,
      rsi14: rsi,
      velocity: velocity,
      ageMs: ageMs,
    );
  }

  double _ema(List<double> values, int period) {
    if (values.isEmpty) return 0;
    final k = 2 / (period + 1);
    double ema = values.first;
    for (final v in values.skip(1)) {
      ema = (v * k) + (ema * (1 - k));
    }
    return ema;
  }

  double _rsi(List<double> values, int period) {
    if (values.length < 2) return 50;
    final start = max(1, values.length - period);
    double gains = 0;
    double losses = 0;
    int count = 0;

    for (int i = start; i < values.length; i++) {
      final d = values[i] - values[i - 1];
      if (d >= 0) {
        gains += d;
      } else {
        losses += -d;
      }
      count++;
    }

    if (count == 0) return 50;
    final avgGain = gains / count;
    final avgLoss = losses / count;
    if (avgLoss == 0) return 100;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _feed?.disconnect();
    super.dispose();
  }
}
