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
- `lib/main.dart` — Entry point, CharacterSelection → GameScreen, mobile UI (joystick + buttons)
- `lib/game.dart` — NgocRongGame (Flame), LocalPlayer, SlimeEnemy, combat, physics (~1700 lines)
- `lib/boss.dart` — BossEnemy AI, skills, minions, 2-hit attack combo (~520 lines)
- `lib/inventory.dart` — InventoryItem, EquipmentSlot, stats, UI (~570 lines)
- `lib/character_config.dart` — FreeKnight character with 50+ animations (roll, crouch, fall, etc.)
- `lib/overlay_layout.dart` — Mobile/desktop button layout, customizable via overlay editor
- `lib/overlay_editor.dart` — Drag-drop UI editor for joystick + buttons (position/scale/opacity)
- `lib/settings_page.dart` — Key bindings, mobile controls toggle
- `lib/shield_badge.dart`, `lib/stamina_config.dart` — UI components, stamina costs

**Character system:**
- **Current**: FreeKnight only (1.5× base size scaled to 2× final = player size 0.6 × screen height)
- **Animations**: idle, walk, run, jump, fall, attack1/2/combo, crouch, crouchWalk, crouchAttack, crouchTransition, roll, shield/push, hurt, death
- **Stats**: HP=100, Stamina=100, damage/defense from inventory
- **Stamina costs**: attack=20, roll=30, jump=20, run=0.8/frame

**Combat system:**
- **Sword**: 20 base damage, 2-hit combo (attack1 → attack2), +5 damage when crouching
- **Bow**: 18 base damage, arrow projectiles
- **Roll**: Dark Souls style with iframe (frame 3-8), locks momentum during roll, 2s cooldown regen penalty
- **Shield**: blocks damage, consumes stamina; breaks when stamina=0 → stun
- **Crouch attack**: +5 damage bonus

**Physics:**
- **Jump**: `impulse = -2.07 × size.y`, `gravity = 5.11 × size.y`, costs 20 stamina
- **Movement**: `speed = 10/12 × size.y`, lerp factor=6 (smooth air control)
- **Ground**: `y = screen.height - 0.1×height - size.y/2`

**Enemy system:**
- **Slime** (map 1): 30 damage, size=0.27×screen.height, respawns after 5s
- **Undead Boss** (map 2): 200 HP, size×1.5 (sizeMultiplier=3.6), 2-hit attack combo (frame 3 & 10), skill1, summon minions, aggro range=240

**Mobile Controls:**
- **Joystick**: Custom `_VirtualJoystick` widget (left/right = move, up = jump, down = crouch)
- **Buttons**: run, attack, roll (configurable in overlay editor)
- **Overlay editor**: Drag to reposition, sliders for scale/opacity per button
- **Settings removed**: Global buttonOpacity/buttonSize sliders (redundant with per-button customization)

**Map system:**
- Map 0: Starting area (chest, fire)
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

## Animation Safety

- Chỉ gán `current` bằng key tồn tại trong `animations`.
- Animation tùy chọn phải có fallback hợp lệ như `idle`, `walk`, hoặc `jump`.
- Kiểm tra asset thật trong `assets/images/` trước khi thêm key animation; không giả định file tồn tại.
- Input mobile phải gọi public method của `LocalPlayer`, không truy cập state private.
- Chạy `flutter analyze` sau mọi thay đổi animation hoặc control.

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
