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

import 'inventory.dart';
import 'item_loader.dart';
import 'inventory.dart';
import 'item_loader.dart';

import 'character_config.dart';
import 'shield_badge.dart';
import 'stamina_config.dart';
import 'boss.dart';

class DamageConfig {
  static const double swordBaseDamage = 20.0;
  static const double bowBaseDamage = 18.0;
  static const double noneBaseDamage = 10.0;
  static const double slimeBaseDamage = 30.0;
  static const double bossAttackDamage = 60.0;
  static const double bossSkillDamage = 120.0;
  static const double bossMinionDamage = 5.0;
}

class GameSettings {
  LogicalKeyboardKey leftKey = LogicalKeyboardKey.arrowLeft;
  LogicalKeyboardKey rightKey = LogicalKeyboardKey.arrowRight;
  LogicalKeyboardKey jumpKey = LogicalKeyboardKey.space;
  LogicalKeyboardKey attackKey = LogicalKeyboardKey.keyZ;
  LogicalKeyboardKey shieldKey = LogicalKeyboardKey.keyX;
  LogicalKeyboardKey runKey = LogicalKeyboardKey.shiftLeft;
  LogicalKeyboardKey chestKey = LogicalKeyboardKey.keyR;
  LogicalKeyboardKey inventoryKey = LogicalKeyboardKey.keyI;
  LogicalKeyboardKey squatKey = LogicalKeyboardKey.arrowDown;
  bool showMobileControls =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool mouseControl = true;
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

class ArrowProjectile extends SpriteComponent
    with HasGameReference<NgocRongGame> {
  final double vx;
  final double damage;

  ArrowProjectile({
    required Vector2 position,
    required Sprite sprite,
    required this.vx,
    required this.damage,
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
    if (game.currentMap == 1 &&
        !game.slime._dead &&
        (position - game.slime.position).length < game.slime.size.x * 0.35) {
      game.slime.takeDamage(damage);
      removeFromParent();
    } else if (game.currentMap == 2 &&
        !game.boss.dead &&
        (position - game.boss.position).length < BossEnemy.frameSize * 1.2) {
      game.boss.takeDamage(damage);
      removeFromParent();
    } else if (position.x < -100 || position.x > game.size.x + 100) {
      removeFromParent();
    }
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
  final Set<LogicalKeyboardKey> _keysPressed = {};
  final Set<double> _movementInputs = {};
  bool _shieldBroken = false;
  SpriteAnimation? _dustAnimation;
  SpriteAnimation? _walkRunPushDustAnimation;
  SpriteAnimation? _deathAnimation;
  SpriteAnimation? _hurtAnimation;
  Map<String, SpriteAnimation>? _baseAnimations;
  double health = 100;
  double maxHealth = 100;
  int dmgBonus = 0;
  int defenseBonus = 0;
  final ValueNotifier<double> healthNotifier = ValueNotifier(100);
  final ValueNotifier<double> maxHealthNotifier = ValueNotifier(100);
  double shield = 100;
  double maxShield = 100;
  final ValueNotifier<double> shieldNotifier = ValueNotifier(100);
  bool _stunned = false;
  double _stunTimer = 0;
  bool get isStunned => _stunned;
  bool get isShielding => _shielding;
  bool get isShieldBroken => _shieldBroken;
  late ShieldBadge _shieldBadge;
  double _runDustTimer = 0;
  bool _squatting = false;

  int _comboStep = 0;
  bool _comboHit1 = false;
  bool _comboHit2 = false;
  double _comboWindow = 0;
  bool _dead = false;
  bool get isDead => _dead;
  double _deathAnimTimer = 0;
  double _respawnTimer = 0;
  double _invincibilityTimer = 0;
  bool _hurt = false;
  double _hurtTimer = 0;
  bool get canAttack => true;
  double stamina = StaminaConfig.maxStamina;
  double maxStamina = StaminaConfig.maxStamina;
  final ValueNotifier<double> staminaNotifier = ValueNotifier(
    StaminaConfig.maxStamina,
  );
  double _staminaRegenDelay = 0;
  bool _staminaExhausted = false;
  final ValueNotifier<bool> inventoryOpen = ValueNotifier(false);
  final ValueNotifier<int> inventoryPage = ValueNotifier(0);
  final ValueNotifier<int> weaponTypeVersion = ValueNotifier(0);
  final InventoryState inventory = InventoryState();
  List<InventoryItem> itemCatalog = [];

  bool _canUseStamina(double amount) => !_staminaExhausted && stamina >= amount;

  bool get _hasRecoveredStamina => stamina >= maxStamina * 0.5;
  double get baseDamage => _getWeaponBaseDamage();

  LocalPlayer({
    required Vector2 position,
    required this.character,
    GameSettings? settings,
  }) : settings = settings ?? GameSettings(),
       super(
         position: position,
         size: Vector2(96, 96),
         anchor: Anchor.center,
         priority: 5,
       );

  SpriteAnimation _loadAnim(
    String path,
    int amount,
    double stepTime,
    Vector2 size, {
    bool loop = true,
  }) => SpriteAnimation.fromFrameData(
    game.images.fromCache(path),
    SpriteAnimationData.sequenced(
      amount: amount,
      stepTime: stepTime,
      textureSize: size,
      loop: loop,
    ),
  );

  Future<SpriteAnimation> _loadWeaponSheet(
    String file,
    int frames, {
    bool loop = true,
    double stepTime = 0.1,
  }) async {
    final kind = game.inventory.weaponType;
    final folder = kind == 'sword' ? 'sword' : 'bow';
    final actualPath = 'characters/${character.id}_monster_$folder/$file';
    final image = await game.images.load(actualPath);
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: Vector2.all(42),
        loop: loop,
      ),
    );
  }

  Future<void> _loadAnimations() async {
    final kind = game.inventory.weaponType;
    if (kind == 'none') {
      animations = _baseAnimations;
      current = 'idle';
      size = Vector2.all(game.size.y * 0.2); // Restore base size
      return;
    }
    final isSword = kind == 'sword';
    final jump = await _loadWeaponSheet('Jump.png', 8, loop: false);
    final attack1 = await _loadWeaponSheet(
      isSword ? 'Attack1.png' : 'Attack.png',
      6,
      loop: false,
    );
    final walkAttack = await _loadWeaponSheet(
      isSword ? 'WalkAttack1.png' : 'WalkAttack.png',
      6,
      loop: false,
    );
    final runAttack1 = await _loadWeaponSheet(
      isSword ? 'RunAttack1.png' : 'RunAttack.png',
      6,
      loop: false,
    );
    final squat = await _loadWeaponSheet(
      isSword || character.id != 'dude' ? 'Squat.png' : 'Squad.png',
      4,
    );

    final newAnimations = <String, SpriteAnimation>{
      'idle': await _loadWeaponSheet('Idle.png', 4),
      'walk': await _loadWeaponSheet('Walk.png', 6),
      'run': await _loadWeaponSheet('Run.png', 6),
      'walkAttack': walkAttack,
      'attack1': attack1,
      'jump': jump,
      'doubleJump': jump,
      'jumpAttack': await _loadWeaponSheet('JumpAttack.png', 6, loop: false),
      'fallAttack': await _loadWeaponSheet('FallAttack.png', 6, loop: false),
      'runAttack1': runAttack1,
      'squat': squat,
      'death': await _loadWeaponSheet('Death.png', 8, loop: false),
      'hurt': await _loadWeaponSheet('Hurt.png', 4, loop: false),
    };
    if (isSword) {
      newAnimations['attack2'] = await _loadWeaponSheet(
        'Attack2.png',
        6,
        loop: false,
      );
      newAnimations['runAttack2'] = await _loadWeaponSheet(
        'RunAttack2.png',
        6,
        loop: false,
      );
      newAnimations['squatAttack'] = await _loadWeaponSheet(
        'SquatAttack.png',
        6,
        loop: false,
      );
    }

    // Xóa group cũ, thay mới hoàn toàn để không dùng sprite nhân vật gốc
    animations = newAnimations;
    current = 'idle';
  }

  @override
  Future<void> onLoad() async {
    final paths = [
      character.idlePath,
      character.walkPath,
      character.runPath,
      character.walkRunPushDustPath,
      character.walkAttackPath,
      character.attack1Path,
      character.attack2Path,
      character.jumpPath,
      character.pushPath,
      character.doubleJumpDustPath,
      character.deathPath,
      character.hurtPath,
    ];
    await game.images.loadAll(paths);

    _deathAnimation = _loadAnim(
      character.deathPath,
      character.deathAmount,
      character.deathStepTime,
      character.textureSize,
      loop: false,
    );
    _hurtAnimation = _loadAnim(
      character.hurtPath,
      character.hurtAmount,
      character.hurtStepTime,
      character.textureSize,
      loop: false,
    );
    _dustAnimation = _loadAnim(
      character.doubleJumpDustPath,
      character.doubleJumpDustAmount,
      character.doubleJumpDustStepTime,
      character.textureSize,
      loop: false,
    );
    _walkRunPushDustAnimation = _loadAnim(
      character.walkRunPushDustPath,
      character.walkRunPushDustAmount,
      character.walkRunPushDustStepTime,
      character.textureSize,
      loop: false,
    );

    animations = {
      'idle': _loadAnim(
        character.idlePath,
        character.idleAmount,
        character.idleStepTime,
        character.textureSize,
      ),
      'walk': _loadAnim(
        character.walkPath,
        character.walkAmount,
        character.walkStepTime,
        character.textureSize,
      ),
      'run': _loadAnim(
        character.runPath,
        character.runAmount,
        character.runStepTime,
        character.textureSize,
      ),
      'death': _deathAnimation!,
      'hurt': _hurtAnimation!,
      'walkAttack': _loadAnim(
        character.walkAttackPath,
        character.walkAttackAmount,
        character.walkAttackStepTime,
        character.textureSize,
      ),
      'attack1': _loadAnim(
        character.attack1Path,
        character.attack1Amount,
        character.attack1StepTime,
        character.textureSize,
        loop: false,
      ),
      'attack2': _loadAnim(
        character.attack2Path,
        character.attack2Amount,
        character.attack2StepTime,
        character.textureSize,
        loop: false,
      ),
      'jump': _loadAnim(
        character.jumpPath,
        character.jumpAmount,
        character.jumpStepTime,
        character.textureSize,
        loop: false,
      ),
      'doubleJump': _loadAnim(
        character.jumpPath,
        character.jumpAmount,
        character.jumpStepTime,
        character.textureSize,
        loop: false,
      ),
      'push': _loadAnim(
        character.pushPath,
        character.pushAmount,
        character.pushStepTime,
        character.textureSize,
        loop: false,
      ),
      'stun': SpriteAnimation.fromFrameData(
        game.images.fromCache(character.deathPath),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: character.textureSize,
          texturePosition: Vector2(character.textureSize.x, 0),
          loop: false,
        ),
      ),
    };

    _baseAnimations = Map<String, SpriteAnimation>.from(animations!);
    current = 'idle';
    add(RectangleHitbox());
    _shieldBadge = ShieldBadge(player: this);
    game.add(_shieldBadge);
    await _loadAnimations();
  }

