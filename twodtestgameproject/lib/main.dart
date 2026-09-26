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

class _GameScreenState extends State<GameScreen> {
  late final game = NgocRongGame(character: widget.character);
  OverlayLayout _layout = OverlayLayout.defaults();

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
            Positioned(
              top: 16,
              left: 150,
              child: FutureBuilder<void>(
                future: game.loaded,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<double>(
                    valueListenable: game.player.healthNotifier,
                    builder: (ctx2, health, _) {
                      final healthPct = health / game.player.maxHealth;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HP',
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
                                  width: 120 * healthPct,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: healthPct > 0.5
                                        ? Colors.green
                                        : (healthPct > 0.25
                                              ? Colors.orange
                                              : Colors.red),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '${health.toInt()}/${game.player.maxHealth.toInt()}',
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
                        child: ElevatedButton(
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
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Dialog(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: SettingsPage(
                            settings: game.settings,
                            onChanged: () async {
                              await _loadLayout();
                              if (context.mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Setting', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            if (game.settings.showMobileControls) ...[
              _btn(
                size,
                OverlayButtonId.moveLeft,
                _RoundControl(
                  icon: Icons.keyboard_arrow_left,
                  label: 'TRÁI',
                  onPressed: () => _move(-1),
                  onReleased: () => _move(0),
                ),
              ),
              _btn(
                size,
                OverlayButtonId.moveRight,
                _RoundControl(
                  icon: Icons.keyboard_arrow_right,
                  label: 'PHẢI',
                  onPressed: () => _move(1),
                  onReleased: () => _move(0),
                ),
              ),
              _btn(
                size,
                OverlayButtonId.shield,
                _RoundControl(
                  icon: Icons.shield,
                  label: 'KHIÊN',
                  color: Colors.grey,
                  onPressed: () => game.player.setShielding(true),
                  onReleased: () => game.player.setShielding(false),
                ),
              ),
              _btn(
                size,
                OverlayButtonId.run,
                _RoundControl(
                  icon: Icons.directions_run,
                  label: 'CHẠY',
                  color: Colors.green,
                  onPressed: () => game.player.setRunning(true),
                  onReleased: () => game.player.setRunning(false),
                ),
              ),
              _btn(
                size,
                OverlayButtonId.throwRock,
                _RoundControl(
                  icon: Icons.landscape,
                  label: 'NÉM ĐÁ',
                  color: Colors.brown,
                  onPressed: () => game.player.throwRock(),
                ),
              ),
              _btn(
                size,
                OverlayButtonId.attack,
                _RoundControl(
                  icon: Icons.local_fire_department,
                  label: 'TẤN CÔNG',
                  color: Colors.red,
                  onPressed: () => game.player.setAttackHeld(true),
                  onReleased: () => game.player.setAttackHeld(false),
                ),
              ),
              _btn(
                size,
                OverlayButtonId.jump,
                _RoundControl(
                  icon: Icons.keyboard_arrow_up,
                  label: 'NHẢY',
                  color: Colors.orange,
                  onPressed: () => game.player.jump(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _btn(Size size, OverlayButtonId id, Widget child) {
    final c = _layout.buttons[id]!;
    final w = 72 * c.scale;
    return Positioned(
      left: (c.anchor.dx * size.width - w / 2).clamp(0.0, size.width - w),
      top: (c.anchor.dy * size.height - w / 2).clamp(0.0, size.height - w),
      child: Opacity(
        opacity: c.opacity,
        child: Transform.scale(scale: c.scale, child: child),
      ),
    );
  }
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
  Timer? _repeat;

  void _start() {
    widget.onPressed();
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
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
