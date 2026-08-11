import '../models/tick.dart';

abstract class FeedAdapter {
  String get name;
  Stream<Tick> get ticks;
  Future<void> connect();
  Future<void> disconnect();
  bool get isConnected;
}
