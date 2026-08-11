import 'package:flutter/material.dart';
import 'trading_chart_screen.dart';

import '../core/scanner_engine.dart';
import '../models/scan_result.dart';
import '../feeds/twelve_data_feed_adapter.dart';
import '../feeds/browser_bridge_adapter.dart';
import 'agent_duke_panel.dart';
import 'duke_market_radar.dart';

import '../feeds/demo_feed_adapter.dart';

class TradeXDashboard extends StatefulWidget {
  final ScannerEngine engine;
  final List<ScanResult> results;

  const TradeXDashboard({
    super.key,
    required this.engine,
    required this.results,
  });

  @override
  State<TradeXDashboard> createState() => _TradeXDashboardState();
}

class _TradeXDashboardState extends State<TradeXDashboard> {
  @override
  void initState() {
    super.initState();
    _autoStartDemo();
  }

  bool _autoDemoStarted = false;

  void _autoStartDemo() {
    if (_autoDemoStarted) return;
    _autoDemoStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startDemo();
    });
  }

  String timeframe = '1M';
  String assetFilter = 'ALL';
  bool topSignalsOnly = true;
  double minConfidence = 70;
  bool liveMode = false;

  ScannerEngine get engine => widget.engine;
  List<ScanResult> get results => widget.results;

  Future<void> _startDemo() async {
    setState(() => liveMode = false);
    await engine.useFeed(DemoFeedAdapter());
  }

  Future<void> _startLive() async {
    setState(() => liveMode = true);
    await engine.useFeed(TwelveDataFeedAdapter());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070A12),
      child: Column(
        children: [
          _topBar(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  child: _leftPanel(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 3,
                  child: _centerPanel(),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 330,
                  child: _rightPanel(),
                ),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E18),
        border: Border(
          bottom: BorderSide(color: Color(0xFF202536)),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open Command Center',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '999 TRADE X INTELLIGENCE',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _navButton(
                    Icons.dashboard_outlined,
                    'SCANNER',
                    true,
                    () {},
                  ),
                  _navButton(
                    Icons.candlestick_chart,
                    'CHARTS',
                    false,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: const Color(0xFF080B16),
                            appBar: AppBar(
                              backgroundColor: const Color(0xFF0B0E1A),
                              title: const Text('999 TRADE X — CHARTS'),
                            ),
                            body: TradingChartScreen(engine: engine),
                          ),
                        ),
                      );
                    },
                  ),
                  _navButton(
                    Icons.analytics_outlined,
                    'BACKTEST',
                    false,
                    () => _openFeature(context, 'BACKTEST'),
                  ),
                  _navButton(
                    Icons.psychology_alt_outlined,
                    'AGENT DUKE DA BOSS X',
                    false,
                    () => _openAgentDuke(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.circle,
            size: 10,
            color: Color(0xFF62E6AC),
          ),
          const SizedBox(width: 7),
          const Text('LIVE FEED'),
          const SizedBox(width: 22),
          const Text('142ms'),
          const SizedBox(width: 22),
          const Text(
            'PRO',
            style: TextStyle(
              color: Color(0xFFFFC84A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftPanel() {
    return Container(
      color: const Color(0xFF0A0D16),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _sectionTitle('MARKET MODE'),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _startDemo,
                  child: const Text('DEMO'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _startLive,
                  child: const Text('LIVE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('TIMEFRAME'),
          Row(
            children: [
              Expanded(
                child: _MiniChoice(
                  text: '1M',
                  selected: timeframe == '1M',
                  onTap: () {
                    engine.setTimeframeSeconds(60);
                    setState(() => timeframe = '1M');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniChoice(
                  text: '5M',
                  selected: timeframe == '5M',
                  onTap: () {
                    engine.setTimeframeSeconds(300);
                    setState(() => timeframe = '5M');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniChoice(
                  text: '15M',
                  selected: timeframe == '15M',
                  onTap: () {
                    engine.setTimeframeSeconds(900);
                    setState(() => timeframe = '15M');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('ASSETS'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChoice(
                text: 'ALL',
                selected: assetFilter == 'ALL',
                onTap: () => setState(() => assetFilter = 'ALL'),
              ),
              _MiniChoice(
                text: 'OTC',
                selected: assetFilter == 'OTC',
                onTap: () => setState(() => assetFilter = 'OTC'),
              ),
              _MiniChoice(
                text: 'CRYPTO',
                selected: assetFilter == 'CRYPTO',
                onTap: () => setState(() => assetFilter = 'CRYPTO'),
              ),
              _MiniChoice(
                text: 'STOCKS',
                selected: assetFilter == 'STOCKS',
                onTap: () => setState(() => assetFilter = 'STOCKS'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('FILTERS'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: topSignalsOnly,
            onChanged: (value) {
              setState(() => topSignalsOnly = value);
            },
            title: const Text('Top Signals Only'),
          ),
          const Text('Min. Confidence'),
          Slider(
            value: minConfidence,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${minConfidence.round()}%',
            onChanged: (value) {
              setState(() => minConfidence = value);
            },
          ),
          const SizedBox(height: 12),
          _sectionTitle('MARKET OVERVIEW'),
          _infoRow('TOTAL ASSETS', '${engine.assetCount}'),
          _infoRow('TICKS', '${engine.totalTicks}'),
          _infoRow('STATUS', engine.status),
          const SizedBox(height: 18),
          AgentDukePanel(marketContext: _dukeMarketContext()),
        ],
      ),
    );
  }

  Widget _centerPanel() {
    return Container(
      color: const Color(0xFF080B13),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'LIVE SCANNER — 1 MINUTE',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _scannerTable(),
          const SizedBox(height: 16),
          DukeMarketRadar(results: results),
          const SizedBox(height: 16),
          _chartPlaceholder(),
        ],
      ),
    );
  }

  Widget _rightPanel() {
    final top = results.isEmpty ? null : results.first;

    return Container(
      color: const Color(0xFF0A0D16),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _sectionTitle('TOP SIGNAL'),
          _topSignalCard(top),
          const SizedBox(height: 16),
          _sectionTitle('SIGNAL HISTORY'),
          _historyPlaceholder(),
          const SizedBox(height: 16),
          _sectionTitle('MARKET NEWS'),
          _newsPlaceholder(),
        ],
      ),
    );
  }

  void _openFeature(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D111C),
        child: SizedBox(
          width: 720,
          height: 480,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$feature workspace is online.',
                  style: const TextStyle(color: Colors.white60),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _dukeMarketContext() {
    final ranked = engine.rankedResults;

    return {
      'status': engine.status,
      'provider': engine.feedName,
      'assets': engine.assetCount,
      'ticks': engine.totalTicks,
      'timeframe': timeframe,
      'assetFilter': assetFilter,
      'minConfidence': minConfidence.round(),
      'topSignalsOnly': topSignalsOnly,
      'rankedResults': ranked.take(10).map((r) {
        return {
          'symbol': r.symbol,
          'side': r.side.name.toUpperCase(),
          'score': r.score,
          'price': r.price,
          'source': r.source,
          'reason': r.reason,
          'ema9': r.ema9,
          'ema21': r.ema21,
          'rsi14': r.rsi14,
          'velocity': r.velocity,
          'ageMs': r.ageMs,
        };
      }).toList(),
      'topSignal': ranked.isEmpty
          ? null
          : {
              'symbol': ranked.first.symbol,
              'side': ranked.first.side.name.toUpperCase(),
              'score': ranked.first.score,
              'price': ranked.first.price,
              'source': ranked.first.source,
              'reason': ranked.first.reason,
              'ema9': ranked.first.ema9,
              'ema21': ranked.first.ema21,
              'rsi14': ranked.first.rsi14,
              'velocity': ranked.first.velocity,
              'ageMs': ranked.first.ageMs,
            },
    };
  }

  void _openAgentDuke(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF080B13),
        child: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(22),
            child: AgentDukePanel(marketContext: _dukeMarketContext()),
          ),
        ),
      ),
    );
  }

  Widget _navButton(
    IconData icon,
    String text,
    bool selected,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(text),
        style: FilledButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xFF4C27A8) : const Color(0xFF121522),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFFCAB7FF),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerTable() {
    if (results.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0D111C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF242A3A)),
        ),
        child: const Text(
          'Connect a feed to begin scanning.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D111C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242A3A)),
      ),
      child: Column(
        children: results.take(10).map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF202536)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    r.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${r.score}/100',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF62E6AC),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartPlaceholder() {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242A3A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1-MINUTE MARKET CHART',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          Spacer(),
          Center(
            child: Icon(
              Icons.candlestick_chart,
              size: 80,
              color: Colors.white24,
            ),
          ),
          Spacer(),
          Text(
            'EMA 9 • EMA 21 • RSI 14 • Momentum',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _topSignalCard(ScanResult? top) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF302451)),
      ),
      child: top == null
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Waiting for market data...',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  top.symbol,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${top.score}/100',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF62E6AC),
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: top.score / 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'REASONING',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  top.reason,
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
    );
  }

  Widget _historyPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242A3A)),
      ),
      child: const Text(
        'Signals will appear here as trades are validated.',
        style: TextStyle(
          color: Colors.white60,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _newsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242A3A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market news feed ready'),
          SizedBox(height: 10),
          Text(
            'Live headlines will be connected here.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E18),
        border: Border(
          top: BorderSide(color: Color(0xFF202536)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            size: 9,
            color: Color(0xFF62E6AC),
          ),
          const SizedBox(width: 7),
          const Text('CONNECTION: STABLE'),
          const Spacer(),
          Text('ASSETS ${engine.assetCount}'),
          const SizedBox(width: 28),
          Text('TICKS ${engine.totalTicks}'),
          const SizedBox(width: 28),
          const Text('999 INTELLIGENCE ACTIVE'),
        ],
      ),
    );
  }
}

class _MiniChoice extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const _MiniChoice({
    required this.text,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4C27A8) : const Color(0xFF121522),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF7046D8) : const Color(0xFF242A3A),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
