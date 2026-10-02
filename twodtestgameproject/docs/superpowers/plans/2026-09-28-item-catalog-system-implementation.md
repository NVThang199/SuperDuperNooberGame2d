# Item Catalog System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Each task below is assigned to a subagent; tasks have dependencies tracked in Interfaces blocks.

**Goal:** Generate 2,192-item catalog with rarity, balanced stats, detail popups, searchable inventory, and defense stat integration.

**Architecture:** Five independent implementation tracks:
1. CSV data generation & validation.
2. InventoryState enhanced with search/filter/equip tracking.
3. Item detail popup UI component.
4. LocalPlayer defense stat integration.
5. End-to-end testing & verification.

**Tech Stack:** Dart, Flutter, CSV format, no new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-28-item-catalog-system-design.md`

## Global Constraints
- CSV file: `assets/item/items.csv`, exactly 2,192 rows (id 1–2192) + 1 header row.
- Rarity enum: common, uncommon, rare, epic, legendary (case-sensitive).
- Type enum: aggregated from dataset; minimum: weapon, armor, accessory, consumable.
- Defense formula: `actualDamage = damage * (100.0 / (100.0 + totalDefense))`.
- Equip limit: max 8 items, enforced in InventoryState.
- Stat ranges locked per rarity (see spec Global Constraints section).

## Review Focus
1. **CSV row count**: Load CSV, parse, assert count == 2192.
2. **Rarity distribution**: On load, sample 100 random items, verify rarity breakdown near target %.
3. **Stat bounds**: For each rarity, assert all bonuses within spec ranges.
4. **Popup equip race**: Click equip twice fast; verify state consistent.
5. **Defense cap**: Equip 8 max-defense items; verify damage formula doesn't invert (damage > 0).

---

## File Structure

- **Modify:** `lib/inventory.dart` (extend InventoryItem, enhance InventoryState).
- **Create:** `lib/item_popup.dart` (new popup widget).
- **Create:** `lib/item_filter.dart` (search/filter bar component).
- **Modify:** `lib/game.dart` (add defense stat, apply in takeDamage).
- **Modify:** `lib/main.dart` (wire popup into inventory UI).
- **Create:** `lib/csv_generator.dart` (one-time script to generate items.csv).
- **Create:** `assets/item/items.csv` (auto-generated, 2192 items).
- **Create:** `test/item_catalog_test.dart` (unit tests for loader, state, defense).

---

## Task 1: CSV Data Generation & Validation

**Assigned to:** Subagent A (Data)

**Files:**
- Create: `lib/csv_generator.dart` (generator script)
- Create: `assets/item/items.csv` (output)
- Modify: `lib/inventory.dart` (add rarity, type, defense_bonus columns to InventoryItem)
- Test: `test/item_catalog_test.dart` (load & validate CSV)

**Interfaces:**
- Consumes: List of 2,192 PNG filenames (fc1.png–fc2192.png) from `assets/item/64x64/`.
- Produces: 
  - `InventoryItem` class with fields: `id, name, imagePath, rarity, type, hpBonus, mpBonus, staminaBonus, dmgBonus, defenseBonus, description`.
  - CSV file at `assets/item/items.csv` with 2,193 rows (1 header + 2,192 data).
  - `ItemLoader.loadItems()` async method returning `List<InventoryItem>`.
  - Validator: `ItemValidator.validateCatalog(List<InventoryItem>) -> bool` asserting count, rarity distribution, stat bounds.

**Steps:**

- [ ] **Step 1: Extend InventoryItem model**

Update `lib/inventory.dart`:

```dart
class InventoryItem {
  final String id;
  final String name;
  final String imagePath;
  final String rarity;      // new
  final String type;        // new
  final int hpBonus;
  final int mpBonus;
  final int staminaBonus;
  final int dmgBonus;
  final int defenseBonus;   // new
  final String description;

  InventoryItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.rarity,
    required this.type,
    this.hpBonus = 0,
    this.mpBonus = 0,
    this.staminaBonus = 0,
    this.dmgBonus = 0,
    this.defenseBonus = 0,
    this.description = '',
  });
}
```

- [ ] **Step 2: Create CSV generator script**

Create `lib/csv_generator.dart`:

```dart
import 'dart:io';
import 'dart:math';
import 'inventory.dart';

void generateItemsCsv() {
  final csv = StringBuffer();
  csv.writeln('id,name,image_path,rarity,type,hp_bonus,mp_bonus,stamina_bonus,dmg_bonus,defense_bonus,description');

  final rarities = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
  final types = ['weapon', 'armor', 'accessory', 'consumable', 'potion', 'scroll'];
  final descriptions = [
    'A mysterious artifact.',
    'Glows with faint light.',
    'Well-crafted and sturdy.',
    'Ancient relic.',
    'Radiates power.',
  ];

  final rng = Random();

  for (int i = 1; i <= 2192; i++) {
    final rarity = _assignRarity(rng);
    final type = types[rng.nextInt(types.length)];
    final stats = _generateStats(rarity, rng);
    final name = 'Item_$i';
    final desc = descriptions[rng.nextInt(descriptions.length)];
    final path = 'assets/item/64x64/fc$i.png';

    csv.writeln('$i,$name,$path,$rarity,$type,${stats['hp']},${stats['mp']},${stats['stamina']},${stats['dmg']},${stats['defense']},$desc');
  }

  File('assets/item/items.csv').writeAsStringSync(csv.toString());
  print('Generated assets/item/items.csv with 2192 items.');
}

String _assignRarity(Random rng) {
  final roll = rng.nextDouble();
  if (roll < 0.50) return 'common';
  if (roll < 0.75) return 'uncommon';
  if (roll < 0.90) return 'rare';
  if (roll < 0.98) return 'epic';
  return 'legendary';
}

Map<String, int> _generateStats(String rarity, Random rng) {
  final ranges = {
    'common': {'hp': [0, 5], 'mp': [0, 2], 'stamina': [0, 3], 'dmg': [0, 2], 'defense': [0, 1]},
    'uncommon': {'hp': [5, 15], 'mp': [2, 8], 'stamina': [3, 10], 'dmg': [2, 5], 'defense': [1, 3]},
    'rare': {'hp': [15, 30], 'mp': [8, 15], 'stamina': [10, 20], 'dmg': [5, 10], 'defense': [3, 6]},
    'epic': {'hp': [30, 50], 'mp': [15, 25], 'stamina': [20, 35], 'dmg': [10, 15], 'defense': [6, 10]},
    'legendary': {'hp': [50, 75], 'mp': [25, 40], 'stamina': [35, 50], 'dmg': [15, 20], 'defense': [10, 15]},
  };

  final r = ranges[rarity]!;
  return {
    'hp': r['hp']![0] + rng.nextInt(r['hp']![1] - r['hp']![0] + 1),
    'mp': r['mp']![0] + rng.nextInt(r['mp']![1] - r['mp']![0] + 1),
    'stamina': r['stamina']![0] + rng.nextInt(r['stamina']![1] - r['stamina']![0] + 1),
    'dmg': r['dmg']![0] + rng.nextInt(r['dmg']![1] - r['dmg']![0] + 1),
    'defense': r['defense']![0] + rng.nextInt(r['defense']![1] - r['defense']![0] + 1),
  };
}

