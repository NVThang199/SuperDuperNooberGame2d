import 'package:flutter_test/flutter_test.dart';
import 'package:twodtestgameproject/inventory.dart';
import 'package:twodtestgameproject/item_loader.dart';

void main() {
  group('InventoryState Search & Filter', () {
    late List<InventoryItem> items;

    setUp(() {
      items = [
        InventoryItem(id: '1', name: 'Sword', rarity: 'rare', type: 'weapon', description: 'Sharp blade'),
        InventoryItem(id: '2', name: 'Shield', rarity: 'common', type: 'armor', description: 'Protection'),
        InventoryItem(id: '3', name: 'Potion', rarity: 'common', type: 'consumable', description: 'Restore health'),
        InventoryItem(id: '4', name: 'Legendary Sword', rarity: 'legendary', type: 'weapon', description: 'Epic blade'),
      ];
    });

    test('search by name returns matching items', () {
      final inventory = InventoryState(items: items);
      final results = inventory.search('Sword');
      expect(results.length, 2);
      expect(results[0].name, 'Sword');
      expect(results[1].name, 'Legendary Sword');
    });

    test('search by description returns matching items', () {
      final inventory = InventoryState(items: items);
      final results = inventory.search('blade');
      expect(results.length, 2);
    });

    test('search is case-insensitive', () {
      final inventory = InventoryState(items: items);
      final results = inventory.search('SWORD');
      expect(results.length, 2);
    });

    test('search returns empty when no match', () {
      final inventory = InventoryState(items: items);
      final results = inventory.search('nonexistent');
      expect(results.isEmpty, true);
    });

    test('filter by rarity returns matching items', () {
      final inventory = InventoryState(items: items);
      final results = inventory.filter(rarity: 'common');
      expect(results.length, 2);
    });

    test('filter by type returns matching items', () {
      final inventory = InventoryState(items: items);
      final results = inventory.filter(type: 'weapon');
      expect(results.length, 2);
    });

    test('filter by rarity and type returns matching items', () {
      final inventory = InventoryState(items: items);
      final results = inventory.filter(rarity: 'common', type: 'consumable');
      expect(results.length, 1);
      expect(results[0].name, 'Potion');
    });

    test('filter returns all when no filters applied', () {
      final inventory = InventoryState(items: items);
      final results = inventory.filter();
      expect(results.length, 4);
    });

    test('search and filter combination works', () {
      final inventory = InventoryState(items: items);
      final filtered = inventory.filter(type: 'weapon');
      final searched = inventory.search('Sword', filtered);
      expect(searched.length, 2);
    });
  });

  group('ItemLoader', () {
    test('loadItems loads correct number of items', () async {
      final items = await ItemLoader.loadItems();
      expect(items.length, 2192);
      expect(items.first.name, 'item_1');
      expect(items.first.defenseBonus, inInclusiveRange(0, 16));
    });

    test('rarity distribution approximates 50/25/15/8/2%', () async {
      final items = await ItemLoader.loadItems();
      final counts = <String, int>{};
      for (var item in items) {
        counts[item.rarity] = (counts[item.rarity] ?? 0) + 1;
      }

      expect(counts['common'], greaterThan(1000));
      expect(counts['uncommon'], greaterThan(500));
      expect(counts['rare'], greaterThan(300));
      expect(counts['epic'], greaterThan(150));
      expect(counts['legendary'], greaterThan(30));
    });

    test('stat ranges match rarity spec', () async {
      final items = await ItemLoader.loadItems();

      final rangesByRarity = {
        'common': {
          'hp': [0, 5],
          'mp': [0, 3],
          'stamina': [0, 3],
          'dmg': [0, 3],
          'defense': [0, 2],
        },
        'uncommon': {
          'hp': [4, 10],
          'mp': [3, 7],
          'stamina': [3, 7],
          'dmg': [3, 7],
          'defense': [2, 5],
        },
        'rare': {
          'hp': [9, 15],
          'mp': [7, 12],
          'stamina': [7, 12],
          'dmg': [7, 12],
          'defense': [5, 8],
        },
        'epic': {
          'hp': [14, 20],
          'mp': [12, 18],
          'stamina': [12, 18],
          'dmg': [12, 18],
          'defense': [8, 12],
        },
        'legendary': {
          'hp': [19, 25],
          'mp': [17, 24],
          'stamina': [17, 24],
          'dmg': [17, 24],
          'defense': [12, 16],
        },
      };

      for (var item in items) {
        final ranges = rangesByRarity[item.rarity]!;
        expect(
          item.hpBonus,
          inInclusiveRange(ranges['hp']![0], ranges['hp']![1]),
        );
        expect(
          item.mpBonus,
          inInclusiveRange(ranges['mp']![0], ranges['mp']![1]),
        );
        expect(
          item.staminaBonus,
          inInclusiveRange(ranges['stamina']![0], ranges['stamina']![1]),
        );
        expect(
          item.dmgBonus,
          inInclusiveRange(ranges['dmg']![0], ranges['dmg']![1]),
        );
        expect(
          item.defenseBonus,
          inInclusiveRange(ranges['defense']![0], ranges['defense']![1]),
        );
      }
    });
  });
}
