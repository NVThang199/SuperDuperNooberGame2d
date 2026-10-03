import 'package:flutter/services.dart' show rootBundle;

import 'inventory.dart';

class ItemLoader {
  static Future<List<InventoryItem>> loadItems() async {
    final csv = await rootBundle.loadString('assets/item/items.csv');
    final lines = csv.split('\n').skip(1);
    return lines.where((line) => line.isNotEmpty).map((line) {
      final parts = line.split(',');
      if (parts.length != 17) {
        throw FormatException(
          'Expected 17 columns, got ${parts.length}: $line',
        );
      }
      final type = parts[4];
      final validTypes = {
        'ring', 'necklace', 'bracer', 'weapon', 'bow', 'shield', 
        'belt', 'artifact', 'cape',
        'light helm', 'medium helm', 'heavy helm',
        'light armor', 'medium armor', 'heavy armor',
        'light boots', 'medium boots', 'heavy boots',
      };
      if (!validTypes.contains(type)) {
        throw FormatException('Invalid item type: $type');
      }
      return InventoryItem(
        id: parts[0],
        name: parts[1],
        imagePath: parts[2],
        rarity: parts[3],
        type: type,
        hpBonus: int.parse(parts[5]),
        mpBonus: int.parse(parts[6]),
        staminaBonus: int.parse(parts[7]),
        dmgBonus: int.parse(parts[8]),
        defenseBonus: int.parse(parts[9]),
        description: parts[10].trim(),
        attack1Path: parts[11].trim(),
        attack2Path: parts[12].trim(),
        squatAttackPath: parts[13].trim(),
        attack1TextureWidth: int.tryParse(parts[14].trim()) ?? 120,
        attack2TextureWidth: int.tryParse(parts[15].trim()) ?? 120,
        squatAttackTextureWidth: int.tryParse(parts[16].trim()) ?? 120,
      );
    }).toList();
  }
}
