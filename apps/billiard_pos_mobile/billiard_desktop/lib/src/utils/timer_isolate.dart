import 'dart:async';
import 'dart:isolate';

/// Background entry point for the Billiard Table Timer Isolate.
/// 
/// It listens for events from the main thread to start, stop, or clear table timings
/// and sends back a periodic map of active tables with their elapsed seconds.
void timerIsolateEntryPoint(SendPort mainSendPort) {
  final isolateReceivePort = ReceivePort();
  
  // First, send the isolate's send port back to the main thread
  mainSendPort.send(isolateReceivePort.sendPort);

  final activeTables = <String, DateTime>{};
  Timer? periodicTimer;

  // Called every 1 second to update elapsed play times
  void handleTick(Timer timer) {
    if (activeTables.isEmpty) return;
    
    final now = DateTime.now();
    final elapsedSecondsMap = <String, int>{};
    
    for (final entry in activeTables.entries) {
      elapsedSecondsMap[entry.key] = now.difference(entry.value).inSeconds;
    }
    
    mainSendPort.send({
      'type': 'tick',
      'elapsedSeconds': elapsedSecondsMap,
    });
  }

  isolateReceivePort.listen((message) {
    if (message is! Map<String, dynamic>) return;
    
    final action = message['action'];
    
    if (action == 'start') {
      final tableId = message['tableId'] as String;
      final startTimeMs = message['startTime'] as int;
      activeTables[tableId] = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
      
      periodicTimer ??= Timer.periodic(const Duration(seconds: 1), handleTick);
    } else if (action == 'stop') {
      final tableId = message['tableId'] as String;
      activeTables.remove(tableId);
      
      if (activeTables.isEmpty) {
        periodicTimer?.cancel();
        periodicTimer = null;
      }
    } else if (action == 'clear') {
      activeTables.clear();
      periodicTimer?.cancel();
      periodicTimer = null;
    }
  });
}
