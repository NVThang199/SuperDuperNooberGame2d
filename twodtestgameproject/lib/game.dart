// Phase 3 & 4: Flame Game Loop & Local Player Component
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocalPlayer extends PositionComponent with HasGameReference<NgocRongGame> {
  static const double speed = 200.0;
  static const double jumpImpulse = -350.0;

  double vx = 0;
  double vy = 0;
  int direction = 1;
  bool isOnGround = true;

  LocalPlayer({required Vector2 position})
      : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  void setHorizontalInput(double input) {
    vx = input * speed;
    if (input < -0.1) direction = -1;
    if (input > 0.1) direction = 1;
  }

  void jump() {
    if (isOnGround) {
      vy = jumpImpulse;
      isOnGround = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.orangeAccent;
    canvas.drawRect(size.toRect(), paint);
    final eyePaint = Paint()..color = Colors.black;
    final eyeOffset = direction == 1 ? const Offset(14, 8) : const Offset(6, 8);
    canvas.drawRect(Rect.fromLTWH(eyeOffset.dx, eyeOffset.dy, 8, 8), eyePaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    vy += 900 * dt;
    position.x += vx * dt;
    position.y += vy * dt;

    final groundY = game.size.y - 40 - size.y / 2;
    if (position.y >= groundY) {
      position.y = groundY;
      vy = 0;
      isOnGround = true;
    }

    final minX = size.x / 2;
    final maxX = game.size.x - size.x / 2;
    if (position.x < minX) position.x = minX;
    if (position.x > maxX) position.x = maxX;
  }
}

// remove onMoved field and keyboard handler


class RemotePlayer extends PositionComponent {
  RemotePlayer({required Vector2 position})
      : super(position: position, size: Vector2(32, 48), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blueGrey;
    canvas.drawRect(size.toRect(), paint);
  }

  void updatePosition(double targetX, double targetY, double dt) {
    // Basic lerp interpolation
    position.x += (targetX - position.x) * 10 * dt;
    position.y += (targetY - position.y) * 10 * dt;
  }
}

class NgocRongGame extends FlameGame {
  late LocalPlayer player;
  late RectangleComponent ground;

  @override
  Future<void> onLoad() async {
    // Mock Ground
    ground = RectangleComponent(paint: Paint()..color = Colors.green.shade800);
    add(ground);

    // Add local player
    player = LocalPlayer(position: Vector2(size.x / 2, size.y - 40 - 24));
    add(player);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      ground.size = Vector2(size.x, 40);
      ground.position = Vector2(0, size.y - 40);
    }
  }
}
