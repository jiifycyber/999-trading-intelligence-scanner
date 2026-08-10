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

  @override
  void initState() {
    super.initState();
    engine = ScannerEngine();
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final results = engine.rankedResults;
        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('999 Trading Intelligence',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                Text('V2 • 60-Second Multi-Asset Scanner',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${engine.assetCount} assets • ${engine.totalTicks} ticks',
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              SizedBox(
                width: 320,
                child: Container(
                  color: const Color(0xFF0B1018),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('LIVE FEED',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      _statusRow('Status', engine.status),
                      _statusRow('Provider', engine.feedName),
                      _statusRow('Assets', '${engine.assetCount}'),
                      _statusRow('Ticks', '${engine.totalTicks}'),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => engine.useFeed(DemoFeedAdapter()),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run Demo Feed'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            engine.useFeed(BrowserBridgeAdapter()),
                        icon: const Icon(Icons.sensors),
                        label: const Text('Connect Browser Bridge'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: engine.disconnect,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: engine.clear,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Scanner'),
                      ),
                      const Spacer(),
                      Text(
                        'Browser Bridge receives sanitized quote messages only: '
                        'symbol + timestamp + price. No passwords, cookies, SID, '
                        'or session tokens are stored in this app.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: .55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: results.isEmpty
                      ? const Center(
                          child: Text(
                            'Connect a feed to begin scanning.',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) =>
                              _ResultCard(result: results[index]),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(color: Colors.white.withValues(alpha: .55))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final label = switch (result.side) {
      SignalSide.call => 'CALL',
      SignalSide.put => 'PUT',
      SignalSide.wait => 'WAIT',
    };
    final icon = switch (result.side) {
      SignalSide.call => Icons.trending_up,
      SignalSide.put => Icons.trending_down,
      SignalSide.wait => Icons.pause_circle_outline,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.symbol,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(
                        '${result.source} • age ${result.ageMs} ms',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: .55),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('${result.score}/100'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: result.score / 100),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metric('Price', result.price)),
                Expanded(child: _metric('EMA9', result.ema9)),
                Expanded(child: _metric('EMA21', result.ema21)),
                Expanded(child: _metric('RSI14', result.rsi14)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                result.reason,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .65),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String name, double value) {
    String s;
    if (name == 'RSI14') {
      s = value.toStringAsFixed(1);
    } else {
      s = value.abs() >= 1000
          ? value.toStringAsFixed(2)
          : value.toStringAsFixed(5);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .45), fontSize: 10)),
        Text(s, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
