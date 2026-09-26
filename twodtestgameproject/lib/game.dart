import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart'
    hide PointerMoveEvent, PointerDownEvent, PointerUpEvent;
import 'package:flutter/gestures.dart'
    show PointerMoveEvent, PointerDownEvent, PointerUpEvent;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'character_config.dart';

class GameSettings {
  LogicalKeyboardKey leftKey = LogicalKeyboardKey.arrowLeft;
  LogicalKeyboardKey rightKey = LogicalKeyboardKey.arrowRight;
  LogicalKeyboardKey jumpKey = LogicalKeyboardKey.space;
  LogicalKeyboardKey attackKey = LogicalKeyboardKey.keyZ;
  LogicalKeyboardKey throwKey = LogicalKeyboardKey.keyC;
  LogicalKeyboardKey shieldKey = LogicalKeyboardKey.keyX;
  LogicalKeyboardKey runKey = LogicalKeyboardKey.shiftLeft;
  bool showMobileControls =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool mouseControl = true;
}

class RockProjectile extends SpriteComponent
    with HasGameReference<NgocRongGame> {
  final double vx;
  RockProjectile({
    required Vector2 position,
    required Sprite sprite,
    required this.vx,
    required Vector2 size,
  }) : super(
         position: position,
         sprite: sprite,
         size: size,
         anchor: Anchor.center,
         priority: 5,
       );

  @override
  void update(double dt) {
    super.update(dt);
    position.x += vx * dt;
    if (position.x < -100 || position.x > game.size.x + 100) {
      removeFromParent();
    }
  }
}

class DoubleJumpDust extends SpriteAnimationComponent
    with HasGameReference<NgocRongGame> {
  DoubleJumpDust({
    required Vector2 position,
    required SpriteAnimation animation,
    required Vector2 size,
  }) : super(
         position: position,
         animation: animation,
         size: size,
         anchor: Anchor.center,
         priority: 10,
       );

  @override
  void update(double dt) {
    super.update(dt);
    if (animationTicker?.done() ?? false) removeFromParent();
  }
}

