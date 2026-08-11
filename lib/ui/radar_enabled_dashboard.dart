import 'package:flutter/material.dart';

import '../core/scanner_engine.dart';
import '../models/scan_result.dart';
import 'duke_market_radar.dart';
import 'trade_x_dashboard.dart';

class RadarEnabledDashboard extends StatelessWidget {
  final ScannerEngine engine;
  final List<ScanResult> results;

  const RadarEnabledDashboard({
    super.key,
    required this.engine,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Column(
      children: [
        SizedBox(
          height: compact ? 410 : 360,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              10,
              10,
              4,
            ),
            child: DukeMarketRadar(
              results: results,
            ),
          ),
        ),
        Expanded(
          child: TradeXDashboard(
            engine: engine,
            results: results,
          ),
        ),
      ],
    );
  }
}
