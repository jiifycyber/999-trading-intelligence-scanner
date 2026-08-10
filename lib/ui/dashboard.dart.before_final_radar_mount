import 'dart:async';

import 'package:flutter/material.dart';

import '../core/scanner_engine.dart';
import '../feeds/browser_bridge_adapter.dart';
import '../feeds/demo_feed_adapter.dart';
import '../models/scan_result.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final ScannerEngine engine;
  Timer? _timer;

  String? _candidateSymbol;
  SignalSide? _candidateSide;
  int _candidateCount = 0;

  String? _lockedSymbol;
  SignalSide? _lockedSide;
  int _lockedScore = 0;
  double _entryPrice = 0;

  DateTime? _lockedAt;
  DateTime? _expiresAt;

  String? _lastResult;
  String? _lastResultSymbol;
  SignalSide? _lastResultSide;

  int wins = 0;
  int losses = 0;
  int ties = 0;

  static const int confirmationsNeeded = 3;
  static const int minimumLockScore = 80;
  static const int lockSeconds = 60;

  @override
  void initState() {
    super.initState();

    engine = ScannerEngine();

    engine.addListener(_processScanner);

    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (!mounted) return;

        _checkExpiration();

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    engine.removeListener(_processScanner);

    engine.dispose();

    super.dispose();
  }

  void _processScanner() {
    if (!mounted) return;

    final results = engine.rankedResults;

    if (results.isEmpty) {
      setState(() {});
      return;
    }

// --------------------------------------------------
// LIVE ANALYSIS KEEPS RUNNING WHILE SIGNAL IS LOCKED.
// We simply do not replace the selected locked trade.
// --------------------------------------------------

    if (_lockedSymbol != null) {
      setState(() {});
      return;
    }

    final top = results.first;

    final stable = top.stableSignal;

    if (stable == SignalSide.wait ||
        top.score < minimumLockScore ||
        top.ageMs > 2500) {
      _candidateSymbol = null;
      _candidateSide = null;
      _candidateCount = 0;

      setState(() {});
      return;
    }

    if (_candidateSymbol == top.symbol && _candidateSide == stable) {
      _candidateCount++;
    } else {
      _candidateSymbol = top.symbol;
      _candidateSide = stable;
      _candidateCount = 1;
    }

    if (_candidateCount >= confirmationsNeeded) {
      _lockSignal(
        top,
        stable,
      );
    }

    setState(() {});
  }

  void _lockSignal(
    ScanResult result,
    SignalSide side,
  ) {
    final now = DateTime.now();

    _lockedSymbol = result.symbol;
    _lockedSide = side;
    _lockedScore = result.score;
    _entryPrice = result.price;

    _lockedAt = now;

    _expiresAt = now.add(
      const Duration(
        seconds: lockSeconds,
      ),
    );

    _candidateSymbol = null;
    _candidateSide = null;
    _candidateCount = 0;

    _lastResult = null;
  }

  void _checkExpiration() {
    if (_lockedSymbol == null ||
        _expiresAt == null ||
        DateTime.now().isBefore(_expiresAt!)) {
      return;
    }

    final current = _findResult(_lockedSymbol!);

    if (current != null) {
      final difference = current.price - _entryPrice;

      if (difference.abs() < 0.000000001) {
        ties++;
        _lastResult = 'TIE';
      } else {
        final won = _lockedSide == SignalSide.call
            ? current.price > _entryPrice
            : current.price < _entryPrice;

        if (won) {
          wins++;
          _lastResult = 'WIN';
        } else {
          losses++;
          _lastResult = 'LOSS';
        }
      }

      _lastResultSymbol = _lockedSymbol;

      _lastResultSide = _lockedSide;
    } else {
      _lastResult = 'NO RESULT';
    }

    _lockedSymbol = null;
    _lockedSide = null;
    _lockedScore = 0;

    _entryPrice = 0;

    _lockedAt = null;
    _expiresAt = null;

    _candidateSymbol = null;
    _candidateSide = null;
    _candidateCount = 0;
  }

  ScanResult? _findResult(
    String symbol,
  ) {
    for (final result in engine.rankedResults) {
      if (result.symbol == symbol) {
        return result;
      }
    }

    return null;
  }

  int get _secondsLeft {
    if (_expiresAt == null) {
      return 0;
    }

    final seconds = _expiresAt!.difference(DateTime.now()).inSeconds;

    return seconds < 0 ? 0 : seconds;
  }

  double get _winRate {
    final decisive = wins + losses;

    if (decisive == 0) {
      return 0;
    }

    return wins / decisive * 100;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final results = engine.rankedResults;

    final mobile = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: mobile ? 78 : 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '999 Trading Intelligence',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'V2 • 60-Second Scanner • '
              '${engine.assetCount} assets • '
              '${engine.totalTicks} ticks',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: mobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  _feedPanel(),
                  _signalPanel(),
                  _performancePanel(),
                  _dukePanel(
                    results,
                  ),
                  _resultArea(
                    results,
                    mobile: true,
                  ),
                ],
              ),
            )
          : Row(
              children: [
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _feedPanel(),
                        _signalPanel(),
                        _performancePanel(),
                        _dukePanel(
                          results,
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                ),
                Expanded(
                  child: _resultArea(
                    results,
                    mobile: false,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _feedPanel() {
    return _panel(
      title: 'LIVE FEED',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _status(
            'Status',
            engine.status,
          ),
          _status(
            'Provider',
            engine.feedName,
          ),
          _status(
            'Assets',
            '${engine.assetCount}',
          ),
          _status(
            'Ticks',
            '${engine.totalTicks}',
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: () => engine.useFeed(
              DemoFeedAdapter(),
            ),
            icon: const Icon(
              Icons.play_arrow,
            ),
            label: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Text(
                'Run Demo Feed',
              ),
            ),
          ),
          const SizedBox(height: 9),
          FilledButton.tonalIcon(
            onPressed: () => engine.useFeed(
              BrowserBridgeAdapter(),
            ),
            icon: const Icon(
              Icons.sensors,
            ),
            label: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Text(
                'Connect Browser Bridge',
              ),
            ),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: engine.disconnect,
            icon: const Icon(
              Icons.link_off,
            ),
            label: const Text(
              'Disconnect',
            ),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: () {
              engine.clear();

              setState(() {
                _candidateSymbol = null;
                _candidateSide = null;
                _candidateCount = 0;

                _lockedSymbol = null;
                _lockedSide = null;
                _lockedScore = 0;

                _entryPrice = 0;

                _lockedAt = null;
                _expiresAt = null;

                _lastResult = null;
              });
            },
            icon: const Icon(
              Icons.delete_outline,
            ),
            label: const Text(
              'Clear Scanner',
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalPanel() {
    if (_lockedSymbol != null) {
      return _lockedPanel();
    }

    return _panel(
      title: '60-SECOND SIGNAL LOCK',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar,
                size: 22,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  _candidateSymbol == null
                      ? 'SCANNING EVERY TICK'
                      : 'CONFIRMING $_candidateSymbol',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            _candidateSymbol == null
                ? 'Every incoming tick is still analyzed. '
                    'The scanner waits for a strong setup '
                    'before selecting one.'
                : '${_sideText(_candidateSide)} • '
                    '$_candidateCount/$confirmationsNeeded '
                    'confirmation ticks',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (_candidateSymbol != null) ...[
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
              value: _candidateCount / confirmationsNeeded,
            ),
          ],
          if (_lastResult != null) ...[
            const SizedBox(
              height: 15,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                11,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .05,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAST LOCKED RESULT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${_lastResultSymbol ?? ''} '
                    '${_sideText(_lastResultSide)} '
                    '• $_lastResult',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lockedPanel() {
    final live = _lockedSymbol == null
        ? null
        : _findResult(
            _lockedSymbol!,
          );

    final liveSide = live?.stableSignal;

    final priceDiff = live == null ? 0 : live.price - _entryPrice;

    final favorable =
        _lockedSide == SignalSide.call ? priceDiff >= 0 : priceDiff <= 0;

    return _panel(
      title: '🔒 LOCKED 60-SECOND SIGNAL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lockedSymbol ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '${_sideText(_lockedSide)} '
                      '• $_lockedScore/100',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: .07,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  '${_secondsLeft}s',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dataChip(
                'ENTRY PRICE',
                _formatPrice(
                  _entryPrice,
                ),
              ),
              _dataChip(
                'LOCKED SCORE',
                '$_lockedScore/100',
              ),
              _dataChip(
                'LIVE PRICE',
                live == null
                    ? '--'
                    : _formatPrice(
                        live.price,
                      ),
              ),
              _dataChip(
                'LIVE SCORE',
                live == null ? '--' : '${live.score}/100',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: .04,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE CONDITIONS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  live == null
                      ? 'Waiting for next tick...'
                      : 'Current signal: '
                          '${_sideText(liveSide)} '
                          '${live.score}/100',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  live == null
                      ? ''
                      : favorable
                          ? 'Price is currently moving in the locked direction.'
                          : 'Price is currently moving against the locked direction.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Live analysis continues every tick. '
                  'The selected entry does not change during '
                  'the 60-second lock.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _performancePanel() {
    return _panel(
      title: 'LIVE VALIDATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dataChip(
                'WINS',
                '$wins',
              ),
              _dataChip(
                'LOSSES',
                '$losses',
              ),
              _dataChip(
                'TIES',
                '$ties',
              ),
              _dataChip(
                'WIN RATE',
                '${_winRate.toStringAsFixed(1)}%',
              ),
              _dataChip(
                'LOCK THRESHOLD',
                '$minimumLockScore/100',
              ),
              _dataChip(
                'CONFIRMATIONS',
                '$confirmationsNeeded',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Results are measured from the frozen entry price '
            'to the price approximately 60 seconds later.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dukePanel(
    List<ScanResult> results,
  ) {
    final top = results.isEmpty ? null : results.first;

    String message;

    if (_lockedSymbol != null) {
      message = '${_lockedSymbol!} is currently locked '
          '${_sideText(_lockedSide)} at '
          '$_lockedScore/100. '
          'I am continuing to monitor the live conditions '
          'without changing the original entry.';
    } else if (_candidateSymbol != null) {
      message = 'I am confirming $_candidateSymbol '
          '${_sideText(_candidateSide)}. '
          '$_candidateCount of $confirmationsNeeded '
          'confirmation ticks have passed.';
    } else if (top != null) {
      message = '${top.symbol}: ${top.recommendation}. '
          'Current confidence ${top.score}/100. '
          '${top.reason}';
    } else {
      message = 'Waiting for market data. '
          'Connect a feed to begin live analysis.';
    }

    return _panel(
      title: 'Agent Duke Da Boss X',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF6C4BA5),
                child: Icon(
                  Icons.psychology_alt,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '999 Trading Intelligence AI Analyst',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
              Icon(
                Icons.circle,
                color: Colors.greenAccent,
                size: 9,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultArea(
    List<ScanResult> results, {
    required bool mobile,
  }) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Connect a feed to begin scanning.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (mobile) {
      return Padding(
        padding: const EdgeInsets.all(
          12,
        ),
        child: Column(
          children: [
            for (int i = 0; i < results.length; i++) ...[
              _ResultCard(
                result: results[i],
              ),
              if (i != results.length - 1)
                const SizedBox(
                  height: 10,
                ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(
        16,
      ),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(
        height: 10,
      ),
      itemBuilder: (_, index) => _ResultCard(
        result: results[index],
      ),
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(
        12,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF17131F,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: .12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          child,
        ],
      ),
    );
  }

  Widget _dataChip(
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: .05,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sideText(
    SignalSide? side,
  ) {
    return switch (side) {
      SignalSide.call => 'CALL',
      SignalSide.put => 'PUT',
      _ => 'WAIT',
    };
  }

  String _formatPrice(
    double value,
  ) {
    return value.abs() >= 1000
        ? value.toStringAsFixed(
            2,
          )
        : value.toStringAsFixed(
            5,
          );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
  });

  final ScanResult result;

  @override
  Widget build(
    BuildContext context,
  ) {
    final side = result.stableSignal;

    final direction = switch (side) {
      SignalSide.call => 'CALL',
      SignalSide.put => 'PUT',
      SignalSide.wait => 'WAIT',
    };

    final icon = switch (side) {
      SignalSide.call => Icons.trending_up,
      SignalSide.put => Icons.trending_down,
      SignalSide.wait => Icons.pause_circle_outline,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(
          15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 27,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${result.source} • '
                        'age ${result.ageMs} ms',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      direction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${result.score}/100',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            LinearProgressIndicator(
              value: result.score / 100,
            ),
            const SizedBox(
              height: 13,
            ),
            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final narrow = constraints.maxWidth < 520;

                final width = narrow
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 36) / 4;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _metric(
                        'Price',
                        result.price,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _metric(
                        'EMA9',
                        result.ema9,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _metric(
                        'EMA21',
                        result.ema21,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _metric(
                        'RSI14',
                        result.rsi14,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              result.reason,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(
              height: 11,
            ),
            Container(
              padding: const EdgeInsets.all(
                11,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .04,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECOMMENDATION',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    result.recommendation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    String label,
    double value,
  ) {
    final text = label == 'RSI14'
        ? value.toStringAsFixed(
            1,
          )
        : value.abs() >= 1000
            ? value.toStringAsFixed(
                2,
              )
            : value.toStringAsFixed(
                5,
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
