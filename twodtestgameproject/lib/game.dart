import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameSettings {
  LogicalKeyboardKey leftKey = LogicalKeyboardKey.arrowLeft;
  LogicalKeyboardKey rightKey = LogicalKeyboardKey.arrowRight;
  LogicalKeyboardKey jumpKey = LogicalKeyboardKey.space;
  LogicalKeyboardKey attackKey = LogicalKeyboardKey.keyZ;
  LogicalKeyboardKey shieldKey = LogicalKeyboardKey.keyX;
  LogicalKeyboardKey parryKey = LogicalKeyboardKey.keyC;
  bool showMobileControls = true;
}

class LocalPlayer extends SpriteAnimationGroupComponent<String> with HasGameReference<NgocRongGame>, KeyboardHandler {
  static const double speed = 200.0;
  static const double jumpImpulse = -350.0;

  double vx = 0;
  double vy = 0;
  int direction = 1;
  bool isOnGround = true;
  bool _attacking = false;
  DateTime? _lastAttack;
  bool _shielding = false;
  bool _attackHeld = false;
  double _lastInput = 0;
  final GameSettings settings;
  
  int _comboStep = 0;
  double _comboWindow = 0;

  bool get canAttack => true; // Removed cooldown for hold-to-combo

  LocalPlayer({required Vector2 position, GameSettings? settings})
      : settings = settings ?? GameSettings(),
        super(position: position, size: Vector2(96, 96), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final idleSheet = await game.images.load('player/Idle.png');
    final walkSheet = await game.images.load('player/Walk.png');
    final attack1Sheet = await game.images.load('player/Attack_1.png');
    final attack2Sheet = await game.images.load('player/Attack_2.png');
    final shieldSheet = await game.images.load('player/Shield.png');
    final shieldAttackSheet = await game.images.load('player/Shield+Attack.png');

    animations = {
      'idle': SpriteAnimation.fromFrameData(idleSheet, SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2(32, 32))),
      'walk': SpriteAnimation.fromFrameData(walkSheet, SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(32, 32))),
      'attack1': SpriteAnimation.fromFrameData(attack1Sheet, SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(32, 32))),
      'attack2': SpriteAnimation.fromFrameData(attack2Sheet, SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(32, 32))),
      'shield': SpriteAnimation.fromFrameData(shieldSheet, SpriteAnimationData.sequenced(amount: 1, stepTime: 1, textureSize: Vector2(32, 32))),
      'shieldAttack': SpriteAnimation.fromFrameData(shieldAttackSheet, SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(32, 32), loop: true)),
    };
    current = 'idle';
  }

  void attack() {
    if (_shielding) return;
    
    // Allow attack advancement or start
    if (_attacking) {
      if (_comboStep == 1 && _comboWindow > 0) {
        _comboStep = 2;
        _comboWindow = 0.4;
        current = 'attack2';
      }
      return;
    }
    
    if (_lastAttack != null && DateTime.now().difference(_lastAttack!) < const Duration(milliseconds: 200)) return;
    
    _lastAttack = DateTime.now();
    _attacking = true;
    _comboStep = 1;
    _comboWindow = 0.4;
    _applySpeed(); // Giảm tốc độ ngay khi bắt đầu đòn đánh
    current = 'attack1';
  }

  void parry() {
    if (_attacking) return;
    _attacking = true;
    _comboStep = 0; // Reset combo to prevent logic interference
    _comboWindow = 0.4; // Use window for animation duration
    vx = 0;
    current = 'shieldAttack';
  }

  void setAttackHeld(bool active) {
    _attackHeld = active;
    if (active) attack();
  }

  void setShielding(bool active) {
    _shielding = active;
    _applySpeed(); // Cập nhật tốc độ ngay khi đổi state
    if (!_attacking) {
      _updateAnimationState();
    }
  }

  void toggleShield() => setShielding(!_shielding);

  void _updateAnimationState() {
    if (_attacking) return; // Keep current attack animation
    if (_shielding) {
      current = 'shield';
    } else if (vx != 0) {
      current = 'walk';
    } else {
      current = 'idle';
    }
  }

  void setHorizontalInput(double input) {
    _lastInput = input;
    _applySpeed();
  }

  void _applySpeed() {
    double multiplier = _attacking ? 0.2 : (_shielding ? 0.3 : 1.0);
    vx = _lastInput * speed * multiplier;
    if (_lastInput < -0.1) { direction = -1; flipAround(); }
    else if (_lastInput > 0.1) { direction = 1; flipAround(); }
    if (!_attacking && !_shielding) {
      current = (_lastInput == 0) ? 'idle' : 'walk';
    }
  }

  void jump() {
    if (isOnGround) {
      vy = jumpImpulse;
      isOnGround = false;
    }
  }

  void flipAround() {
    if (direction == -1 && scale.x > 0) scale.x *= -1;
    else if (direction == 1 && scale.x < 0) scale.x *= -1;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == settings.leftKey) setHorizontalInput(-1);
      else if (event.logicalKey == settings.rightKey) setHorizontalInput(1);
      else if (event.logicalKey == settings.jumpKey) jump();
      else if (event.logicalKey == settings.attackKey) attack();
      else if (event.logicalKey == settings.shieldKey) setShielding(true);
      else if (event.logicalKey == settings.parryKey) parry();
      return true;
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == settings.leftKey && vx < 0) setHorizontalInput(0);
      else if (event.logicalKey == settings.rightKey && vx > 0) setHorizontalInput(0);
      else if (event.logicalKey == settings.shieldKey) setShielding(false);
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    vy += 900 * dt;
    // Cập nhật vị trí dùng vx hiện tại (đã bao gồm multiplier)
    position.x += vx * dt;
    position.y += vy * dt;

    final groundY = game.size.y - 48 - size.y / 2;
    if (position.y >= groundY) {
      position.y = groundY;
      vy = 0;
      isOnGround = true;
    }

    final minX = size.x / 2;
    final maxX = game.size.x - size.x / 2;
    if (position.x < minX) position.x = minX;
    if (position.x > maxX) position.x = maxX;

    if (_attacking) {
      _comboWindow -= dt;
      
      // Transition to attack2 when holding attack button (not shielding)
      if (_attackHeld && !_shielding && _comboStep == 1 && _comboWindow <= 0.2) {
        _comboStep = 2;
        _comboWindow = 0.4;
        current = 'attack2';
      }
      
      if (_comboWindow <= 0) {
        _attacking = false;
        _comboStep = 0;
        _applySpeed(); // Khôi phục tốc độ bình thường khi kết thúc đòn đánh
        _updateAnimationState();
      }
    }
  }
}

class RemotePlayer extends PositionComponent {
  RemotePlayer({required Vector2 position})
      : super(position: position, size: Vector2(32, 48), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blueGrey;
    canvas.drawRect(size.toRect(), paint);
  }

  void updatePosition(double targetX, double targetY, double dt) {
    position.x += (targetX - position.x) * 10 * dt;
    position.y += (targetY - position.y) * 10 * dt;
  }
}

class NgocRongGame extends FlameGame with HasKeyboardHandlerComponents {
  late LocalPlayer player;
  late SpriteComponent background;
  RectangleComponent? ground;
  GameSettings settings = GameSettings();

  @override
  Future<void> onLoad() async {
    final forest = await images.load('background/forest.png');
    background = SpriteComponent(
      sprite: Sprite(forest),
      size: size.clone(),
      priority: -1,
    );
    add(background);

    ground = null;

    player = LocalPlayer(position: Vector2(size.x / 2, size.y - 48 - 48), settings: settings);
    add(player);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      background.size = size.clone();
    }
  }
}