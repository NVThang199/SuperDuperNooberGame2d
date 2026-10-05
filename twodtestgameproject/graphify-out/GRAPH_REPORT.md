# Graph Report - twodtestgameproject  (2026-10-05)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 879 nodes · 1043 edges · 36 communities (23 shown, 13 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.85)
- Token cost: 22,799 input · 506 output

## Graph Freshness
- Built from commit: `5f415cb6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Core Game Engine
- Inventory UI Assets
- Character Animation Config
- Boss Enemy AI
- Camera Management
- Character Selection UI
- Overlay Editor
- Item CSV Generator
- Linux Flutter Runner
- Windows Runner Entry
- Flutter Window Wrapper
- Game Settings UI
- Win32 Window Management
- Project Tooling Permissions
- Coordinate Measurement Tool
- Shield Combat HUD
- Stamina Configuration
- Game Control Widgets
- Collision Game Entities
- Web App Manifest
- Window Lifecycle Management
- Win32 Message Handling
- Character Selection Navigation
- Game Tests
- Item Loading
- Plugin Registry
- Point Geometry
- Size Geometry
- Android Activity Entry
- Player Keyboard Input
- Inventory Widget

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 21 edges
2. `FlutterWindow` - 10 edges
3. `permission` - 8 edges
4. `WindowClassRegistrar` - 7 edges
5. `_MyApplication` - 7 edges
6. `LocalPlayer` - 6 edges
7. `Point` - 5 edges
8. `Size` - 5 edges
9. `wWinMain()` - 5 edges
10. `GetCommandLineArguments()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `wWinMain()` --calls--> `GetCommandLineArguments()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp

## Import Cycles
- None detected.

## Communities (36 total, 13 thin omitted)

### Community 0 - "Core Game Engine"
Cohesion: 0.01
Nodes (193): _applyHorizontalInput, _applySpeed, _arrowSpawnDelay, _arrowSpawned, _arrowSprite, attack, _attackAnimForCombo, _attackCooldown (+185 more)

### Community 1 - "Inventory UI Assets"
Cohesion: 0.02
Nodes (96): attack1Path, attack1TextureWidth, attack2Path, attack2TextureWidth, btnCloseX, btnCloseY, btnNextX, btnNextY (+88 more)

### Community 2 - "Character Animation Config"
Cohesion: 0.02
Nodes (85): attack1Amount, attack1File, attack1Path, attack1StepTime, attack2Amount, attack2File, attack2Path, attack2StepTime (+77 more)

### Community 3 - "Boss Enemy AI"
Cohesion: 0.04
Nodes (47): activationRange, _aggro, _appeared, _appearTimer, attackCooldown, _attackCount, chaseSpeed, _currentState (+39 more)

### Community 4 - "Camera Management"
Cohesion: 0.05
Nodes (33): applyToFlameCamera, CameraManager, cameraWorldPos, _clampX, deadZoneLeft, deadZoneRight, game, getCameraDelta (+25 more)

### Community 5 - "Character Selection UI"
Cohesion: 0.05
Nodes (31): CharacterConfig, _btn, build, buildBar, character, color, createState, _debugBorder (+23 more)

### Community 6 - "Overlay Editor"
Cohesion: 0.05
Nodes (32): build, _buildButton, _buildControls, createState, _icBtn, _iconOf, initState, _layout (+24 more)

### Community 7 - "Item CSV Generator"
Cohesion: 0.06
Nodes (26): cumulativeWeights, main, output, pickRarity, random, rarities, rarityWeights, statRanges (+18 more)

### Community 8 - "Linux Flutter Runner"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 9 - "Windows Runner Entry"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 10 - "Flutter Window Wrapper"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 11 - "Game Settings UI"
Cohesion: 0.11
Nodes (14): GameSettings, build, createState, current, dispose, _focus, initState, _name (+6 more)

### Community 12 - "Win32 Window Management"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 13 - "Project Tooling Permissions"
Cohesion: 0.13
Nodes (14): C:/PRMt/git/SuperDuperNooberGame2d/twodtestgameproject/**, C:/Users/nguye/Downloads/**, instructions, permission, bash, edit, external_directory, glob (+6 more)

### Community 14 - "Coordinate Measurement Tool"
Cohesion: 0.15
Nodes (9): build, bytes, _clickPos, createState, data, image, imageBytes, main (+1 more)

### Community 15 - "Shield Combat HUD"
Cohesion: 0.15
Nodes (8): ArrowProjectile, SpriteComponent, _brokenShield, _fullShield, onLoad, player, _shieldIcon, update

### Community 16 - "Stamina Configuration"
Cohesion: 0.15
Nodes (11): activeRegenRate, attackCost, idleRegenRate, jumpCost, maxStamina, regenDelay, rollCost, runCostPerFrame (+3 more)

### Community 17 - "Game Control Widgets"
Cohesion: 0.23
Nodes (10): CoordinateFinder, _CoordinateFinderState, GameScreen, _GameScreenState, _RoundControl, _RoundControlState, _VirtualJoystick, _VirtualJoystickState (+2 more)

### Community 18 - "Collision Game Entities"
Cohesion: 0.21
Nodes (9): BossEnemy, BossMinion, DebugOverlay, DoubleJumpDust, MapSelector, SlimeEnemy, SpriteAnimationComponent, PositionComponent (+1 more)

### Community 19 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 20 - "Window Lifecycle Management"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 26 - "Point Geometry"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 27 - "Size Geometry"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **608 isolated node(s):** `_applyHorizontalInput`, `_applySpeed`, `_arrowSpawnDelay`, `_arrowSpawned`, `_arrowSprite` (+603 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 705 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CharacterConfig` connect `Character Selection UI` to `Core Game Engine`, `Character Animation Config`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `_applyHorizontalInput`, `_applySpeed`, `_arrowSpawnDelay` to the rest of the system?**
  _608 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Core Game Engine` be split into smaller, more focused modules?**
  _Cohesion score 0.009216589861751152 - nodes in this community are weakly interconnected._
- **Why does `InventoryState` connect `Inventory UI Assets` to `Core Game Engine`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `Inventory UI Assets` be split into smaller, more focused modules?**
  _Cohesion score 0.019417475728155338 - nodes in this community are weakly interconnected._
- **Why does `LocalPlayer` connect `Player Keyboard Input` to `Core Game Engine`, `Collision Game Entities`, `Boss Enemy AI`, `Shield Combat HUD`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `Character Animation Config` be split into smaller, more focused modules?**
  _Cohesion score 0.022988505747126436 - nodes in this community are weakly interconnected._