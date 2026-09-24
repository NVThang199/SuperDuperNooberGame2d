// Phase 2: Server-Authoritative WebSocket Game Loop (Dart Native)
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:twodtestgameproject/contract.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ZONE MANAGER & TICK LOOP
// ═══════════════════════════════════════════════════════════════════════════

class Zone {
  final String id;
  final Map<String, WebSocket> connections = {};
  final Map<String, Map<String, dynamic>> playerStates = {};
  final List<Map<String, dynamic>> mobs = [];

  Zone(this.id);

  void addPlayer(String userId, WebSocket socket) {
    connections[userId] = socket;
    playerStates[userId] = {
      'id': userId,
      'x': 0.0,
      'y': 0.0,
      'dir': 1,
    };
  }

  void removePlayer(String userId) {
    connections.remove(userId);
    playerStates.remove(userId);
  }

  void updatePlayer(String userId, double x, double y, int dir) {
    if (playerStates.containsKey(userId)) {
      playerStates[userId]!['x'] = x;
      playerStates[userId]!['y'] = y;
      playerStates[userId]!['dir'] = dir;
    }
  }

  void tick() {
    if (connections.isEmpty) return;

    // AI/Physics logic skipped: add when mobs/collision needed.
    
    final packet = ZoneStatePacket(
      playerStates.values.toList(),
      mobs,
    ).toJson();
    
    final payload = jsonEncode(packet);

    for (var socket in connections.values) {
      if (socket.readyState == WebSocket.open) {
        socket.add(payload);
      }
    }
  }
}

class ServerEngine {
  final Map<String, Zone> zones = {
    'zone_1': Zone('zone_1'),
  };
  Timer? loop;

  void start() {
    // 20 ticks per second = 50ms
    loop = Timer.periodic(const Duration(milliseconds: 50), (_) {
      for (var zone in zones.values) {
        zone.tick();
      }
    });
    print('Server loop started (20Hz)');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEBSOCKET SERVER
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  final engine = ServerEngine();
  engine.start();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('WebSocket Server running on ws://localhost:8080');

  await for (HttpRequest req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = await WebSocketTransformer.upgrade(req);
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      final zone = engine.zones['zone_1']!;
      zone.addPlayer(userId, socket);
      print('Client connected: $userId');

      socket.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            if (json['type'] == 'MOVE') {
              zone.updatePlayer(userId, json['x'], json['y'], json['dir']);
            }
            // Combat packets skipped: add when hitboxes needed.
          } catch (e) {
            print('Invalid packet: $e');
          }
        },
        onDone: () {
          zone.removePlayer(userId);
          print('Client disconnected: $userId');
        },
        onError: (e) {
          zone.removePlayer(userId);
          print('Client error: $userId, $e');
        },
      );
    } else {
      req.response
        ..statusCode = HttpStatus.forbidden
        ..write('WebSocket connections only')
        ..close();
    }
  }
}
