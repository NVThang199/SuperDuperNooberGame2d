/// Wire protocol shared between `bin/server.dart` and the game client.
class ZoneStatePacket {
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> mobs;

  ZoneStatePacket(this.players, this.mobs);

  Map<String, dynamic> toJson() => {
        'type': 'ZONE_STATE',
        'players': players,
        'mobs': mobs,
      };
}