  double _getWeaponBaseDamage() {
    return switch (game.inventory.weaponType) {
      'sword' => DamageConfig.swordBaseDamage,
      'bow' => DamageConfig.bowBaseDamage,
      _ => DamageConfig.noneBaseDamage,
    };
  }

  void refreshWeaponAnimation() {
    if (!isLoaded) return;
    size = Vector2.all(
      game.size.y * 0.2 * (game.inventory.weaponType == 'none' ? 1 : 42 / 32),
    );
    _loadAnimations().then((_) {
      current = 'idle';
    });
  }

  String _attackAnimForCombo(int step) {
    if (_squatting &&
        isOnGround &&
        animations?.containsKey('squatAttack') == true)
      return 'squatAttack';
    if (!isOnGround && animations?.containsKey('jumpAttack') == true)
      return 'jumpAttack';
    if (_running && _lastInput.abs() > 0.1) {
      final runAttack = step == 2 ? 'runAttack2' : 'runAttack1';
      if (animations?.containsKey(runAttack) == true) return runAttack;
    }
    if (step == 2 && animations?.containsKey('attack2') == true)
      return 'attack2';
    if (_lastInput.abs() > 0.1) return 'walkAttack';
    return 'attack1';
  }

  void _triggerStun() {
    if (_stunned) return;
    _stunned = true;
    _stunTimer = 1.0;
    _shielding = false;
    _attacking = false;
    _targetVx = 0;
    vx = 0;
    current = 'stun';
  }

