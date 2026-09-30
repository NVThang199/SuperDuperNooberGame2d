# Super Duper Noober Game 2D

Flutter + Flame 2D action game với combat, inventory system, boss fights.

## Quick Start
```bash
flutter pub get
flutter run              # dev
flutter analyze          # lint
flutter build web        # production web
flutter build windows    # production desktop
```

## Architecture

**Core files:**
- `lib/main.dart` — Entry point, CharacterSelection → GameScreen
- `lib/game.dart` — NgocRongGame (Flame), LocalPlayer, SlimeEnemy, combat, controls (1470 lines)
- `lib/boss.dart` — BossEnemy AI, skills, health (522 lines)
- `lib/inventory.dart` — InventoryItem, EquipmentSlot, stats, UI (571 lines)
- `lib/character_config.dart` — 3 characters (dude/owlet/pink), weapon types (sword/bow/none)
- `lib/overlay_layout.dart` — Mobile/desktop button layout system
- `lib/settings_page.dart` — Key bindings, mobile controls toggle
- `lib/shield_badge.dart`, `lib/stamina_config.dart` — UI components

**Character system:**
- 3 base characters: Dude Monster, Owlet Monster, Pink Monster
- 3 weapon variants each: sword, bow, none
- Stats: HP, MP, Stamina, Damage, Defense (from inventory)
- Animations: idle, walk, jump, double_jump, attack (3-hit combo), shield, squat, hurt, death

**Combat system:**
- Sword: 20 base damage, 3-hit combo
- Bow: 18 base damage, arrow projectiles
- Shield: blocks damage while held, can break
- Dash/Run: stamina cost
- Double jump with dust VFX

**Enemy system:**
- Slime (map 1): 30 damage, basic AI
- Undead Boss (map 2): 200 HP, 2 skills, aggro range 80, minion summon

**Inventory system:**
- 7 equipment slots: ring1/2, helm, weapon1/2, armor, belt
- Stats bonus: HP, MP, Stamina, Damage, Defense
- Item loader from `assets/item/`

**Map system:**
- Map 0: Character selection
- Map 1: Forest (slime enemy)
- Map 2: Boss arena (undead boss)
- Backgrounds: `assets/images/background/forest*.png`

## Controls (default)

**Keyboard:**
- Arrow Left/Right: move
- Space: jump (press twice for double jump)
- Shift: dash/run
- Z: attack
- X: shield
- Down: squat
- R: open chest
- I: inventory

**Mobile:** Touch buttons (configurable via overlay_layout.dart)

**Mouse:** Click to move (toggleable in settings)

## Assets Structure
```
assets/
├── images/
│   ├── characters/
│   │   ├── dude_monster/        # Base sprites
│   │   ├── dude_monster_sword/
│   │   ├── dude_monster_bow/
│   │   ├── owlet_monster/
│   │   ├── owlet_monster_sword/
│   │   ├── owlet_monster_bow/
│   │   ├── pink_monster/
│   │   ├── pink_monster_sword/
│   │   └── pink_monster_bow/
│   ├── enemies/
│   │   ├── slime3/
│   │   └── undead_boss/
│   ├── action/                  # Shield, alert icons
│   ├── background/              # forest.png, mountains.png, forest_map1/2.png
│   └── ui/inventory/
└── item/                        # 64x64 item icons
```

## Dependencies
```yaml
flame: ^1.38.2                   # Game engine
web_socket_channel: ^3.0.3       # Multiplayer (unused?)
shared_preferences: ^2.5.5       # Settings persistence
```

## Coding Standards
- Scale all objects relative to viewport/player size
- Use `lerp()` for smooth movements/transitions
- Gated logs: `if (kDebugMode) print()`
- Landscape orientation only
- Run `flutter analyze` before commit
- Run `flutter build` to verify before claiming success

## Known Issues & Fixed

**Fixed (2026-09-26):**
- ✓ Movement priority: Hold R + Press L + Release R → now moves L correctly
- ✓ Walk animation: works on both mobile + keyboard
- ✓ Missing tileset.png: removed orphan asset references
- ✓ Reverse movement: Hold L + Press R + Release L → now moves R correctly

**TODOs (scan code for `// TODO`):**
```bash
rg "TODO|FIXME|XXX|HACK" lib/
```

## Skills & Agent Rules

**Local skill:** `.opencode/skills/flutter-flame-game/SKILL.md` (auto-loaded)

**When to use:**
- Editing game loop, sprite, input, collision, animation → load `flutter-flame-game` skill
- Editing UI, inventory, settings → standard Flutter patterns
- Adding new character/enemy → follow existing pattern in `character_config.dart`, `game.dart`

**GitHub skills:** Only from allowlist in `.opencode/opencode.json` → `skills.urls`

## Session Workflow

1. **Understand task** → check relevant files first
2. **Make changes** → follow coding standards
3. **Verify:**
   ```bash
   flutter analyze              # Must show 0 issues
   flutter build web --release  # Must PASS
   ```
4. **Update this file** → add entry to Work Log below

---

## Work Log

### [2026-09-26] - Fix Movement Priority & Animation Transition
- **Issue**: Holding Right + Press Left + Release Right caused character to stop while Left still held.
- **Fix v1 (broken)**: Added `Set<LogicalKeyboardKey> _keysPressed` for real-time tracking, implemented `_updateMovementDirection()` every frame. Problem: reset `_lastInput` to 0 every frame, broke mobile controls.
- **Fix v2 (correct)**: Removed every-frame update, sync `_keysPressed` from `keysPressed` parameter in `onKeyEvent()`. Mobile via `setHorizontalInput()` works independently.
- **Verification**: `flutter analyze` 0 errors, `flutter build web --release` PASS.

### [2026-09-26] - Fix Walk Animation + Pubspec Assets
- **Issue**: Walk animation lost after v2 fix; `pubspec.yaml` referenced deleted dirs.
- **Fix**: `_updateAnimationState()` checks `_lastInput.abs() > 0.01 || _keysPressed`. Removed `player/`, `environment/`, `ui/` from pubspec.
- **Verification**: `flutter pub get` PASS.

### [2026-09-26] - Fix Missing tileset.png Asset Error
- **Issue**: `PathNotFoundException: assets/images/tileset.png` after deleting unused assets.
- **Cause**: `pubspec.yaml` wildcard `- assets/images/` tried to bundle deleted files.
- **Fix**: Removed wildcard, keep explicit dirs. Ran `flutter clean` + `flutter pub get`.
- **Verification**: No code references to `tileset`, `player/`, `environment/`, `ui/`.

### [2026-09-26] - Fix Reverse Movement Priority
- **Issue**: Hold Left + Press Right + Release Left → character stood still instead of moving Right.
- **Fix**: Track press order in `Set`, move toward newest key. Empty set → stop.
- **Test matrix**: All 3 cases pass ✓
