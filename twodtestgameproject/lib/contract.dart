// Phase 1: In-memory domain models & WebSocket protocol (no DB)

// ═══════════════════════════════════════════════════════════════════════════
// DOMAIN MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum Planet { earth, namek, saiyan }

class Coordinates {
  final double x;
  final double y;
  final String zoneId;

  Coordinates(this.x, this.y, this.zoneId);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'zoneId': zoneId};
  factory Coordinates.fromJson(Map<String, dynamic> m) =>
      Coordinates(m['x'], m['y'], m['zoneId']);
}

class Item {
  final String id;
  final String name;
  final int quantity;

  Item(this.id, this.name, this.quantity);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'qty': quantity};
  factory Item.fromJson(Map<String, dynamic> m) =>
      Item(m['id'], m['name'], m['qty']);
}

class Character {
  final String userId;
  final String name;
  final Planet planet;
  int powerLevel;
  int ki;
  int hp;
  int maxHp;
  int gold;
  Coordinates coords;
  final List<Item> inventory;

  Character({
    required this.userId,
    required this.name,
    required this.planet,
    required this.powerLevel,
    required this.ki,
    required this.hp,
    required this.maxHp,
    required this.gold,
    required this.coords,
    required this.inventory,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'planet': planet.name,
        'powerLevel': powerLevel,
        'ki': ki,
        'hp': hp,
        'maxHp': maxHp,
        'gold': gold,
        'coords': coords.toJson(),
        'inventory': inventory.map((i) => i.toJson()).toList(),
      };

  factory Character.fromJson(Map<String, dynamic> m) => Character(
        userId: m['userId'],
        name: m['name'],
        planet: Planet.values.byName(m['planet']),
        powerLevel: m['powerLevel'],
        ki: m['ki'],
        hp: m['hp'],
        maxHp: m['maxHp'],
        gold: m['gold'],
        coords: Coordinates.fromJson(m['coords']),
        inventory: (m['inventory'] as List).map((i) => Item.fromJson(i)).toList(),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// NETWORK PROTOCOL
// ═══════════════════════════════════════════════════════════════════════════

abstract class NetworkPacket {
  final String type;
  NetworkPacket(this.type);
  Map<String, dynamic> toJson();
}

// Client → Server
class MovePacket extends NetworkPacket {
  final double x;
  final double y;
  final int direction;

  MovePacket(this.x, this.y, this.direction) : super('MOVE');

  @override
  Map<String, dynamic> toJson() => {'type': type, 'x': x, 'y': y, 'dir': direction};
}

class AttackPacket extends NetworkPacket {
  final String targetId;

  AttackPacket(this.targetId) : super('ATTACK');

  @override
  Map<String, dynamic> toJson() => {'type': type, 'targetId': targetId};
}

class SkillPacket extends NetworkPacket {
  final String skillId;
  final double x;
  final double y;

  SkillPacket(this.skillId, this.x, this.y) : super('SKILL');

  @override
  Map<String, dynamic> toJson() => {'type': type, 'skillId': skillId, 'x': x, 'y': y};
}

// Server → Client
class ZoneStatePacket extends NetworkPacket {
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> mobs;

  ZoneStatePacket(this.players, this.mobs) : super('ZONE_STATE');

  @override
  Map<String, dynamic> toJson() => {'type': type, 'players': players, 'mobs': mobs};
}

class DamagePacket extends NetworkPacket {
  final String targetId;
  final int damage;
  final int remainingHp;

  DamagePacket(this.targetId, this.damage, this.remainingHp) : super('DAMAGE');

  @override
  Map<String, dynamic> toJson() =>
      {'type': type, 'targetId': targetId, 'dmg': damage, 'hp': remainingHp};
}

class ZoneChangePacket extends NetworkPacket {
  final String newZoneId;

  ZoneChangePacket(this.newZoneId) : super('ZONE_CHANGE');

  @override
  Map<String, dynamic> toJson() => {'type': type, 'zoneId': newZoneId};
}
