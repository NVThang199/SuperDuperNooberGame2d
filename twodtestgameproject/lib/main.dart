import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'character_config.dart';
import 'character_selection.dart';
import 'overlay_layout.dart';
import 'overlay_editor.dart';
import 'game.dart';
import 'settings_page.dart';
import 'inventory.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      const MaterialApp(
        home: CharacterSelection(),
        debugShowCheckedModeBanner: false,
      ),
    );
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.character});
  final CharacterConfig character;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

Widget buildBar(
  double value,
  double max,
  Color color,
  String assetPath, {
  bool showText = false,
}) {
  final pct = value / max;
  return SizedBox(
    width: 200,
    height: 40,
    child: Stack(
      children: [
        Positioned(
          left: 9,
          top: 12,
          width: 174 * pct.clamp(0.0, 1.0),
          height: 20,
          child: Container(color: color),
        ),
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
        ),
        if (showText)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Center(
                child: Text(
                  '${value.toInt()}/${max.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _GameScreenState extends State<GameScreen> {
  late final game = NgocRongGame(character: widget.character);
  OverlayLayout _layout = OverlayLayout.defaults();
  bool _showPauseMenu = false;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final l = await loadOverlayLayout();
    if (mounted) setState(() => _layout = l);
  }

  void _move(double direction) {
    game.player.setHorizontalInput(direction);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
        ),
        child: Stack(
          children: [
            GameWidget(game: game),
            ValueListenableBuilder<bool>(
              valueListenable: game.mapSelectionVisible,
              builder: (context, visible, _) {
                if (!visible) return const SizedBox.shrink();
                return Center(
                  child: Material(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('CHỌN MAP', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(onPressed: () => game.selectMap(1), child: const Text('MAP 1')),
                              const SizedBox(width: 12),
                              ElevatedButton(onPressed: () => game.selectMap(2), child: const Text('MAP 2')),
                            ],
                          ),
                          TextButton(onPressed: () => game.mapSelector.showUI.value = false, child: const Text('ĐÓNG')),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_showPauseMenu)
              Center(
                child: Container(
                  width: 266,
                  height: 340,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/ui/pauseframe.png'),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: SizedBox(
                        width: 50,
                        height: 150,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Transform.scale(
                                scale: 3.5,
                                child: Image.asset(
                                  'assets/images/ui/menufunction button.png',
                                  filterQuality: FilterQuality.none,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() {
                                      _showPauseMenu = false;
                                      game.isPaused.value = false;
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _showPauseMenu = false;
                                        game.isPaused.value = false;
                                      });
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CharacterSelection(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _showPauseMenu = false;
                                        game.isPaused.value = false;
                                      });
                                      showDialog(
                                        context: context,
                                        builder: (_) => BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 5,
                                            sigmaY: 5,
                                          ),
                                          child: Dialog(
                                            backgroundColor: Colors.black
                                                .withValues(alpha: 0.6),
                                            child: SettingsPage(
                                              settings: game.settings,
                                              onChanged: () async {
                                                await _loadLayout();
                                                game.toggleDebug();
                                                if (context.mounted)
                                                  setState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 16,
              left: 16,
              child: FutureBuilder<void>(
                future: game.loaded,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<double>(
                    valueListenable: game.player.healthNotifier,
                    builder: (ctx2, health, _) =>
                        ValueListenableBuilder<double>(
                          valueListenable: game.player.maxHealthNotifier,
                          builder: (ctx3, maxHealth, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildBar(
                                health,
                                maxHealth,
                                Colors.red,
                                'assets/images/ui/HPbar.png',
                                showText: true,
                              ),
                              ValueListenableBuilder<double>(
                                valueListenable: game.player.staminaNotifier,
                                builder: (ctx4, stamina, _) =>
                                    Transform.translate(
                                      offset: const Offset(0, -8),
                                      child: buildBar(
                                        stamina,
                                        game.player.maxStamina,
                                        Colors.blue.shade700,
                                        'assets/images/ui/HPbar.png',
                                        showText: true,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                  );
                },
              ),
            ),
            Positioned(
              top: 12,
              left: 204,
              child: SizedBox(
                width: 96,
                height: 96,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => game.player.inventoryOpen.value = true,
                  child: _debugBorder(
                    Image.asset(
                      'assets/images/ui/inventorybagicon.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 32,
              child: SizedBox(
                width: 64,
                height: 64,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _showPauseMenu = !_showPauseMenu;
                    game.isPaused.value = _showPauseMenu;
                  }),
                  child: _debugBorder(
                    Transform.scale(
                      scale: 4.0,
                      child: Image.asset(
                        'assets/images/ui/settingbutton.png',
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FutureBuilder<void>(
                future: game.loaded,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder<void>(
                    future: game.loaded,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done ||
                          game.currentMap != 1) {
                        return const SizedBox.shrink();
                      }
                      final dist =
                          (game.player.position - game.slime.position).length;
                      final attackRange =
                          (game.slime.size.x + game.player.size.x) * 0.6;
                      if (dist > attackRange) {
                        return const SizedBox.shrink();
                      }
                      final cd = game.slime.attackCooldown;
                      final pct = (cd / 7.0).clamp(0.0, 1.0).toDouble();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Slime CD',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 120 * pct,
                                  height: 16,
                                  color: pct > 0.5 ? Colors.green : Colors.red,
                                ),
                                Center(
                                  child: Text(
                                    '${cd.toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: game.canOpenChest,
              builder: (ctx, canOpen, _) => canOpen
                  ? ValueListenableBuilder<bool>(
                      valueListenable: game.chestOpenState,
                      builder: (ctx2, isOpen, _) => Align(
                        alignment: const Alignment(0, 0.35),
                        child: _debugBorder(
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => game.openChest(),
                            child: Text(
                              isOpen ? 'Đóng rương' : 'Mở rương',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            FutureBuilder<void>(
              future: game.loaded,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done ||
                    game.isPaused.value ||
                    game.player.isDead ||
                    !game.settings.showMobileControls) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder<int>(
                  valueListenable: game.player.weaponTypeVersion,
                  builder: (ctx, version, _) => Stack(
                    children: [
                      _joystick(size, game),
                      _btn(
                        size,
                        OverlayButtonId.run,
                        _RoundControl(
                          icon: Icons.directions_run,
                          label: 'CHẠY',
                          color: Colors.green,
                          onPressed: () => game.player.isDead
                              ? null
                              : game.player.setRunning(true),
                          onReleased: () => game.player.isDead
                              ? null
                              : game.player.setRunning(false),
                        ),
                      ),
                      _btn(
                        size,
                        OverlayButtonId.attack,
                        _RoundControl(
                          icon: Icons.local_fire_department,
                          label: 'TẤN CÔNG',
                          color: Colors.red,
                          onPressed: () => game.player.isDead
                              ? null
                              : game.player.setAttackHeld(true),
                          onReleased: () => game.player.isDead
                              ? null
                              : game.player.setAttackHeld(false),
                        ),
                      ),
                      _btn(
                        size,
                        OverlayButtonId.roll,
                        _RoundControl(
                          icon: Icons.cached,
                          label: 'LĂN',
                          color: Colors.purple,
                          onPressed: () =>
                              game.player.isDead ? null : game.player.roll(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            FutureBuilder<void>(
              future: game.loaded,
              builder: (ctx, snap) =>
                  snap.connectionState != ConnectionState.done
                  ? const SizedBox.shrink()
                  : ValueListenableBuilder<bool>(
                      valueListenable: game.player.inventoryOpen,
                      builder: (ctx, open, _) => open
                          ? InventoryWidget(
                              inventory: game.inventory,
                              onUseItem: (item) {
                                final stats = game
                                    .inventory
                                    .equippedSlots
                                    .values
                                    .where((id) => id != null)
                                    .map(
                                      (id) => game.inventory.items.firstWhere(
                                        (i) => i.id == id,
                                      ),
                                    )
                                    .fold(
                                      {
                                        'hp': 0,
                                        'stamina': 0,
                                        'dmg': 0,
                                        'def': 0,
                                      },
                                      (prev, item) => {
                                        'hp': prev['hp']! + item.hpBonus,
                                        'stamina':
                                            prev['stamina']! +
                                            item.staminaBonus,
                                        'dmg': prev['dmg']! + item.dmgBonus,
                                        'def': prev['def']! + item.defenseBonus,
                                      },
                                    );
                                game.player.maxHealth += stats['hp']!;
                                game.player.maxStamina += stats['stamina']!;
                                game.player.dmgBonus = stats['dmg']!;
                                game.player.defenseBonus += stats['def']!;
                                game.player.maxHealthNotifier.value =
                                    game.player.maxHealth;
                                game.player.staminaNotifier.value =
                                    game.player.stamina;
                                game.player.refreshWeaponAnimation();
                                game.player.weaponTypeVersion.value++;
                              },
                              onUnequipItem: (item) {
                                game.inventory.unequip(item);
                                final stats = game
                                    .inventory
                                    .equippedSlots
                                    .values
                                    .where((id) => id != null)
                                    .map(
                                      (id) => game.inventory.items.firstWhere(
                                        (i) => i.id == id,
                                      ),
                                    )
                                    .fold(
                                      {
                                        'hp': 0,
                                        'stamina': 0,
                                        'dmg': 0,
                                        'def': 0,
                                      },
                                      (prev, item) => {
                                        'hp': prev['hp']! + item.hpBonus,
                                        'stamina':
                                            prev['stamina']! +
                                            item.staminaBonus,
                                        'dmg': prev['dmg']! + item.dmgBonus,
                                        'def': prev['def']! + item.defenseBonus,
                                      },
                                    );
                                game.player.maxHealth = 100.0 + stats['hp']!;
                                game.player.maxStamina =
                                    100.0 + stats['stamina']!;
                                game.player.dmgBonus = stats['dmg']!;
                                game.player.defenseBonus = stats['def']!;
                                game.player.health = game.player.health.clamp(
                                  0,
                                  game.player.maxHealth,
                                );
                                game.player.maxHealthNotifier.value =
                                    game.player.maxHealth;
                                game.player.healthNotifier.value =
                                    game.player.health;
                                game.player.stamina = game.player.stamina.clamp(
                                  0,
                                  game.player.maxStamina,
                                );
                                game.player.staminaNotifier.value =
                                    game.player.stamina;
                                game.player.refreshWeaponAnimation();
                                game.player.weaponTypeVersion.value++;
                              },
                              onGiveAll: () => setState(() {
                                game.inventory.items
                                  ..clear()
                                  ..addAll(game.itemCatalog);
                              }),
                              onClose: () =>
                                  game.player.inventoryOpen.value = false,
                              debugMode: game.settings.debugMode,
                            )
                          : const SizedBox.shrink(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _debugBorder(Widget child) => game.settings.debugMode
      ? DecoratedBox(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: Colors.red)),
          ),
          child: child,
        )
      : child;

  Widget _joystick(Size size, NgocRongGame game) {
    final cfg = _layout.buttons[OverlayButtonId.joystick]!;
    final diameter = 120 * cfg.scale;
    return Positioned(
      left: (cfg.anchor.dx * size.width - diameter / 2).clamp(
        0.0,
        size.width - diameter,
      ),
      top: (cfg.anchor.dy * size.height - diameter / 2).clamp(
        0.0,
        size.height - diameter,
      ),
      child: Opacity(
        opacity: cfg.opacity,
        child: _debugBorder(
          _VirtualJoystick(
            size: diameter,
            onChanged: (dx, dy) {
              if (game.player.isDead) return;
              _move(dx.abs() < 0.15 ? 0 : dx);
              game.player.setCrouching(dy > 0.3);
              if (dy < -0.3) game.player.jump();
            },
            onReleased: () {
              _move(0);
              game.player.setCrouching(false);
            },
          ),
        ),
      ),
    );
  }

  Widget _btn(Size size, OverlayButtonId id, Widget child) {
    final c = _layout.buttons[id]!;
    final scale = c.scale;
    final w = 72 * scale;
    return Positioned(
      left: (c.anchor.dx * size.width - w / 2).clamp(0.0, size.width - w),
      top: (c.anchor.dy * size.height - w / 2).clamp(0.0, size.height - w),
      child: Opacity(
        opacity: c.opacity,
        child: _debugBorder(Transform.scale(scale: scale, child: child)),
      ),
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({
    required this.size,
    required this.onChanged,
    required this.onReleased,
  });
  final double size;
  final void Function(double, double) onChanged;
  final VoidCallback onReleased;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset knob = Offset.zero;

  void update(Offset p) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = p - center;
    final radius = widget.size * 0.32;
    final limited = delta.distance > radius
        ? Offset.fromDirection(delta.direction, radius)
        : delta;
    setState(() => knob = limited);
    widget.onChanged(limited.dx / radius, limited.dy / radius);
  }

  void reset() {
    setState(() => knob = Offset.zero);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onPanStart: (d) => update(d.localPosition),
    onPanUpdate: (d) => update(d.localPosition),
    onPanEnd: (_) => reset(),
    onPanCancel: reset,
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: Transform.translate(
        offset: knob,
        child: Center(
          child: Container(
            width: widget.size * 0.38,
            height: widget.size * 0.38,
            decoration: const BoxDecoration(
              color: Colors.white30,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoundControl extends StatefulWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onReleased,
    this.color = Colors.blue,
    this.uiSheet,
    this.uiRect,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onReleased;
  final Color color;
  final Image? uiSheet;
  final Rect? uiRect;

  @override
  State<_RoundControl> createState() => _RoundControlState();
}

class _RoundControlState extends State<_RoundControl> {
  void _start() {
    widget.onPressed();
  }

  void _stop() {
    widget.onReleased?.call();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: Semantics(
        button: true,
        label: widget.label,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: widget.uiSheet == null
                ? widget.color.withValues(alpha: 0.8)
                : null,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
            image: widget.uiSheet != null
                ? DecorationImage(
                    image: widget.uiSheet!.image,
                    fit: BoxFit.cover,
                    centerSlice: widget.uiRect,
                  )
                : null,
          ),
          child: widget.uiSheet == null
              ? Icon(widget.icon, color: Colors.white, size: 42)
              : null,
        ),
      ),
    );
  }
}
