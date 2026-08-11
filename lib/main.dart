import 'package:flutter/material.dart';
import 'ui/dashboard.dart';

void main() {
  runApp(const TradingIntelligenceApp());
}

class TradingIntelligenceApp extends StatelessWidget {
  const TradingIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '999 Trading Intelligence',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A10),
        cardColor: const Color(0xFF111722),
      ),
      home: const Dashboard(),
    );
  }
}
