# Project Game Rules
(Copied from ProjectGameRule.txt)

## Game Info
- Flutter + Flame 2D game.
- Main files: lib/game.dart, lib/main.dart, lib/settings_page.dart, pubspec.yaml.
- Assets: `assets/images/characters/{dude,owlet,pink}_monster/`, `enemies/slime3/`, `player/`, `environment/` (Chest.png, Fire.png), `ui/`, `background/`. Orphan at root `assets/*.png` (player_idle, player_walk, tileset) not bundled — remove or move to `assets/images/` if needed. See `pubspec.yaml` assets list.

## Implemented Features
- Mobile/Desktop controls (Landscape).
- Double jump & Dash (Run).
- Shield, Attack combo, Throw rock.
- Custom overlay layout (v2).
- Responsive sizing for all game objects.

## Coding Standards
- Scale all objects relative to viewport/player size.
- Use `lerp` for smooth movements.
- Gated logs: `if (kDebugMode) print()`.
- Run `flutter analyze` & `flutter build` before claiming success.

## Skills — Auto-load Rules (for partners/agents)
- Local skills: `.opencode/skills/<name>/SKILL.md` auto-loaded (no config needed). Current: `flutter-flame-game`.
- GitHub/external skills: only from allowlist in `opencode.json` → `skills.urls`. Do not auto-fetch arbitrary GitHub repos.
- To add new GitHub skill: 1) verify source/license/content, 2) add URL to allowlist, 3) restart opencode.
- Agent must apply matching skill when keywords hit (game loop, sprite, input, etc.) — see `flutter-flame-game` SKILL.md.

---

# Work Log

## [2026-09-26] - Fix Movement Priority & Animation Transition
- **Issue**: Holding Right + Press Left + Release Right caused character to stop while Left still held.
- **Fix v1 (broken)**: 
    - Added `Set<LogicalKeyboardKey> _keysPressed` for real-time tracking.
    - Implemented `_updateMovementDirection()` called every frame.
    - Problem: Every frame without keyboard input reset `_lastInput` to 0, breaking mobile controls.
- **Fix v2 (correct)**:
    - Removed every-frame `_updateMovementDirection()` from `update()`.
    - Sync `_keysPressed` from `keysPressed` parameter in `onKeyEvent()` (platform provides live state).
    - Mobile controls via `setHorizontalInput()` work independently, keyboard only updates on key events.
    - Right movement priority logic preserved.
- **Verification**: `flutter analyze` 0 errors, `flutter build web --release` PASS.

## [2026-09-26] - Fix Walk Animation + Pubspec Assets
- **Issue**: Walk animation lost after v2 fix; `pubspec.yaml` referenced deleted dirs `player/`, `environment/`, `ui/`.
- **Fix**:
    - `_updateAnimationState()` now checks `_lastInput.abs() > 0.01 || _keysPressed` (mobile + keyboard).
    - `pubspec.yaml`: removed `assets/images/player/`, `environment/`, `ui/` entries.
- **Verification**: `flutter pub get` PASS.

## [2026-09-26] - Fix Missing tileset.png Asset Error
- **Issue**: `PathNotFoundException: assets/images/tileset.png` after deleting unused assets.
- **Cause**: `pubspec.yaml` had wildcard `- assets/images/` which tries to bundle every file under that dir; deleted files still matched the declaration.
- **Fix**: Removed `- assets/images/` wildcard; keep only explicit dirs that exist: `characters/*/`, `background/`. Ran `flutter clean` + `flutter pub get`.
- **Scan**: `lib/` has no reference to `tileset`, `player/`, `environment/`, `ui/` — no code cleanup needed.
- **Verification**: `flutter pub get` PASS, `flutter clean` PASS.

## [2026-09-26] - Fix Reverse Movement Priority
- **Issue**: Fixed Right-first case but missed reverse: Hold Left + Press Right + Release Left → character stood still instead of moving Right.
- **Cause**: `_updateMovementDirection()` hardcoded Right > Left priority, ignored press order.
- **Fix**: Track press order in `Set<LogicalKeyboardKey>` (`_keysPressed.last` = most recent); move toward newest key. Empty set → stop.
- **Test matrix**: 1) Hold R + Press L + Release R → moves L ✓ 2) Hold L + Press R + Release L → moves R ✓ 3) Single keys work ✓.
