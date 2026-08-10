import 'scan_result.dart';

class LockedSignal {
final String symbol;
final SignalSide lockedSide;
final int lockedScore;
final double entryPrice;
final DateTime entryTime;
final DateTime expiresAt;

final SignalSide liveSide;
final int liveScore;
final double livePrice;

const LockedSignal({
required this.symbol,
required this.lockedSide,
required this.lockedScore,
required this.entryPrice,
required this.entryTime,
required this.expiresAt,
required this.liveSide,
required this.liveScore,
required this.livePrice,
});

LockedSignal copyLive({
required SignalSide side,
required int score,
required double price,
}) {
return LockedSignal(
symbol: symbol,
lockedSide: lockedSide,
lockedScore: lockedScore,
entryPrice: entryPrice,
entryTime: entryTime,
expiresAt: expiresAt,
liveSide: side,
liveScore: score,
livePrice: price,
);
}
}
