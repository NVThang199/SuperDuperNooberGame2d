import 'package:flutter_test/flutter_test.dart';
import 'package:twodtestgameproject/item_loader.dart';
import 'package:twodtestgameproject/inventory.dart';

void main() {
  group('ItemLoader', () {
    test('parses CSV and returns items with correct bonuses', () async {
      final items = await ItemLoader.loadItems();
      
      expect(items, isNotEmpty);
      expect(items[0].id, '1');
      expect(items[0].name, 'Health Potion');
      expect(items[0].hpBonus, 10);
      expect(items[0].mpBonus, 0);
      expect(items[0].staminaBonus, 0);
      expect(items[0].dmgBonus, 0);
      expect(items[0].type, 'consumable');
    });

    test('loads all items from CSV', () async {
      final items = await ItemLoader.loadItems();
      expect(items.length, greaterThan(0));
    });
  });

  group('InventoryState equipment', () {
    test('allows at most eight equipped items and supports unequip', () {
      final items = List.generate(9, (i) => InventoryItem(id: '$i', name: 'Item $i'));
      final inventory = InventoryState(items: items);

      for (final item in items.take(8)) {
        expect(inventory.equip(item), isTrue);
      }
      expect(inventory.equippedCount, 8);
      expect(inventory.equip(items.last), isFalse);
      expect(inventory.unequip(items.first), isTrue);
      expect(inventory.equip(items.last), isTrue);
    });

    test('clear removes all items and equipped state', () {
      final item = InventoryItem(id: '1', name: 'Item');
      final inventory = InventoryState(items: [item]);
      inventory.equip(item);

      inventory.clear();

      expect(inventory.items, isEmpty);
      expect(inventory.equippedCount, 0);
    });
  });

  group('InventoryState equipment', () {
    test('allows at most eight equipped items and supports unequip', () {
      final items = List.generate(9, (i) => InventoryItem(id: '$i', name: 'Item $i'));
      final inventory = InventoryState(items: items);

      for (final item in items.take(8)) {
        expect(inventory.equip(item), isTrue);
      }
      expect(inventory.equippedCount, 8);
      expect(inventory.equip(items.last), isFalse);
      expect(inventory.unequip(items.first), isTrue);
      expect(inventory.equip(items.last), isTrue);
    });

    test('clear removes all items and equipped state', () {
      final item = InventoryItem(id: '1', name: 'Item');
      final inventory = InventoryState(items: [item]);
      inventory.equip(item);

      inventory.clear();

      expect(inventory.items, isEmpty);
      expect(inventory.equippedCount, 0);
    });
  });

  group('InventoryItem', () {
    test('applies stat bonuses correctly', () {
      final item = InventoryItem(
        id: '1',
        name: 'Test Item',
        hpBonus: 5,
        dmgBonus: 2,
        staminaBonus: 3,
      );

      expect(item.hpBonus, 5);
      expect(item.dmgBonus, 2);
      expect(item.staminaBonus, 3);
    });
  });
}