  void damageShield(double dmg) {
    if (!_shielding || _stunned) return;
    consumeStamina(dmg * 1.5);
    if (stamina <= 0) {
      _shieldBroken = true;
      _triggerStun();
    }
  }

  void _dealMeleeDamage(int step) {
    if (step == 1 && _comboHit1) return;
    if (step == 2 && _comboHit2) return;
    if (step == 1) {
      _comboHit1 = true;
    } else {
      _comboHit2 = true;
    }

    final baseDamage = _getWeaponBaseDamage();
    final totalDamage = baseDamage + dmgBonus;

    if (game.currentMap == 1) {
      final slime = game.slime;
      if (!slime._dead &&
          (position - slime.position).length < (size.x + slime.size.x) * 0.35) {
        slime.takeDamage(totalDamage);
      }
    } else if (game.currentMap == 2) {
      final boss = game.boss;
      if (!boss.dead &&
          (position - boss.position).length < (size.x + boss.size.x) * 0.5) {
        boss.takeDamage(totalDamage);
      }
      for (final minion in game.children.whereType<BossMinion>().toList()) {
        if (!minion.dead &&
            (position - minion.position).length <
                (size.x + minion.size.x) * 0.5) {
          minion.takeDamage(totalDamage);
        }
      }
    }
  }