class LocalPlayer extends SpriteAnimationGroupComponent<String>
    with HasGameReference<NgocRongGame>, KeyboardHandler {
  double get jumpImpulse => -size.y * 13;
  double get gravity => size.y * 65;
  double get movementSpeed => size.y * 25 / 12;

  double vx = 0;
  double vy = 0;
  int direction = 1;
  bool isOnGround = true;
  bool _attacking = false;
  DateTime? _lastAttack;
  bool _shielding = false;
  bool _running = false;
  bool _attackHeld = false;
  double _lastInput = 0;
  double _coyoteTimer = 0;
  double _jumpBuffer = 0;
  double _targetVx = 0;
  final GameSettings settings;
  final CharacterConfig character;
  bool _doubleJumpUsed = false;
  SpriteAnimation? _dustAnimation;
  SpriteAnimation? _walkRunPushDustAnimation;
  SpriteAnimation? _throwAnimation;
  Sprite? _rockSprite;
  double _runDustTimer = 0;
  bool _throwing = false;
  double _throwTimer = 0;
  double _throwSpawnDelay = 0;
  bool _throwSpawned = false;

  int _comboStep = 0;
  double _comboWindow = 0;
  bool get canAttack => true;

  LocalPlayer({
    required Vector2 position,
    required this.character,
    GameSettings? settings,
  }) : settings = settings ?? GameSettings(),
       super(position: position, size: Vector2(96, 96), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final idleSheet = await game.images.load(character.idlePath);
    final walkSheet = await game.images.load(character.walkPath);
    final runSheet = await game.images.load(character.runPath);
    final walkRunPushDustSheet = await game.images.load(
      character.walkRunPushDustPath,
    );
    final walkAttackSheet = await game.images.load(character.walkAttackPath);
    final attack1Sheet = await game.images.load(character.attack1Path);
    final attack2Sheet = await game.images.load(character.attack2Path);
    final jumpSheet = await game.images.load(character.jumpPath);
    final pushSheet = await game.images.load(character.pushPath);
    final dustSheet = await game.images.load(character.doubleJumpDustPath);
    final throwSheet = await game.images.load(character.throwPath);
    final rockImage = await game.images.load('${character.basePath}/Rock1.png');
    _rockSprite = Sprite(rockImage);
    final throwAnim = SpriteAnimation.fromFrameData(
      throwSheet,
      SpriteAnimationData.sequenced(
        amount: character.throwAmount,
        stepTime: character.throwStepTime,
        textureSize: character.textureSize,
        loop: false,
      ),
    );
    _throwAnimation = throwAnim;

    _dustAnimation = SpriteAnimation.fromFrameData(
      dustSheet,
      SpriteAnimationData.sequenced(
        amount: character.doubleJumpDustAmount,
        stepTime: character.doubleJumpDustStepTime,
        textureSize: character.textureSize,
        loop: false,
      ),
    );
    _walkRunPushDustAnimation = SpriteAnimation.fromFrameData(
      walkRunPushDustSheet,
      SpriteAnimationData.sequenced(
        amount: character.walkRunPushDustAmount,
        stepTime: character.walkRunPushDustStepTime,
        textureSize: character.textureSize,
        loop: false,
      ),
    );

    animations = {
      'idle': SpriteAnimation.fromFrameData(
        idleSheet,
        SpriteAnimationData.sequenced(
          amount: character.idleAmount,
          stepTime: character.idleStepTime,
          textureSize: character.textureSize,
        ),
      ),
      'walk': SpriteAnimation.fromFrameData(
        walkSheet,
        SpriteAnimationData.sequenced(
          amount: character.walkAmount,
          stepTime: character.walkStepTime,
          textureSize: character.textureSize,
        ),
      ),
      'run': SpriteAnimation.fromFrameData(
        runSheet,
        SpriteAnimationData.sequenced(
          amount: character.runAmount,
          stepTime: character.runStepTime,
          textureSize: character.textureSize,
        ),
      ),
      'throw': _throwAnimation!,
      'walkAttack': SpriteAnimation.fromFrameData(
        walkAttackSheet,
        SpriteAnimationData.sequenced(
          amount: character.walkAttackAmount,
          stepTime: character.walkAttackStepTime,
          textureSize: character.textureSize,
          loop: true,
        ),
      ),
      'attack1': SpriteAnimation.fromFrameData(
        attack1Sheet,
        SpriteAnimationData.sequenced(
          amount: character.attack1Amount,
          stepTime: character.attack1StepTime,
          textureSize: character.textureSize,
          loop: false,
        ),
      ),
      'attack2': SpriteAnimation.fromFrameData(
        attack2Sheet,
        SpriteAnimationData.sequenced(
          amount: character.attack2Amount,
          stepTime: character.attack2StepTime,
          textureSize: character.textureSize,
          loop: false,
        ),
      ),
      'jump': SpriteAnimation.fromFrameData(
        jumpSheet,
        SpriteAnimationData.sequenced(
          amount: character.jumpAmount,
          stepTime: character.jumpStepTime,
          textureSize: character.textureSize,
          loop: false,
        ),
      ),
      'doubleJump': SpriteAnimation.fromFrameData(
        jumpSheet,
        SpriteAnimationData.sequenced(
          amount: character.jumpAmount,
          stepTime: character.jumpStepTime,
          textureSize: character.textureSize,
          loop: false,
        ),
      ),
      'push': SpriteAnimation.fromFrameData(
        pushSheet,
        SpriteAnimationData.sequenced(
          amount: character.pushAmount,
          stepTime: character.pushStepTime,
          textureSize: character.textureSize,
        ),
      ),
    };
    current = 'idle';
    add(RectangleHitbox());
  }

  String _attackAnimForCombo(int step) {
    if (step == 2) return 'attack2';
    if (_lastInput.abs() > 0.1) return 'walkAttack';
    return 'attack1';
  }

  void attack() {
    if (_shielding) return;
    if (_attacking) {
      if (_comboStep == 1 && _comboWindow <= 0.18) {
        _comboStep = 2;
        _comboWindow = 0.48;
        current = 'attack2';
      }
      return;
    }
    if (_lastAttack != null &&
        DateTime.now().difference(_lastAttack!) <
            const Duration(milliseconds: 200))
      return;
    _lastAttack = DateTime.now();
    _attacking = true;
    _comboStep = 1;
    _comboWindow = 0.48;
    _applySpeed();
    current = _attackAnimForCombo(1);
  }

  void _spawnRock() {
    if (_rockSprite == null) return;
    game.add(
      RockProjectile(
        position: position + Vector2(direction * size.x * 0.45, size.y * 0.05),
        sprite: _rockSprite!,
        vx: direction * movementSpeed * 2.5,
        size: Vector2.all(size.y * 0.30),
      ),
    );
  }

  void throwRock() {
    if (_throwing || _shielding || _rockSprite == null) return;
    _throwing = true;
    _throwTimer = character.throwAmount * character.throwStepTime;
    _throwSpawnDelay = _throwTimer * 0.70;
    _throwSpawned = false;
    _targetVx = 0;
    current = 'throw';
  }

  void setAttackHeld(bool active) {
    _attackHeld = active;
    if (active) attack();
  }

  void setShielding(bool active) {
    _shielding = active;
    _applySpeed();
    if (!_attacking) {
      _updateAnimationState();
    }
  }

  void toggleShield() => setShielding(!_shielding);

  void setRunning(bool active) {
    _running = active;
    _applySpeed();
    if (!_attacking) _updateAnimationState();
  }

  void _updateAnimationState() {
    if (_attacking || _throwing) return;
    if (_shielding) {
      current = 'push';
    } else if (!isOnGround) {
      current = _doubleJumpUsed ? 'doubleJump' : 'jump';
    } else if (_lastInput != 0) {
      current = _running ? 'run' : 'walk';
    } else {
      current = 'idle';
    }
  }

  void setHorizontalInput(double input) {
    _lastInput = input;
    _applySpeed();
  }

  void _applySpeed() {
    double runMul = _running && isOnGround ? 1.7 : 1.0;
    double multiplier = _attacking ? 0.2 : (_shielding ? 0.3 : runMul);
    _targetVx = _lastInput * movementSpeed * multiplier;
    if (_lastInput < -0.1) {
      direction = -1;
      flipAround();
    } else if (_lastInput > 0.1) {
      direction = 1;
      flipAround();
    }
    if (!_attacking) _updateAnimationState();
  }

  void _doJump({bool isDouble = false}) {
    vy = jumpImpulse;
    isOnGround = false;
    _coyoteTimer = 0;
    _jumpBuffer = 0;
    if (isDouble) {
      _doubleJumpUsed = true;
      current = 'doubleJump';
      _spawnDust();
    } else {
      current = 'jump';
    }
  }

  void _spawnDust() {
    if (_dustAnimation == null) return;
    final anim = _dustAnimation!.clone();
    final dust = DoubleJumpDust(
      position: position.clone(),
      animation: anim,
      size: Vector2.all(size.y * 1.15),
    );
    game.add(dust);
  }

  void _spawnRunPushDust() {
    if (_walkRunPushDustAnimation == null) return;
    final anim = _walkRunPushDustAnimation!.clone();
    final behind = Vector2(
      position.x - direction * 6,
      position.y - size.y * 0.05,
    );
    final dust = DoubleJumpDust(
      position: behind,
      animation: anim,
      size: Vector2.all(size.y * 1.15),
    );
    dust.scale.x = direction < 0 ? -1 : 1;
    game.add(dust);
  }

  void jump() {
    final canJump = isOnGround || _coyoteTimer > 0;
    if (canJump) {
      _doubleJumpUsed = false;
      _doJump(isDouble: false);
    } else if (!_doubleJumpUsed) {
      _doJump(isDouble: true);
    } else {
      _jumpBuffer = 0.12;
    }
  }

  void flipAround() {
    if (direction == -1 && scale.x > 0)
      scale.x *= -1;
    else if (direction == 1 && scale.x < 0)
      scale.x *= -1;
  }

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
      if (event.logicalKey == settings.leftKey)
        setHorizontalInput(-1);
      else if (event.logicalKey == settings.rightKey)
        setHorizontalInput(1);
      else if (event.logicalKey == settings.jumpKey)
        jump();
      else if (event.logicalKey == settings.attackKey)
        attack();
      else if (event.logicalKey == settings.throwKey)
        throwRock();
      else if (event.logicalKey == settings.shieldKey)
        setShielding(true);
      else if (event.logicalKey == settings.runKey)
        setRunning(true);
      return true;
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == settings.leftKey)
        setHorizontalInput(0);
      else if (event.logicalKey == settings.rightKey)
        setHorizontalInput(0);
      else if (event.logicalKey == settings.shieldKey)
        setShielding(false);
      else if (event.logicalKey == settings.runKey)
        setRunning(false);
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_throwing) {
      _throwSpawnDelay -= dt;
      if (!_throwSpawned && _throwSpawnDelay <= 0) {
        _throwSpawned = true;
        _spawnRock();
      }
      _throwTimer -= dt;
      if (_throwTimer <= 0) {
        _throwing = false;
        _throwSpawned = false;
        _updateAnimationState();
      }
    }
    if (_coyoteTimer > 0) _coyoteTimer = (_coyoteTimer - dt).clamp(0, 0.12);
    if (_jumpBuffer > 0) {
      _jumpBuffer -= dt;
      if (_jumpBuffer <= 0)
        _jumpBuffer = 0;
      else if (isOnGround || _coyoteTimer > 0) {
        _doubleJumpUsed = false;
        _doJump();
      }
    }
    vx = lerpDouble(vx, _targetVx, (12 * dt).clamp(0.0, 1.0))!;
    vy += gravity * dt;
    final wasOnGround = isOnGround;
    position.x += vx * dt;
    position.y += vy * dt;

    final groundHeight = game.size.y * 0.1;
    final groundY = game.size.y - groundHeight - size.y / 2;
    if (position.y >= groundY) {
      position.y = groundY;
      vy = 0;
      final justLanded = !isOnGround;
      isOnGround = true;
      if (justLanded) _doubleJumpUsed = false;
      if (_jumpBuffer > 0) {
        _doubleJumpUsed = false;
        _doJump();
      } else if (!_attacking) {
        _updateAnimationState();
      }
    } else if (wasOnGround) {
      isOnGround = false;
      _coyoteTimer = 0.12;
    }

    if (isOnGround && _running && _lastInput != 0 && !_attacking) {
      _runDustTimer -= dt;
      if (_runDustTimer <= 0) {
        _runDustTimer = 0.18;
        _spawnRunPushDust();
      }
    } else {
      _runDustTimer = 0;
    }

    if (!isOnGround && !_attacking && !_shielding) {
      _updateAnimationState();
    }

    final minX = size.x / 2;
    final maxX = game.size.x - size.x / 2;
    if (position.x < minX) position.x = minX;
    if (position.x > maxX) position.x = maxX;

    if (_attacking) {
      _comboWindow -= dt;
      if (_attackHeld &&
          !_shielding &&
          _comboStep == 1 &&
          _comboWindow <= 0.08) {
        _comboStep = 2;
        _comboWindow = 0.48;
        current = 'attack2';
      }

      if (_comboWindow <= 0) {
        _attacking = false;
        _comboStep = 0;
        _applySpeed();
        if (_attackHeld && !_shielding) {
          attack();
        } else {
          _updateAnimationState();
        }
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

class NgocRongGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  static final Random _shakeRandom = Random();
  final Vector2 _shakeOffset = Vector2.zero();
  double _shakeTimer = 0;
  late LocalPlayer player;
  late SpriteComponent background;
  late SpriteComponent background1;
  late SpriteComponent chest;
  late SpriteAnimationComponent fire;
  late Sprite chestOpenSprite;
  RectangleComponent? ground;
  GameSettings settings = GameSettings();
  final CharacterConfig character;
  final ValueNotifier<bool> canOpenChest = ValueNotifier(false);
  int currentMap = 0;
  bool chestOpen = false;

  NgocRongGame({required this.character});

  @override
  Future<void> onLoad() async {
    final forest = await images.load('background/forest.png');
    background = SpriteComponent(
      sprite: Sprite(forest),
      size: size.clone(),
      priority: -1,
    );
    add(background);

    final forest1 = await images.load('background/forest_map1.png');
    background1 = SpriteComponent(
      sprite: Sprite(forest1),
      size: size.clone(),
      priority: -1,
    );

    final chestImg = await images.load('Chest.png');
    final chestPos = Vector2(
      size.x * 0.7,
      size.y - size.y * 0.1 - size.y * 0.2 + size.y * 0.08,
    );
    chest = SpriteComponent(
      sprite: Sprite(
        chestImg,
        srcPosition: Vector2.zero(),
        srcSize: Vector2.all(32),
      ),
      size: Vector2.all(size.y * 0.15),
      position: chestPos,
      priority: 1,
    );
    // ponytail: frame dau = rương đóng, frame cuối = rương mở. Nếu sheet đổi thứ tự frame, đổi 2 số này.
    chestOpenSprite = Sprite(
      chestImg,
      srcPosition: Vector2(32 * 3, 0),
      srcSize: Vector2.all(32),
    );

    final fireImg = await images.load('Fire.png');
    fire = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        fireImg,
        SpriteAnimationData.sequenced(
          amount: 5,
          stepTime: 0.1,
          textureSize: Vector2.all(32),
        ),
      ),
      size: Vector2.all(size.y * 0.12),
      position: Vector2(size.x * 0.3, size.y - size.y * 0.1 - size.y * 0.06),
      priority: 0,
    );

    ground = null;

    final playerSize = size.y * 0.2;
    final groundHeight = size.y * 0.1;
    player = LocalPlayer(
      position: Vector2(size.x / 2, size.y - groundHeight - playerSize / 2),
      character: character,
      settings: settings,
    )..size = Vector2.all(playerSize);
    add(player);
    camera.follow(player);
    camera.viewfinder.zoom = 1.0;
    add(chest);
    add(fire);
  }

  void openChest() {
    if (!canOpenChest.value) return;
    chestOpen = !chestOpen;
    if (chestOpen) {
      chest.sprite = chestOpenSprite;
    } else {
      chest.sprite = Sprite(
        chest.sprite!.image,
        srcPosition: Vector2.zero(),
        srcSize: Vector2.all(32),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Rương + lửa chỉ ở map 0 (forest). Sang map 1 thì gỡ, về map 0 thì thêm lại.
    if (currentMap == 0 && player.position.x > size.x * 0.95) {
      currentMap = 1;
      background.removeFromParent();
      add(background1);
      chest.removeFromParent();
      fire.removeFromParent();
      canOpenChest.value = false;
      player.position.x = size.x * 0.1;
    } else if (currentMap == 1 && player.position.x < size.x * 0.05) {
      currentMap = 0;
      background1.removeFromParent();
      add(background);
      // Chest giữ trạng thái mở/đóng, add lại luôn để rương ở map 0.
      add(chest);
      add(fire);
      player.position.x = size.x * 0.9;
    }

    // Hiển thị nút "Mở/Đóng rương" khi player gần chest trên map 0.
    if (currentMap == 0) {
      final dist = (player.position - chest.position).length;
      canOpenChest.value = dist < size.y * 0.12;
    } else {
      canOpenChest.value = false;
    }

    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      camera.viewfinder.position -= _shakeOffset;
      _shakeOffset.setValues(
        (_shakeRandom.nextDouble() - 0.5) * 4,
        (_shakeRandom.nextDouble() - 0.5) * 4,
      );
      camera.viewfinder.position += _shakeOffset;
    } else if (_shakeOffset.length > 0) {
      camera.viewfinder.position -= _shakeOffset;
      _shakeOffset.setZero();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      background.size = size.clone();
      background1.size = size.clone();
      chest.size = Vector2.all(size.y * 0.15);
      fire.size = Vector2.all(size.y * 0.12);
      final playerSize = size.y * 0.2;
      final groundHeight = size.y * 0.1;
      player.size = Vector2.all(playerSize);
      player.position.y = size.y - groundHeight - playerSize / 2;
      final maxX = size.x - playerSize / 2;
      if (player.position.x > maxX) player.position.x = maxX;
    }
  }
}
