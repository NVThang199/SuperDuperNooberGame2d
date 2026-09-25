import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/particles.dart';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart' hide PointerMoveEvent, PointerDownEvent, PointerUpEvent;
import 'package:flutter/gestures.dart' show PointerMoveEvent, PointerDownEvent, PointerUpEvent;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class GameSettings {
  LogicalKeyboardKey leftKey = LogicalKeyboardKey.arrowLeft;
  LogicalKeyboardKey rightKey = LogicalKeyboardKey.arrowRight;
  LogicalKeyboardKey jumpKey = LogicalKeyboardKey.space;
  LogicalKeyboardKey attackKey = LogicalKeyboardKey.keyZ;
  LogicalKeyboardKey shieldKey = LogicalKeyboardKey.keyX;
  LogicalKeyboardKey perfectBlockKey = LogicalKeyboardKey.shiftLeft;
  bool showMobileControls = true;
  bool mouseControl = true;
}

class LocalPlayer extends SpriteAnimationGroupComponent<String> with HasGameReference<NgocRongGame>, KeyboardHandler {
  static const double jumpImpulse = -350.0;
  double get movementSpeed => size.y * 25 / 12;

  double vx = 0;
  double vy = 0;
  int direction = 1;
  bool isOnGround = true;
  bool _attacking = false;
  DateTime? _lastAttack;
  bool _shielding = false;
  bool _attackHeld = false;
  double _lastInput = 0;
  double _coyoteTimer = 0;
  double _jumpBuffer = 0;
  double _targetVx = 0;
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
    add(RectangleHitbox());
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
    _applySpeed();
    current = 'attack1';
  }

  void perfectBlock() {
    if (_attacking) return;
    _attacking = true;
    vx = 0;
    current = 'shieldAttack';
    Future.delayed(const Duration(milliseconds: 400), () {
      _attacking = false;
      _updateAnimationState();
    });
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
    } else if (_lastInput != 0) {
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
    _targetVx = _lastInput * movementSpeed * multiplier;
    if (_lastInput < -0.1) { direction = -1; flipAround(); }
    else if (_lastInput > 0.1) { direction = 1; flipAround(); }
    if (!_attacking) _updateAnimationState();
  }

  void _doJump() {
    vy = jumpImpulse;
    isOnGround = false;
    _coyoteTimer = 0;
    _jumpBuffer = 0;
  }

  void jump() {
    final canJump = isOnGround || _coyoteTimer > 0;
    if (canJump) {
      _doJump();
    } else {
      _jumpBuffer = 0.12;
    }
  }

  void flipAround() {
    if (direction == -1 && scale.x > 0) scale.x *= -1;
    else if (direction == 1 && scale.x < 0) scale.x *= -1;
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    if (!settings.mouseControl) return;
    final targetX = event.localPosition.dx;
    final currentX = position.x;
    if ((targetX - currentX).abs() > 5) {
      setHorizontalInput(targetX < currentX ? -1 : 1);
    } else {
      setHorizontalInput(0);
    }
  }

  @override
  void onPointerDown(PointerDownEvent event) {
    if (!settings.mouseControl) return;
    // Mouse button bits: left=1<<0, right=1<<1
    if ((event.buttons & (1 << 0)) != 0) {
      attack();
    }
    if ((event.buttons & (1 << 1)) != 0) {
      setShielding(true);
    }
  }

  @override
  void onPointerUp(PointerUpEvent event) {
    if (!settings.mouseControl) return;
    if ((event.buttons & (1 << 1)) == 0) {
      setShielding(false);
    }
    setHorizontalInput(0);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == settings.leftKey) setHorizontalInput(-1);
      else if (event.logicalKey == settings.rightKey) setHorizontalInput(1);
      else if (event.logicalKey == settings.jumpKey) jump();
      else if (event.logicalKey == settings.attackKey) attack();
      else if (event.logicalKey == settings.shieldKey) setShielding(true);
      else if (event.logicalKey == settings.perfectBlockKey) perfectBlock();
      return true;
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == settings.leftKey) setHorizontalInput(0);
      else if (event.logicalKey == settings.rightKey) setHorizontalInput(0);
      else if (event.logicalKey == settings.shieldKey) setShielding(false);
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_coyoteTimer > 0) _coyoteTimer = (_coyoteTimer - dt).clamp(0, 0.12);
    if (_jumpBuffer > 0) {
      _jumpBuffer -= dt;
      if (_jumpBuffer <= 0) _jumpBuffer = 0;
      else if (isOnGround || _coyoteTimer > 0) _doJump();
    }
    vx = lerpDouble(vx, _targetVx, (12 * dt).clamp(0.0, 1.0))!;
    vy += 900 * dt;
    final wasOnGround = isOnGround;
    position.x += vx * dt;
    position.y += vy * dt;

    final groundHeight = game.size.y * 0.1;
    final groundY = game.size.y - groundHeight - size.y / 2;
    if (position.y >= groundY) {
      position.y = groundY;
      vy = 0;
      isOnGround = true;
      if (_jumpBuffer > 0) _doJump();
    } else if (wasOnGround) {
      isOnGround = false;
      _coyoteTimer = 0.12;
    }

    final minX = size.x / 2;
    final maxX = game.size.x - size.x / 2;
    if (position.x < minX) position.x = minX;
    if (position.x > maxX) position.x = maxX;

    if (_attacking) {
      _comboWindow -= dt;
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

class VfxComponent extends ParticleSystemComponent {
  VfxComponent({required super.position, required Particle particle}) : super(particle: particle, size: Vector2.all(1));
}

class SlashVfx extends VfxComponent {
  SlashVfx({required Vector2 position}) : super(
    position: position,
    particle: CircleParticle(paint: Paint()..color = Colors.yellow, radius: 18, lifespan: 0.12),
  );
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

class NgocRongGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  double _shakeTimer = 0;
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

    final playerSize = size.y * 0.2;
    final groundHeight = size.y * 0.1;
    player = LocalPlayer(
      position: Vector2(size.x / 2, size.y - groundHeight - playerSize / 2),
      settings: settings,
    )..size = Vector2.all(playerSize);
    add(player);
    camera.follow(player);
    camera.viewfinder.zoom = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
       camera.viewfinder.position += Vector2((Random().nextDouble() - 0.5) * 4, (Random().nextDouble() - 0.5) * 4);
     }
   }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      background.size = size.clone();
      final playerSize = size.y * 0.2;
      final groundHeight = size.y * 0.1;
      player.size = Vector2.all(playerSize);
      player.position.y = size.y - groundHeight - playerSize / 2;
    }
  }
}