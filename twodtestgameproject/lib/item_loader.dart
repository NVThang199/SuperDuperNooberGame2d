import 'package:flutter/services.dart' show rootBundle;

import 'inventory.dart';

class ItemLoader {
  static Future<List<InventoryItem>> loadItems() async {
    final csv = await rootBundle.loadString('assets/item/items.csv');
    final lines = csv.split('\n').skip(1);
    return lines.where((line) => line.isNotEmpty).map<InventoryItem>((line) {
      final parts = line.split(',');
      if (parts.length != 11) {
        throw FormatException(
          'Expected 11 columns, got ${parts.length}: $line',
        );
      }
      final type = parts[4];
      if (!{
        'ring', 'necklace', 'bracer', 'armor', 'weapon', 'shield', 
        'helm', 'boots', 'belt', 'artifact', 'cape'
      }.contains(type)) {
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
      );
      }).toList();
  }
}
