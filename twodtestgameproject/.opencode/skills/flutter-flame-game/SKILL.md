---
name: flutter-flame-game
description: Development for Flutter + Flame 2D games. Use when modifying game logic, characters, animations, physics, input, UI overlays, or assets in a Flame-based 2D game project. Triggers for: game loop, sprite animations, double jump, dash, combat (attack/shield/throw), mobile controls, responsive sizing, or asset management.
---

# Flutter + Flame 2D Game Development

## Project Context
- **Stack**: Flutter + Flame 2D game
- **Main files**: `lib/game.dart`, `lib/main.dart`, `lib/settings_page.dart`, `pubspec.yaml`
- **Character assets**: `characters/dude_monster`, `owlet_monster`, `pink_monster`
- **Platforms**: Mobile/Desktop controls (Landscape mode)

## Implemented Features
- Mobile/Desktop controls (Landscape)
- Double jump & Dash (Run)
- Shield, Attack combo, Throw rock
- Custom overlay layout (v2)
- Responsive sizing for all game objects

## Coding Standards

### Architecture & Patterns
- Scale all objects relative to viewport/player size
- Use `lerp()` for smooth movement transitions
- Gated logs only: `if (kDebugMode) print('message')`
- Run `flutter analyze` before claiming success
- Build test: `flutter build web --release`

### Movement & Input (Critical)
- **Priority**: Right > Left (preserve current behavior)
- Track press order via `Set<LogicalKeyboardKey>` (`last` = most recent)
- Mobile controls via `setHorizontalInput()` work independently from keyboard
- Update animation state: `_lastInput.abs() > 0.01 || _keysPressed.isNotEmpty`

### Animation & Sprites
- Walk: `_lastInput.abs() > 0.01 || _keysPressed.isNotEmpty`
- Idle: `_lastInput.abs() <= 0.01 && _keysPressed.isEmpty`
- Avoid `every-frame update()` calls that reset mobile state

### Assets
- `pubspec.yaml` must reference only **existing** directories
- Wildcards like `- assets/images/` bundle all files; remove when deleting folders
- Run `flutter clean && flutter pub get` after asset changes

## Common Fixes Pattern

### Movement Priority Fixes
1. Track key press order in `Set<LogicalKeyboardKey>` 
2. Update direction based on newest key in set
3. Preserve Right > Left priority for same-time presses

### Animation Fixes
1. Check `_lastInput.abs() > 0.01` OR `_keysPressed.isNotEmpty` (mobile + keyboard)
2. Remove every-frame updates that reset mobile input state

### Asset Path Fixes
1. Remove deleted files/folders from `pubspec.yaml`
2. Delete wildcard declarations matching deleted content
3. Run `flutter clean && flutter pub get`

## Verification Checklist
- [ ] `flutter analyze` returns 0 errors
- [ ] `flutter build web --release` passes
- [ ] No hardcoded paths referencing deleted assets
- [ ] Mobile controls tested on at least one target

## Quick Reference
```dart
// Movement direction (Right > Left priority)
final _keysPressed = <LogicalKeyboardKey>{};
// Newest key: _keysPressed.last

// Smooth movement
final speed = lerpDouble(currentSpeed, targetSpeed, deltaTime);

// Debug logging
if (kDebugMode) print('move: $_lastInput');
```

## What This Skill Does NOT Do
- Does not write entire game engines from scratch
- Does not design visual assets (use `frontend-design` for UI layout)
- Does not handle backend server logic
- Does not manage external dependencies beyond `pubspec.yaml`
