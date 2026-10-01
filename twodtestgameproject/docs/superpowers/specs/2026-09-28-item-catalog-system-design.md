# Item Catalog System Design Spec

## Goal
Generate a complete 2,192-item catalog from existing PNG assets, with rarity-based balancing, item detail popups, searchable/filterable inventory, and defense stat integration into game mechanics.

## Architecture
- **CSV Generator**: Reads 2,192 PNG files (fc1.png–fc2192.png), infers names/descriptions from visual inspection, assigns rarity and balanced stats based on tier distribution.
- **InventoryState Enhancement**: Add equipped-item tracking (max 8 equipped), search/filter logic, clear-all method.
- **Item Detail Popup**: Click item → modal displays full info (image, name, rarity, type, stats, description) + Equip/Unequip buttons.
- **Search & Filter**: Name/description search; rarity and type dropdowns.
- **Player Defense Integration**: Add `defense` stat; reduce incoming damage by a percentage based on equipped defense bonuses.

## Tech Stack
- Flutter (UI)
- CSV (data format)
- Dart (item data model, loader, state logic)

## Global Constraints
- Exact file count: 2,192 PNG files in `assets/item/64x64/` named `fc1.png` through `fc2192.png`.
- Asset size: 64×64 pixels.
- Rarity distribution: common 50%, uncommon 25%, rare 15%, epic 8%, legendary 2%.
- Stat ranges by rarity (balanced not to break game):
  - Common: hp 0–5, mp 0–2, stamina 0–3, dmg 0–2, defense 0–1.
  - Uncommon: hp 5–15, mp 2–8, stamina 3–10, dmg 2–5, defense 1–3.
  - Rare: hp 15–30, mp 8–15, stamina 10–20, dmg 5–10, defense 3–6.
  - Epic: hp 30–50, mp 15–25, stamina 20–35, dmg 10–15, defense 6–10.
  - Legendary: hp 50–75, mp 25–40, stamina 35–50, dmg 15–20, defense 10–15.
- Equip limit: max 8 items simultaneously.
- Defense mechanic: reduces incoming damage by `(defense_total / (defense_total + 100)) * damage` (soft cap design).
- CSV format: `id,name,image_path,rarity,type,hp_bonus,mp_bonus,stamina_bonus,dmg_bonus,defense_bonus,description`.

## Review Focus
1. **CSV count mismatch**: Verify row count equals 2,192.
2. **Stat overflow on equip**: Defense formula should soft-cap to avoid distortion.
3. **Rarity distribution skew**: Verify distribution on load matches target percentages.
4. **Popup state race**: Test rapid equip/unequip clicks.
5. **Search performance**: Debounce search on 2,192 items to prevent UI stutter.

## Data Format

### CSV Schema (assets/item/items.csv)
```
id,name,image_path,rarity,type,hp_bonus,mp_bonus,stamina_bonus,dmg_bonus,defense_bonus,description
1,Rusty Dagger,assets/item/64x64/fc1.png,common,weapon,0,0,0,2,0,An old weathered blade.
2,Stone Amulet,assets/item/64x64/fc2.png,common,accessory,3,0,0,0,1,Worn protection charm.
```

### Item Model (Dart)
```dart
class InventoryItem {
  final String id;
  final String name;
  final String imagePath;
  final String rarity;
  final String type;
  final int hpBonus;
  final int mpBonus;
  final int staminaBonus;
  final int dmgBonus;
  final int defenseBonus;
  final String description;
}
```

## Equip/Unequip Behavior
- **Equip**: Only changes max stats. Current health/stamina unchanged.
- **Unequip**: Reduce max stats; clamp current down if needed.
- **Limit**: Block equip if already 8 equipped.

## Popup Workflow
1. User clicks item → popup shows name, rarity, type, stats, description.
2. User clicks Equip → bonuses applied, equip button changes to Unequip.
3. User clicks Unequip → bonuses removed.

## Search & Filter
- Search bar: name/description, case-insensitive, debounced.
- Rarity dropdown: common, uncommon, rare, epic, legendary.
- Type dropdown: weapon, armor, accessory, consumable, etc.