  Sprite? _arrowSprite;
  double _arrowSpawnDelay = 0;
  bool _arrowSpawned = false;

  Future<void> _loadArrowSprite() async {
    if (_arrowSprite != null) return;
    final image = await game.images.load(
      'characters/${character.id}_monster_bow/Arrows.png',
    );
    _arrowSprite = Sprite(
      image,
      srcPosition: Vector2.zero(),
      srcSize: Vector2(image.width.toDouble(), image.height.toDouble()),
    );
  }

  void _spawnArrow() {
    if (_arrowSpawned || _arrowSprite == null) return;
    _arrowSpawned = true;
    game.add(
      ArrowProjectile(
        position: position + Vector2(size.x * 0.45 * direction, size.y * 0.25),
        sprite: _arrowSprite!,
        vx: direction * size.y * 4,
        damage: _getWeaponBaseDamage() + dmgBonus,
        size: Vector2(size.y * 0.6, size.y * 0.15),
      ),
    );
  }

  void attack() {
    if (_stunned || _shielding) return;
    if (!_canUseStamina(StaminaConfig.attackCost)) return;
    if (_attacking) {
      if (game.inventory.weaponType != 'bow' &&
          _comboStep == 1 &&
          _comboWindow <= 0.18) {
        _comboStep = 2;
        _comboWindow = 0.48;
        current = 'attack2';
        consumeStamina(StaminaConfig.attackCost);
        _dealMeleeDamage(2);
      }
      return;
    }
    if (_lastAttack != null &&
        DateTime.now().difference(_lastAttack!) <
            const Duration(milliseconds: 200))
      return;
    _lastAttack = DateTime.now();
    _comboHit1 = false;
    _comboHit2 = false;
    consumeStamina(StaminaConfig.attackCost);
    if (game.inventory.weaponType == 'bow') {
      _arrowSprite = null;
      _arrowSpawned = false;
      _arrowSpawnDelay = 0.18;
      _loadArrowSprite();
    } else {
      _dealMeleeDamage(1);
    }
    _attacking = true;
    _comboStep = 1;
    _comboWindow = 0.48;
    _applySpeed();
    current = _attackAnimForCombo(1);
  }

  void setAttackHeld(bool active) {
    _attackHeld = active;
    if (active) attack();
  }

  void setShielding(bool active) {
    if (_stunned) return;
    if (active && _stunTimer > 0) {
      _shieldBroken = true;
      _stunTimer = 0;
      _stunned = false;
      _stunTimer = 0;
    }
    _shielding = active;
    _applySpeed();
    if (!_attacking) {
      _updateAnimationState();
    }
  }

  void toggleShield() => setShielding(!_shielding);

