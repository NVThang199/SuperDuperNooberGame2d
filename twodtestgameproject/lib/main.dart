import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  runApp(const MaterialApp(home: GameScreen(), debugShowCheckedModeBanner: false));
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
      body: Stack(
        children: [
          GameWidget(game: game),
          const Positioned(
            top: 16,
            left: 16,
            child: Text('Mobile demo', style: TextStyle(color: Colors.white)),
          ),
          Positioned(
            left: 24,
            bottom: 28,
            child: _MoveControls(onMove: _move),
          ),
          Positioned(
            right: 24,
            bottom: 28,
            child: _RoundControl(
              icon: Icons.keyboard_arrow_up,
              label: 'NHẢY',
              color: Colors.orange,
              onPressed: () => game.player.jump(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveControls extends StatelessWidget {
  const _MoveControls({required this.onMove});

  final ValueChanged<double> onMove;

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

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onReleased,
    this.color = Colors.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onReleased;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPressed(),
      onPointerUp: (_) => onReleased?.call(),
      onPointerCancel: (_) => onReleased?.call(),
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 42),
        ),
      ),
    );
  }
}
