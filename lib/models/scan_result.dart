enum SignalSide {
  call,
  put,
  wait,
}

class ScanResult {
  final String symbol;
  final SignalSide side;

// Scanner score is intentionally INT because
// scanner_engine.dart calculates 0-100 integer scores.
  final int score;

  final double price;
  final String source;
  final String reason;

  final double ema9;
  final double ema21;
  final double rsi14;
  final double velocity;

// Age of most recent quote/tick.
  final int ageMs;

// Optional locked-signal information.
  final SignalSide? lockedSide;
  final int? lockedScore;
  final DateTime? lockedAt;

  const ScanResult({
    required this.symbol,
    required this.side,
    required this.score,
    required this.price,
    required this.source,
    required this.reason,
    required this.ema9,
    required this.ema21,
    required this.rsi14,
    required this.velocity,
    required this.ageMs,
    this.lockedSide,
    this.lockedScore,
    this.lockedAt,
  });

  bool get bullish {
    return ema9 > ema21 && velocity > 0 && rsi14 >= 52 && rsi14 < 75;
  }

  bool get bearish {
    return ema9 < ema21 && velocity < 0 && rsi14 <= 48 && rsi14 > 25;
  }

  bool get strongBullish {
    return bullish && score >= 80;
  }

  bool get strongBearish {
    return bearish && score >= 80;
  }

  bool get stale => ageMs > 2500;

  SignalSide get stableSignal {
    if (stale) {
      return SignalSide.wait;
    }

    if (lockedSide != null) {
      return lockedSide!;
    }

    if (strongBullish) {
      return SignalSide.call;
    }

    if (strongBearish) {
      return SignalSide.put;
    }

    return SignalSide.wait;
  }

  String get recommendation {
    if (stale) {
      return 'DO NOT ENTER — STALE FEED';
    }

    switch (stableSignal) {
      case SignalSide.call:
        return score >= 85 ? 'STRONG CALL SETUP' : 'WATCH FOR CALL ENTRY';

      case SignalSide.put:
        return score >= 85 ? 'STRONG PUT SETUP' : 'WATCH FOR PUT ENTRY';

      case SignalSide.wait:
        return 'WAIT FOR CONFIRMATION';
    }
  }

  String get confidenceLabel {
    if (score >= 90) {
      return 'VERY STRONG';
    }

    if (score >= 80) {
      return 'STRONG';
    }

    if (score >= 70) {
      return 'MODERATE';
    }

    return 'WAIT';
  }

  ScanResult copyWith({
    String? symbol,
    SignalSide? side,
    int? score,
    double? price,
    String? source,
    String? reason,
    double? ema9,
    double? ema21,
    double? rsi14,
    double? velocity,
    int? ageMs,
    SignalSide? lockedSide,
    int? lockedScore,
    DateTime? lockedAt,
  }) {
    return ScanResult(
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      score: score ?? this.score,
      price: price ?? this.price,
      source: source ?? this.source,
      reason: reason ?? this.reason,
      ema9: ema9 ?? this.ema9,
      ema21: ema21 ?? this.ema21,
      rsi14: rsi14 ?? this.rsi14,
      velocity: velocity ?? this.velocity,
      ageMs: ageMs ?? this.ageMs,
      lockedSide: lockedSide ?? this.lockedSide,
      lockedScore: lockedScore ?? this.lockedScore,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }
}