  void setRunning(bool active) {
    _running = active && _canUseStamina(0);
    _applySpeed();
    if (!_attacking) _updateAnimationState();
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

  void consumeStamina(double amount) {
    stamina = (stamina - amount).clamp(0.0, maxStamina);
    staminaNotifier.value = stamina;
    _staminaRegenDelay = StaminaConfig.regenDelay;
    if (stamina < StaminaConfig.attackCost) {
      _staminaExhausted = true;
    }
  }

  void _updateStamina(double dt) {
    if (_staminaExhausted && _hasRecoveredStamina) {
      _staminaExhausted = false;
    }
    if (_staminaRegenDelay > 0) {
      _staminaRegenDelay -= dt;
      stamina = (stamina + StaminaConfig.activeRegenRate * dt).clamp(
        0.0,
        maxStamina,
      );
    } else if (_shielding) {
      stamina = (stamina + StaminaConfig.shieldRegenRate * dt).clamp(
        0.0,
        maxStamina,
      );
    } else {
      stamina = (stamina + StaminaConfig.idleRegenRate * dt).clamp(
        0.0,
        maxStamina,
      );
    }
    if (_shieldBroken && stamina >= maxStamina * 0.5) {
      _shieldBroken = false;
    }
    staminaNotifier.value = stamina;
  }

  void _updateAnimationState() {
    if (_attacking) return;
    final hasMovementInput =
        _keysPressed.contains(settings.leftKey) ||
        _keysPressed.contains(settings.rightKey) ||
        _lastInput.abs() > 0.01;
    if (_squatting && isOnGround) {
      current = 'squat';
    } else if (_shielding) {
      current = 'push';
    } else if (!isOnGround) {
      current = _doubleJumpUsed ? 'doubleJump' : 'jump';
    } else if (hasMovementInput) {
      current = _running ? 'run' : 'walk';
    } else {
      current = 'idle';
    }
  }

  void setHorizontalInput(double input) {
    if (input == 0) {
      _movementInputs.clear();
    } else {
      _movementInputs
        ..removeWhere((value) => value == -input)
        ..add(input);
    }
    _applyHorizontalInput();
  }

  void _applyHorizontalInput() {
    final input = _movementInputs.isEmpty ? 0.0 : _movementInputs.last;
    _lastInput = _stunned ? 0 : input;
    _applySpeed();
  }

  void _updateMovementDirection() {
    final right = _keysPressed.contains(settings.rightKey);
    final left = _keysPressed.contains(settings.leftKey);
    setHorizontalInput(right == left ? 0 : (right ? 1 : -1));
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
      if (!_canUseStamina(StaminaConfig.doubleJumpCost)) return;
      consumeStamina(StaminaConfig.doubleJumpCost);
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
    if (game.isPaused.value) return;
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
    if (game.isPaused.value) return;
    if (!settings.mouseControl) return;
    if ((event.buttons & (1 << 1)) == 0) {
      setShielding(false);
    }
    setHorizontalInput(0);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.isPaused.value) return false;
    _keysPressed
      ..removeWhere(
        (key) =>
            key == settings.leftKey ||
            key == settings.rightKey ||
            key == settings.squatKey,
      )
      ..addAll(
        keysPressed.where(
          (key) =>
              key == settings.leftKey ||
              key == settings.rightKey ||
              key == settings.squatKey,
        ),
      );
    if (event is KeyDownEvent) {
      if (event.logicalKey == settings.leftKey) {
        _keysPressed.add(event.logicalKey);
        _updateMovementDirection();
      } else if (event.logicalKey == settings.rightKey) {
        _keysPressed.add(event.logicalKey);
        _updateMovementDirection();
      } else if (event.logicalKey == settings.jumpKey)
        jump();
      else if (event.logicalKey == settings.attackKey)
        attack();
      else if (event.logicalKey == settings.squatKey) {
        _squatting = true;
        _updateAnimationState();
      } else if (event.logicalKey == settings.shieldKey)
        setShielding(true);
      else if (event.logicalKey == settings.runKey) {
        _keysPressed.add(event.logicalKey);
        setRunning(true);
      } else if (event.logicalKey == settings.chestKey)
        game.openChest();
      else if (event.logicalKey == settings.inventoryKey) {
        inventoryOpen.value = !inventoryOpen.value;
      } else if (inventoryOpen.value && event.logicalKey == settings.leftKey) {
        inventoryPage.value = (inventoryPage.value - 1).clamp(0, 99);
        _keysPressed.add(event.logicalKey);
      } else if (inventoryOpen.value && event.logicalKey == settings.rightKey) {
        inventoryPage.value = inventoryPage.value + 1;
        _keysPressed.add(event.logicalKey);
      }
      return true;
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == settings.leftKey ||
          event.logicalKey == settings.rightKey) {
        _keysPressed.remove(event.logicalKey);
        _updateMovementDirection();
      } else if (event.logicalKey == settings.shieldKey) {
        _keysPressed.remove(event.logicalKey);
        setShielding(false);
      } else if (event.logicalKey == settings.squatKey) {
        _squatting = false;
        _updateAnimationState();
      } else if (event.logicalKey == settings.runKey) {
        _keysPressed.remove(event.logicalKey);
        setRunning(false);
      }
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invincibilityTimer > 0) {
      _invincibilityTimer -= dt;
    }
    if (_hurt) {
      _hurtTimer -= dt;
      if (_hurtTimer <= 0) {
        _hurt = false;
        _updateAnimationState();
      }
      return;
    }
    if (_dead) {
      _deathAnimTimer -= dt;
      _respawnTimer -= dt;
      if (_deathAnimTimer <= 0 && _respawnTimer <= 0) {
        _respawn();
      }
      return;
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

    if (_running && isOnGround && _lastInput != 0 && stamina > 0) {
      consumeStamina(StaminaConfig.runCostPerFrame * 60 * dt);
      if (stamina <= 0) {
        _running = false;
        _applySpeed();
      }
    }
    _updateStamina(dt);

    // Shield stun logic
    if (_stunned) {
      _stunTimer -= dt;
      if (_stunTimer <= 0) {
        _stunned = false;
        _stunTimer = 0;
        current = 'idle';
      }
    } else {
      final minX = size.x / 2;
      final maxX = game.size.x - size.x / 2;
      if (position.x < minX) position.x = minX;
      if (position.x > maxX) position.x = maxX;
    }

    if (_attacking) {
      if (game.inventory.weaponType == 'bow' && !_arrowSpawned) {
        _arrowSpawnDelay -= dt;
        if (_arrowSpawnDelay <= 0) _spawnArrow();
      }
      _comboWindow -= dt;
      if (_attackHeld &&
          !_shielding &&
          game.inventory.weaponType != 'bow' &&
          _comboStep == 1 &&
          _comboWindow <= 0.08) {
        _comboStep = 2;
        _comboWindow = 0.48;
        current = 'attack2';
        _dealMeleeDamage(2);
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

  void takeDamage(double damage) {
    if (_shielding || _invincibilityTimer > 0 || _hurt || _dead) {
      if (_shielding) damageShield(damage);
      return;
    }
    _invincibilityTimer = 1.0;
    final actualDamage = (damage - defenseBonus).clamp(0, damage);
    health = (health - actualDamage).clamp(0, maxHealth);
    healthNotifier.value = health;
    if (health <= 0) {
      _dead = true;
      _deathAnimTimer = 0.8;
      _respawnTimer = 5.0;
      _attacking = false;
      current = 'death';
    } else {
      _hurt = true;
      _hurtTimer = character.hurtStepTime * character.hurtAmount;
      _attacking = false;
      current = 'hurt';
    }
  }

  void _respawn() {
    position.setValues(
      game.size.x * 0.2,
      game.size.y - game.size.y * 0.1 - size.y / 2,
    );
    health = maxHealth;
    healthNotifier.value = health;
    _invincibilityTimer = 2.0;
    _dead = false;
    _deathAnimTimer = 0;
    opacity = 1;
    // Switch to map 0 via game.update logic
    game.currentMap = 0;
    if (game.currentMap == 0) {
      game.background1.removeFromParent();
      game.add(game.background);
      game.removeAll(game.children.whereType<DoubleJumpDust>());
      game.slime.removeFromParent();
      game.boss.health = game.boss.maxHealth;
      game.boss.resetState();
      game.boss.removeFromParent();
      game.removeAll(game.children.whereType<BossMinion>());
      game.add(game.chest);
      game.add(game.fire);
    }
    current = 'idle';
  }
}

class SlimeEnemy extends SpriteAnimationComponent
    with HasGameReference<NgocRongGame>, CollisionCallbacks {
  final LocalPlayer player;
  double health = 30;
  double maxHealth = 30;
  final ValueNotifier<double> healthNotifier = ValueNotifier(30);
  bool _dead = false;
  double _deathAnimTimer = 0;
  double _respawnTimer = 0;
  double _invincibilityTimer = 0;
  double vx = 0;
  int directionX = 1;
  double vy = 0;
  double _patrolTimer = 0;
  bool _attacking = false;
  double _attackTimer = 0;
  double _attackCooldown = 0;
  bool get isDead => _dead;
  double get attackCooldown => _attackCooldown;
  static const double attackCooldownMax = 7.0;
  SpriteAnimation? _rightAnimation;
  SpriteAnimation? _leftAnimation;
  SpriteAnimation? _rightAttackAnimation;
  SpriteAnimation? _leftAttackAnimation;

  SlimeEnemy({required Vector2 position, required this.player})
    : super(
        position: position,
        size: Vector2.all(224),
        anchor: Anchor.center,
        priority: 2,
      );

  @override
  Future<void> onLoad() async {
    try {
      final walkImg = await game.images.load(
        'enemies/slime3/Slime3_Walk_with_shadow.png',
      );
      _rightAnimation = SpriteAnimation.fromFrameData(
        walkImg,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.3,
          textureSize: Vector2.all(64),
          texturePosition: Vector2(0, 192),
        ),
      );
      _leftAnimation = SpriteAnimation.fromFrameData(
        walkImg,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.3,
          textureSize: Vector2.all(64),
          texturePosition: Vector2(0, 128),
        ),
      );

      final attackImg = await game.images.load(
        'enemies/slime3/Slime3_Attack_with_shadow.png',
      );
      // 36 frames = 4 rows × 9 cols. Row 0=front, 1=back, 2=left, 3=right.
      _rightAttackAnimation = SpriteAnimation.fromFrameData(
        attackImg,
        SpriteAnimationData.sequenced(
          amount: 9,
          stepTime: 0.1,
          textureSize: Vector2.all(64),
          texturePosition: Vector2(0, 192),
          loop: false,
        ),
      );
      _leftAttackAnimation = SpriteAnimation.fromFrameData(
        attackImg,
        SpriteAnimationData.sequenced(
          amount: 9,
          stepTime: 0.1,
          textureSize: Vector2.all(64),
          texturePosition: Vector2(0, 128),
          loop: false,
        ),
      );

      animation = _rightAnimation;
    } catch (e) {
      if (kDebugMode) print('SlimeEnemy load error: $e');
    }
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _invincibilityTimer -= dt;
    if (_dead) {
      _deathAnimTimer -= dt;
      if (_deathAnimTimer <= 0) {
        _respawnTimer -= dt;
        if (_respawnTimer <= 0) {
          _dead = false;
          health = maxHealth;
          healthNotifier.value = health;
          position.setValues(
            game.size.x * 0.5,
            game.size.y - game.size.y * 0.1 - size.y / 2 + player.size.y * 0.28,
          );
          opacity = 1;
          _attacking = false;
          animation = _rightAnimation;
        }
      }
      return;
    }

    _attackCooldown = (_attackCooldown - dt).clamp(0.0, attackCooldownMax);
    if (_attacking) {
      _attackTimer -= dt;
      if (_attackTimer <= 0) {
        _attacking = false;
        animation = directionX > 0 ? _rightAnimation : _leftAnimation;
        if ((player.position - position).length <
            (size.x + player.size.x) * 0.35 * 2) {
          player.takeDamage(DamageConfig.slimeBaseDamage);
        }
      }
      return;
    }

    _patrolTimer -= dt;
    if (_patrolTimer <= 0) {
      directionX = (Random().nextBool() ? 1 : -1);
      _patrolTimer = 2.0 + Random().nextDouble() * 3.0;
    }

    // Attack if close & cooldown over
    if (_attackCooldown <= 0 &&
        (player.position - position).length <
            (size.x + player.size.x) * 0.35 * 2) {
      _attacking = true;
      _attackTimer = 0.9;
      _attackCooldown = 7.0;
      directionX = player.position.x > position.x ? 1 : -1;
      animation = directionX > 0 ? _rightAttackAnimation : _leftAttackAnimation;
      return;
    }

    animation = directionX > 0 ? _rightAnimation : _leftAnimation;
    vx = directionX * game.size.y * 0.06;

    final groundY =
        game.size.y - game.size.y * 0.1 - size.y / 2 + player.size.y * 0.28;
    vy += 65 * dt;
    position.y += vy * dt;
    if (position.y >= groundY) {
      position.y = groundY;
      vy = 0;
    }
    position.x += vx * dt;

    final minX = game.size.x * 0.40;
    final maxX = game.size.x * 0.60;
    if (position.x < minX || position.x > maxX) {
      position.x = position.x.clamp(minX, maxX);
      directionX *= -1;
      _patrolTimer = 2.0;
    }
  }

  void takeDamage(double damage) {
    if (_dead) return;
    health = (health - damage).clamp(0, maxHealth);
    healthNotifier.value = health;
    if (health <= 0) {
      _dead = true;
      _respawnTimer = 5;
      opacity = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Health bar
    if (!isDead && health < maxHealth) {
      final barWidth = size.x * 0.45;
      final barHeight = size.y * 0.03;
      final barY = size.y * 0.04;
      final barX = size.x * 0.48;
      final bgRect = Rect.fromLTWH(
        barX - barWidth / 2,
        barY,
        barWidth,
        barHeight,
      );
      canvas.drawRect(bgRect, Paint()..color = const Color(0xAA000000));
      canvas.drawRect(
        Rect.fromLTWH(
          barX - barWidth / 2,
          barY,
          barWidth * (health / maxHealth),
          barHeight,
        ),
        Paint()..color = Colors.red,
      );
    }
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
  late SpriteComponent background2;
  late SpriteComponent chest;
  late SpriteAnimationComponent fire;
  late Sprite chestOpenSprite;
  GameSettings settings = GameSettings();
  final CharacterConfig character;
  final ValueNotifier<bool> canOpenChest = ValueNotifier(false);
  final ValueNotifier<bool> chestOpenState = ValueNotifier(false);
  int currentMap = 0;
  late SlimeEnemy slime;
  late BossEnemy boss;

  final ValueNotifier<bool> isPaused = ValueNotifier(false);
  final InventoryState inventory = InventoryState();
  List<InventoryItem> itemCatalog = [];

  NgocRongGame({required this.character});

  @override
  Future<void> onLoad() async {
    itemCatalog = await ItemLoader.loadItems();
    inventory.items.addAll(itemCatalog);
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
    final forest2 = await images.load('background/forest_map2.png');
    background2 = SpriteComponent(
      sprite: Sprite(forest2),
      size: size.clone(),
      priority: -1,
    );

    final chestImg = await images.load('environment/Chest.png');
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
    chestOpenSprite = Sprite(
      chestImg,
      srcPosition: Vector2(32 * 3, 0),
      srcSize: Vector2.all(32),
    );

    final fireImg = await images.load('environment/Fire.png');
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

    slime = SlimeEnemy(position: player.position.clone(), player: player)
      ..size = Vector2.all(player.size.y * 1.35);
    slime.position.y = player.position.y + player.size.y * 0.45;

    boss = BossEnemy(
      game: this,
      player: player,
      position: Vector2(size.x * 0.55, player.position.y),
    );
  }

  void openChest() {
    if (!canOpenChest.value) return;
    chestOpenState.value = !chestOpenState.value;
    if (chestOpenState.value) {
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
    final minPlayerX = player.size.x / 2;
    final maxPlayerX = size.x - player.size.x / 2;
    if (currentMap == 0 && player.position.x >= maxPlayerX - 1) {
      currentMap = 1;
      removeAll(children.whereType<DoubleJumpDust>());
      background.removeFromParent();
      add(background1);
      chest.removeFromParent();
      fire.removeFromParent();
      add(slime);
      canOpenChest.value = false;
      player.position.x = size.x * 0.1;
    } else if (currentMap == 1 && player.position.x >= maxPlayerX - 1) {
      currentMap = 2;
      removeAll(children.whereType<DoubleJumpDust>());
      background1.removeFromParent();
      add(background2);
      slime.removeFromParent();
      add(boss);
      player.position.x = size.x * 0.1;
    } else if (currentMap == 2 && player.position.x <= minPlayerX + 1) {
      currentMap = 1;
      removeAll(children.whereType<DoubleJumpDust>());
      background2.removeFromParent();
      add(background1);
      boss.removeFromParent();
      add(slime);
      player.position.x = size.x * 0.9;
    } else if (currentMap == 1 && player.position.x <= minPlayerX + 1) {
      currentMap = 0;
      removeAll(children.whereType<DoubleJumpDust>());
      background1.removeFromParent();
      add(background);
      slime.removeFromParent();
      add(chest);
      add(fire);
      player.position.x = size.x * 0.9;
    }

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
      background2.size = size.clone();
      chest.size = Vector2.all(size.y * 0.15);
      fire.size = Vector2.all(size.y * 0.12);
      final playerSize = size.y * 0.2;
      final groundHeight = size.y * 0.1;
      player.size = Vector2.all(
        playerSize * (inventory.weaponType == 'none' ? 1 : 42 / 32),
      );
      player.position.y = size.y - groundHeight - playerSize / 2;
      final maxX = size.x - playerSize / 2;
      if (player.position.x > maxX) player.position.x = maxX;
    }
  }
}