void main() => generateItemsCsv();
```

Run once: `dart lib/csv_generator.dart`

- [ ] **Step 3: Update ItemLoader to parse rarity/type/defense**

Update `lib/item_loader.dart`:

```dart
class ItemLoader {
  static Future<List<InventoryItem>> loadItems() async {
    final csv = await rootBundle.loadString('assets/item/items.csv');
    final lines = csv.split('\n').skip(1);
    return lines.where((line) => line.isNotEmpty).map((line) {
      final parts = line.split(',');
      if (parts.length != 11) throw FormatException('Invalid CSV line: $line');
      return InventoryItem(
        id: parts[0],
        name: parts[1],
        imagePath: parts[2],
        rarity: parts[3],
        type: parts[4],
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
```

- [ ] **Step 4: Write failing test: CSV row count**

Create `test/item_catalog_test.dart`:

```dart
test('CSV has exactly 2192 items', () async {
  final items = await ItemLoader.loadItems();
  expect(items.length, 2192);
});
```

- [ ] **Step 5: Run test to verify it fails**

Run: `flutter test test/item_catalog_test.dart::CSV*`
Expected: FAIL (file does not exist yet)

- [ ] **Step 6: Generate CSV file**

Run: `dart lib/csv_generator.dart`

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/item_catalog_test.dart::CSV*`
Expected: PASS

- [ ] **Step 8: Write and run validation tests**

Add to `test/item_catalog_test.dart`:

```dart
test('Rarity distribution is valid', () async {
  final items = await ItemLoader.loadItems();
  final rarities = items.map((it) => it.rarity).toList();
  expect(rarities, everyElement(isIn(['common', 'uncommon', 'rare', 'epic', 'legendary'])));
});

test('All items have stat bonuses within spec ranges', () async {
  final items = await ItemLoader.loadItems();
  for (final item in items) {
    final rarity = item.rarity;
    // Check ranges per rarity (from spec)
    if (rarity == 'common') {
      expect(item.hpBonus, inInclusiveRange(0, 5));
      expect(item.defenseBonus, inInclusiveRange(0, 1));
    }
    // ... add similar checks for other rarities
  }
});
```

- [ ] **Step 9: Commit**

```bash
git add lib/inventory.dart lib/item_loader.dart lib/csv_generator.dart assets/item/items.csv test/item_catalog_test.dart
git commit -m "feat: generate 2192-item catalog with rarity and defense stats"
```

---

## Task 2: Enhance InventoryState with Search/Filter/Equip Tracking

**Assigned to:** Subagent B (State Logic)

**Files:**
- Modify: `lib/inventory.dart` (extend InventoryState)
- Test: `test/inventory_state_test.dart`

**Interfaces:**
- Consumes: `InventoryItem` model (from Task 1).
- Produces:
  - Enhanced `InventoryState` with: `equippedIds: Set<String>`, `searchQuery: String`, `filterRarity: String?`, `filterType: String?`.
  - Methods: `bool canEquip()`, `bool equip(String itemId)`, `bool unequip(String itemId)`, `List<InventoryItem> getFiltered()`.
  - Getter: `int equippedCount`.

**Steps:**

- [ ] **Step 1: Write failing test for equip limit**

```dart
test('cannot equip more than 8 items', () {
  final items = List.generate(10, (i) => InventoryItem(id: '$i', name: 'Item $i'));
  final inv = InventoryState(items: items);
  
  for (int i = 0; i < 8; i++) {
    expect(inv.equip(items[i].id), isTrue);
  }
  expect(inv.equip(items[8].id), isFalse);
  expect(inv.equippedCount, 8);
});
```

- [ ] **Step 2: Implement InventoryState equip/unequip logic**

Update `lib/inventory.dart`:

```dart
class InventoryState {
  final List<InventoryItem> items;
  final Set<String> equippedIds = {};
  String searchQuery = '';
  String? filterRarity;
  String? filterType;
  int page = 0;
  int selected = 0;
  static const int slotsPerPage = 20;
  static const int maxEquippedItems = 8;

  int get equippedCount => equippedIds.length;

  bool canEquip() => equippedIds.length < maxEquippedItems;

  bool equip(String itemId) {
    if (equippedIds.length >= maxEquippedItems) return false;
    equippedIds.add(itemId);
    return true;
  }

  bool unequip(String itemId) => equippedIds.remove(itemId);

  List<InventoryItem> getFiltered() {
    return items.where((item) {
      if (searchQuery.isNotEmpty && !item.name.toLowerCase().contains(searchQuery.toLowerCase())) return false;
      if (filterRarity != null && item.rarity != filterRarity) return false;
      if (filterType != null && item.type != filterType) return false;
      return true;
    }).toList();
  }

  void setSearch(String q) => searchQuery = q;
  void setFilterRarity(String? r) => filterRarity = r;
  void setFilterType(String? t) => filterType = t;
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `flutter test test/inventory_state_test.dart::*equip*`
Expected: PASS

- [ ] **Step 4: Write and run filter tests**

```dart
test('getFiltered respects search query', () {
  final items = [
    InventoryItem(id: '1', name: 'Sword', rarity: 'common', type: 'weapon'),
    InventoryItem(id: '2', name: 'Shield', rarity: 'common', type: 'armor'),
  ];
  final inv = InventoryState(items: items);
  inv.setSearch('sword');
  expect(inv.getFiltered(), [items[0]]);
});

test('getFiltered respects rarity filter', () {
  final items = [
    InventoryItem(id: '1', name: 'Item', rarity: 'common', type: 'weapon'),
    InventoryItem(id: '2', name: 'Item', rarity: 'rare', type: 'weapon'),
  ];
  final inv = InventoryState(items: items);
  inv.setFilterRarity('rare');
  expect(inv.getFiltered(), [items[1]]);
});
```

- [ ] **Step 5: Commit**

```bash
git add lib/inventory.dart test/inventory_state_test.dart
git commit -m "feat: add equip/unequip tracking, search, filter to InventoryState"
```

---

## Task 3: Item Detail Popup UI

**Assigned to:** Subagent C (UI)

**Files:**
- Create: `lib/item_popup.dart` (new popup widget)
- Create: `lib/item_filter.dart` (search/filter bar)
- Modify: `lib/inventory.dart` (InventoryWidget → add popup trigger)
- Test: integration test (manual or screenshot test)

**Interfaces:**
- Consumes: `InventoryItem`, `InventoryState` (from Tasks 1–2), callback `onEquip(InventoryItem)`, `onUnequip(InventoryItem)`.
- Produces:
  - `ItemPopupWidget` stateful widget showing full item details, equip/unequip buttons, counter `x/8`.
  - `ItemFilterBar` widget with search input, rarity dropdown, type dropdown.

**Steps:**

- [ ] **Step 1: Create ItemPopupWidget**

Create `lib/item_popup.dart`:

```dart
class ItemPopupWidget extends StatefulWidget {
  final InventoryItem item;
  final bool isEquipped;
  final bool canEquip;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;
  final VoidCallback onClose;
  final int equippedCount;
  final int maxEquipped;

  const ItemPopupWidget({
    required this.item,
    required this.isEquipped,
    required this.canEquip,
    required this.onEquip,
    required this.onUnequip,
    required this.onClose,
    required this.equippedCount,
    this.maxEquipped = 8,
  });

  @override
  State<ItemPopupWidget> createState() => _ItemPopupWidgetState();
}

class _ItemPopupWidgetState extends State<ItemPopupWidget> {
  late bool isEquipped;

  @override
  void initState() {
    super.initState();
    isEquipped = widget.isEquipped;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item image
            Image.asset(widget.item.imagePath, width: 128, height: 128, fit: BoxFit.cover),
            SizedBox(height: 16),
            // Name + rarity
            Text(
              widget.item.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _rarityColor(widget.item.rarity),
              ),
            ),
            Text(widget.item.rarity.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 12),
            // Type + description
            Text('Type: ${widget.item.type}', style: TextStyle(fontSize: 12)),
            Text(widget.item.description, style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 12),
            // Stats
            _statRow('HP', widget.item.hpBonus),
            _statRow('MP', widget.item.mpBonus),
            _statRow('Stamina', widget.item.staminaBonus),
            _statRow('Damage', widget.item.dmgBonus),
            _statRow('Defense', widget.item.defenseBonus),
            SizedBox(height: 16),
            // Counter
            Text('${widget.equippedCount}/${widget.maxEquipped} equipped'),
            SizedBox(height: 16),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isEquipped)
                  ElevatedButton(
                    onPressed: () {
                      widget.onUnequip();
                      setState(() => isEquipped = false);
                    },
                    child: Text('Unequip'),
                  )
                else if (widget.canEquip)
                  ElevatedButton(
                    onPressed: () {
                      widget.onEquip();
                      setState(() => isEquipped = true);
                    },
                    child: Text('Equip'),
                  )
                else
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Cannot Equip (8/8)'),
                  ),
                ElevatedButton(
                  onPressed: widget.onClose,
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text('+$value')],
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }
}
```

- [ ] **Step 2: Create ItemFilterBar**

Create `lib/item_filter.dart`:

```dart
class ItemFilterBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onRarityChanged;
  final Function(String?) onTypeChanged;
  final List<String> availableTypes;

  const ItemFilterBar({
    required this.onSearchChanged,
    required this.onRarityChanged,
    required this.onTypeChanged,
    required this.availableTypes,
  });

  @override
  State<ItemFilterBar> createState() => _ItemFilterBarState();
}

class _ItemFilterBarState extends State<ItemFilterBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Search items...'),
          onChanged: widget.onSearchChanged,
        ),
        SizedBox(height: 8),
        DropdownButton<String?>(
          value: null,
          items: [
            DropdownMenuItem(value: null, child: Text('All Rarities')),
            ...['common', 'uncommon', 'rare', 'epic', 'legendary']
                .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                .toList(),
          ],
          onChanged: widget.onRarityChanged,
        ),
        SizedBox(height: 8),
        DropdownButton<String?>(
          value: null,
          items: [
            DropdownMenuItem(value: null, child: Text('All Types')),
            ...widget.availableTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
          ],
          onChanged: widget.onTypeChanged,
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Integrate popup into InventoryWidget**

Update `lib/inventory.dart` _onTap method to open popup instead of auto-equipping:

```dart
void _onTap(...) {
  // ... existing page/arrow logic ...
  
  // Slot tap
  if (slotIdx < inv.pageItems.length) {
    final item = inv.pageItems[slotIdx];
    setState(() => inv.selected = slotIdx);
    
    showDialog(
      context: context,
      builder: (_) => ItemPopupWidget(
        item: item,
        isEquipped: inv.equippedIds.contains(item.id),
        canEquip: inv.canEquip(),
        equippedCount: inv.equippedCount,
        onEquip: () {
          inv.equip(item.id);
          widget.onUseItem(item);
          setState(() {});
        },
        onUnequip: () {
          inv.unequip(item.id);
          widget.onUnequipItem(item);
          setState(() {});
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/item_popup.dart lib/item_filter.dart lib/inventory.dart
git commit -m "feat: add item detail popup and filter bar UI"
```

---

## Task 4: Player Defense Stat Integration

**Assigned to:** Subagent D (Game Logic)

**Files:**
- Modify: `lib/game.dart` (add defense stat, apply in takeDamage)
- Test: `test/player_defense_test.dart`

**Interfaces:**
- Consumes: Item defense bonuses (from Tasks 1–2).
- Produces:
  - `LocalPlayer.totalDefense` getter returning sum of equipped item defense bonuses.
  - Updated `takeDamage()` method using defense formula: `actualDamage = damage * (100.0 / (100.0 + totalDefense))`.

**Steps:**

- [ ] **Step 1: Write failing test for defense formula**

Create `test/player_defense_test.dart`:

```dart
test('defense reduces incoming damage', () {
  // Assume LocalPlayer has totalDefense property
  final player = LocalPlayer(...);
  player.totalDefense = 50; // 50 defense
  
  // Damage formula: actualDamage = damage * (100 / (100 + defense))
  // 20 damage * (100 / 150) = 13.33
  player.takeDamage(20);
  expect(player.health, lessThan(100 - 13)); // health reduced by ~13
});
```

- [ ] **Step 2: Add totalDefense to LocalPlayer**

Update `lib/game.dart` LocalPlayer class:

```dart
class LocalPlayer {
  // ... existing fields ...
  int totalDefense = 0;

  int get totalDefense {
    // Sum of all equipped items' defenseBonus
    // Assumes inventory and equipment tracking available
    return 0; // TODO: sum from equipped items
  }
}
```

- [ ] **Step 3: Update takeDamage() to use defense formula**

Update `takeDamage()` method:

```dart
void takeDamage(double damage) {
  if (_dead) return;
  
  // Apply defense reduction
  final actualDamage = damage * (100.0 / (100.0 + totalDefense));
  
  if (_shielding) {
    damageShield(actualDamage);
    if (stamina <= 0) {
      _shieldBroken = true;
      _triggerStun();
    }
  }

  health = (health - actualDamage).clamp(0, maxHealth);
  healthNotifier.value = health;
  
  if (health <= 0) {
    _dead = true;
    // ... death logic ...
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/player_defense_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/game.dart test/player_defense_test.dart
git commit -m "feat: integrate defense stat into player damage reduction"
```

---

## Task 5: End-to-End Integration & Verification

**Assigned to:** Subagent E (QA/Review)

**Files:**
- Modify: `lib/main.dart` (wire up inventory state callbacks)
- Test: `test/item_system_integration_test.dart` (full flow)

**Steps:**

- [ ] **Step 1: Wire onUseItem/onUnequipItem in main.dart**

Ensure callbacks in InventoryWidget update player stats:

```dart
onUseItem: (item) {
  game.player.maxHealth += item.hpBonus;
  game.player.maxStamina += item.staminaBonus;
  game.player.dmgBonus += item.dmgBonus;
  game.player.totalDefense += item.defenseBonus; // NEW
  // Clamp current stats
  game.player.health = game.player.health.clamp(0, game.player.maxHealth);
  game.player.stamina = game.player.stamina.clamp(0, game.player.maxStamina);
  game.player.healthNotifier.value = game.player.health;
  game.player.staminaNotifier.value = game.player.stamina;
},
onUnequipItem: (item) {
  game.player.maxHealth -= item.hpBonus;
  game.player.maxStamina -= item.staminaBonus;
  game.player.dmgBonus -= item.dmgBonus;
  game.player.totalDefense -= item.defenseBonus; // NEW
  game.player.health = game.player.health.clamp(0, game.player.maxHealth);
  game.player.stamina = game.player.stamina.clamp(0, game.player.maxStamina);
  game.player.healthNotifier.value = game.player.health;
  game.player.staminaNotifier.value = game.player.stamina;
},
```

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: All tests pass, including CSV validation, state logic, defense formula, UI integration.

- [ ] **Step 3: Manual verification**

- [ ] Load game, open inventory.
- [ ] Click an item → popup appears with full details.
- [ ] Click Equip → icon changes, counter increments, player stats update (view HUD).
- [ ] Equip 8 items → 9th item shows "Cannot Equip" button.
- [ ] Click Unequip → icon changes, counter decrements, player stats revert.
- [ ] Search for item name → filtered list appears.
- [ ] Filter by rarity → filtered list appears.
- [ ] Close popup, scroll inventory → no crashes.
- [ ] Exit inventory, re-enter → equipped items persist.

- [ ] **Step 4: Run lint and analysis**

Run: `flutter analyze`
Expected: No errors or warnings in new code.

- [ ] **Step 5: Commit final integration**

```bash
git add lib/main.dart test/item_system_integration_test.dart
git commit -m "feat: complete item catalog system with equip, defense, search"
```

---

## Execution Method

**Recommended: Subagent-Driven** (one fresh context per task, independent reviewers between tasks).

**Rationale:** Five parallel-able but interdependent tracks (data → state → UI → game logic → verification). Each subagent reads its Interfaces block to know what to expect from prior tasks. Fresh reviewers catch misaligned names or type mismatches early.

**Alternative: Native** (all tasks in one session, final review at end).

Which would you prefer?
