import 'package:flutter_test/flutter_test.dart';
import 'package:twodtestgameproject/item_loader.dart';
import 'package:twodtestgameproject/inventory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    test('allows at most twelve equipped items with type matching', () {
      final items = [
        InventoryItem(id: '1', name: 'Ring', type: 'ring'),
        InventoryItem(id: '2', name: 'Ring2', type: 'ring'),
        InventoryItem(id: '3', name: 'Necklace', type: 'necklace'),
        InventoryItem(id: '4', name: 'Bracer', type: 'bracer'),
        InventoryItem(id: '5', name: 'Bracer2', type: 'bracer'),
        InventoryItem(id: '6', name: 'Armor', type: 'armor'),
        InventoryItem(id: '7', name: 'Weapon', type: 'weapon'),
        InventoryItem(id: '8', name: 'Weapon2', type: 'weapon'),
        InventoryItem(id: '9', name: 'Shield', type: 'shield'),
        InventoryItem(id: '10', name: 'Helm', type: 'helm'),
        InventoryItem(id: '11', name: 'Boots', type: 'boots'),
        InventoryItem(id: '12', name: 'Belt', type: 'belt'),
        InventoryItem(id: '13', name: 'Artifact', type: 'artifact'),
        InventoryItem(id: '14', name: 'Extra', type: 'artifact'),
      ];
      final inventory = InventoryState(items: items);

      for (final item in items.take(12)) {
        expect(inventory.equip(item), isTrue, reason: 'Should equip ${item.name}');
      }
      expect(inventory.equippedCount, 12);
      expect(inventory.equip(items[13]), isFalse, reason: 'Should reject when full');
      expect(inventory.unequip(items.first), isTrue);
      expect(inventory.equip(items[13]), isTrue, reason: 'Should equip after unequip');
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
