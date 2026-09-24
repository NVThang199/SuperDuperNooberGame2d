import 'dart:async';

import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game.dart';
import 'settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MaterialApp(home: GameScreen(), debugShowCheckedModeBanner: false));
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final game = NgocRongGame();

  void _move(double direction) {
    game.player.setHorizontalInput(direction);
  }

  @override
  Widget build(BuildContext context) {
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
              left: 16,
              child: Row(
                children: [
                  const Text('Mobile demo', style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Dialog(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: SettingsPage(settings: game.settings, onChanged: () => setState(() {})),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (game.settings.showMobileControls)
              Positioned(
                left: 24,
                bottom: 28,
                child: _MoveControls(onMove: _move),
              ),
            if (game.settings.showMobileControls)
              Positioned(
                right: 24,
                bottom: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Row(
                      children: [
                        _RoundControl(
                          icon: Icons.shield,
                          label: 'KHIÊN',
                          color: Colors.grey,
                          onPressed: () => game.player.setShielding(true),
                          onReleased: () => game.player.setShielding(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _RoundControl(
                          icon: Icons.local_fire_department,
                          label: 'TẤN CÔNG',
                          color: Colors.red,
                          onPressed: () => game.player.setAttackHeld(true),
                          onReleased: () => game.player.setAttackHeld(false),
                        ),
                        const SizedBox(width: 12),
                        _RoundControl(
                          icon: Icons.keyboard_arrow_up,
                          label: 'NHẢY',
                          color: Colors.orange,
                          onPressed: () => game.player.jump(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoveControls extends StatelessWidget {
  const _MoveControls({required this.onMove, this.uiSheet});

  final ValueChanged<double> onMove;
  final Image? uiSheet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundControl(
          icon: Icons.keyboard_arrow_left,
          label: 'TRÁI',
          onPressed: () => onMove(-1),
          onReleased: () => onMove(0),
        ),
        const SizedBox(width: 12),
        _RoundControl(
          icon: Icons.keyboard_arrow_right,
          label: 'PHẢI',
          onPressed: () => onMove(1),
          onReleased: () => onMove(0),
        ),
      ],
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
            color: widget.uiSheet == null ? widget.color.withValues(alpha: 0.8) : null,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
            image: widget.uiSheet != null ? DecorationImage(image: widget.uiSheet!.image, fit: BoxFit.cover, centerSlice: widget.uiRect) : null,
          ),
          child: widget.uiSheet == null ? Icon(widget.icon, color: Colors.white, size: 42) : null,
        ),
      ),
    );
  }
}
