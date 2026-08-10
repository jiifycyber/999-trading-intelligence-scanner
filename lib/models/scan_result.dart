enum SignalSide { call, put, wait }

class ScanResult {
  final String symbol;
  final SignalSide side;
  final int score;
  final double price;
  final String source;
  final String reason;
  final double ema9;
  final double ema21;
  final double rsi14;
  final double velocity;
  final int ageMs;

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
  });
}
