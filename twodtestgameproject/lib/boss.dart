import 'dart:ui';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';

import 'game.dart';

class BossEnemy extends PositionComponent {
  static const double frameSize = 100;
  static const double stepTime = 0.1;
  static const double slowStepTime = 0.35;
  static const double sizeMultiplier = 2.4;
  static const double chaseSpeed = 40;
  static const double skill1FastStep = 0.1;
  static const double skill1SlowStep = 0.35;

  final NgocRongGame game;
  final LocalPlayer player;

  late SpriteAnimationComponent sprite;
  late Vector2 _initialPosition;

  double health = 200;
  double maxHealth = 200;
  bool dead = false;
  bool isInvincible = false;
  double invincibleTimer = 0;
  double attackCooldown = 0;
  double skillCooldown = 0;
  bool _aggro = false;

  static const double activationRange = 80;

  String _currentState = 'idle';
  double _currentStepTime = stepTime;
  double stateTimer = 0;
  int nextAttackFrame = 0;
  int direction = 1;
  bool _idle2Triggered = false;
  double _skill1Timer = 0;
  int _attackCount = 0;
  int _skill1Count = 0; // track skill1 uses since last summon
  bool _lowHPTriggered = false; // track first 80% HP threshold summon
  double _deathTimer = 0; // respawn timer after death animation

  BossEnemy({
    required this.game,
    required this.player,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center, priority: 1);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(frameSize * 2.2);
    _initialPosition = position.clone();
    sprite = SpriteAnimationComponent(
      anchor: Anchor.center,
      position: size / 2,
    );
    add(sprite);

    await _loadAnimation('idle');
    sprite.size = Vector2.all(frameSize * sizeMultiplier);
    position.y -= frameSize * 0.3;
    _initialPosition.y = position.y; // save final Y position after adjustment
  }

  Future<void> _loadAnimation(String state) async {
    if (dead) return;
    _currentState = state;
    stateTimer = 0;
    nextAttackFrame = 0;
    _idle2Triggered = false;
    _skill1Timer = 0;

    String file;
    int frames;
    int cols = 0;

    double useStep;
    switch (state) {
      case 'attacking':
        file = 'enemies/undead_boss/attacking.png';
        frames = 13;
        cols = 6;
        useStep = stepTime;
        break;
      case 'skill1':
        file = 'enemies/undead_boss/skill1.png';
        frames = 12;
        cols = 6;
        useStep = stepTime;
        isInvincible = true;
        invincibleTimer = 5 * skill1FastStep + 7 * skill1SlowStep;
        break;
      case 'summon':
        file = 'enemies/undead_boss/summon.png';
        frames = 5;
        cols = 4;
        useStep = slowStepTime;
        break;
      case 'idle2':
        file = 'enemies/undead_boss/idle2.png';
        frames = 8;
        cols = 4;
        useStep = stepTime;
        break;
      case 'death':
        file = 'enemies/undead_boss/death.png';
        frames = 20;
        cols = 10;
        useStep = stepTime;
        dead = true;
        break;
      default:
        file = 'enemies/undead_boss/idle.png';
        frames = 4;
        cols = 5;
        useStep = stepTime;
    }
    _currentStepTime = useStep;

    final img = await Flame.images.load(file);
    final spriteList = <Sprite>[];

    for (int i = 0; i < frames; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      spriteList.add(
        Sprite(
          img,
          srcPosition: Vector2(col * frameSize.toDouble(), row * frameSize.toDouble()),
          srcSize: Vector2.all(frameSize),
        ),
      );
    }

    if (state == 'skill1') {
      sprite.animation = SpriteAnimation.spriteList(
        spriteList,
        stepTime: skill1FastStep,
        loop: false,
      );
    } else {
      sprite.animation = SpriteAnimation.spriteList(
        spriteList,
        stepTime: useStep,
        loop: state != 'death',
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

   if (dead || game.currentMap != 2) {
      if (game.currentMap != 2 && _aggro) {
        _aggro = false;
        health = maxHealth;
        position = _initialPosition.clone();
        _loadAnimation('idle');
        _lowHPTriggered = false;
        _attackCount = 0;
        _skill1Count = 0;
        _deathTimer = 0;
      }
      if (dead) {
        _deathTimer += dt;
        if (_deathTimer >= 5.0) {
          // Respawn
          dead = false;
          health = maxHealth;
          _deathTimer = 0;
          _aggro = false;
          _lowHPTriggered = false;
          _attackCount = 0;
          _skill1Count = 0;
          _loadAnimation('idle');
        }
      }
      return;
    }

    // Walk home if player is dead (check health since _dead is private)
    if (player.health <= 0 && _aggro) {
      final distanceHome = (position - _initialPosition).length;
      if (distanceHome > 15) {
        final homeDir = (_initialPosition - position).normalized();
        position += homeDir * chaseSpeed * 1.5 * dt;
        direction = _initialPosition.x > position.x ? 1 : -1;
        scale = Vector2(direction.toDouble(), 1);
      } else {
        _aggro = false;
        health = maxHealth;
        position = _initialPosition.clone();
        _loadAnimation('idle');
        _lowHPTriggered = false;
        _attackCount = 0;
        _skill1Count = 0;
      }
      return;
    }

    stateTimer += dt;
    attackCooldown = (attackCooldown - dt).clamp(0, double.infinity);
    skillCooldown = (skillCooldown - dt).clamp(0, double.infinity);

    if (isInvincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) isInvincible = false;
    }

    direction = player.position.x > position.x ? 1 : -1;
    scale = Vector2(direction.toDouble(), 1);

    final distanceToPlayer = (player.position - position).length;
    // Wake up when player comes close, not only when damaged.
    if (!_aggro && distanceToPlayer < activationRange * 3) _aggro = true;
    // Chase player except during skill1/summon
    final canMove = _currentState != 'skill1' && _currentState != 'summon';
    if (_aggro && canMove && distanceToPlayer > activationRange) {
      position +=
          (player.position - position).normalized() * chaseSpeed * dt;
    }

    // Follow player vertically except while casting skill1/summon.
    if (_aggro && canMove) {
      position.y += (player.position.y - position.y) * 0.5 * dt;
    }

    if (_aggro && (_currentState == 'idle' || _currentState == 'idle2')) {
      final distanceToPlayer = (player.position - position).length;
      // At low HP: summon immediately if not yet triggered
      if (health < maxHealth * 0.8 && !_lowHPTriggered) {
        _loadAnimation('summon');
        skillCooldown = 12.0;
        _lowHPTriggered = true;
        _attackCount = 0;
        _skill1Count = 0;
      } else if (skillCooldown <= 0 && _attackCount >= 3) {
        // Skill1/summon: tự phát, không cần range check
        if (health < maxHealth * 0.8 && _skill1Count >= 2) {
          _loadAnimation('summon');
          skillCooldown = 12.0;
          _skill1Count = 0;
          _lowHPTriggered = false; // reset flag để lần sau lại trigger ngay tại 80%
        } else {
          _loadAnimation('skill1');
          skillCooldown = 6.0;
          _skill1Count++;
        }
        _attackCount = 0;
      } else if (attackCooldown <= 0 && _attackCount < 3 && distanceToPlayer < activationRange * 1.3) {
        // Attacking: cần trong tầm mới đánh
        _loadAnimation('attacking');
        attackCooldown = 4.5;
        _attackCount++;
      } else if (!_idle2Triggered && stateTimer > 2.5) {
        _loadAnimation('idle2');
      }
    } else if (!_aggro && _currentState != 'idle') {
      _loadAnimation('idle');
    }

    if (_currentState == 'attacking') {
      if (stateTimer > stepTime * 6 && nextAttackFrame == 0) {
        _dealAttackDamage();
        nextAttackFrame = 1;
      }
      if (stateTimer > stepTime * 12 && nextAttackFrame == 1) {
        _dealAttackDamage();
        nextAttackFrame = 2;
      }
    }

    if (_currentState == 'skill1') {
      _skill1Timer += dt;
      final frame5Time = 5 * skill1FastStep;
      if (_skill1Timer > frame5Time && nextAttackFrame == 0) {
        _dealSkillDamage();
        nextAttackFrame = 1;
      }
    }

    if (_currentState == 'summon' &&
        stateTimer > (sprite.animation?.frames.length ?? 1) * _currentStepTime &&
        nextAttackFrame == 0) {
      _dealSkillDamage();
      _summonMinions();
      nextAttackFrame = 1;
    }

    final animDuration = stateTimer;
    final maxDuration = (sprite.animation?.frames.length ?? 1) * _currentStepTime;
    if (animDuration >= maxDuration &&
        _currentState != 'idle' &&
        _currentState != 'idle2') {
      _loadAnimation('idle');
    }
  }

  void _dealAttackDamage() {
    const dmg = DamageConfig.bossAttackDamage;
    const range = 120.0;
    if ((player.position - position).length < range) {
      player.takeDamage(dmg);
      if (kDebugMode) print('Boss attacking: -$dmg HP');
    }
  }

  void _dealSkillDamage() {
    const dmg = DamageConfig.bossSkillDamage;
    const range = 120.0;
    if ((player.position - position).length < range) {
      player.takeDamage(dmg);
      if (kDebugMode) print('Boss skill1: -$dmg HP, boss invincible');
    }
  }

  void _summonMinions() {
    for (int i = 0; i < 3; i++) {
      final offsetX = (i - 1) * frameSize * 1.5;
      final minion = BossMinion(
        game: game,
        player: player,
        position: Vector2(position.x + offsetX, player.position.y),
      );
      game.add(minion);
    }
    if (kDebugMode) print('Boss summoned 3 minions');
  }

  void takeDamage(double dmg) {
    if (isInvincible) return;
    health -= dmg;
    _aggro = true;
    if (health <= 0) {
      health = 0;
      _loadAnimation('death');
    }
    if (kDebugMode) print('Boss health: $health/$maxHealth');
  }

  void resetState() {
    _aggro = false;
    _lowHPTriggered = false;
    _attackCount = 0;
    _skill1Count = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (dead) return; // Hide HP bar when dead
    const barW = 100.0, barH = 8.0;
    final barX = size.x / 2 - barW / 2;
    final barY = -size.y / 2 + 125.0;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW, barH),
      Paint()..color = const Color.fromARGB(255, 50, 50, 50),
    );
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW * (health / maxHealth), barH),
      Paint()..color = const Color.fromARGB(255, 255, 0, 0),
    );
  }
}

class BossMinion extends PositionComponent {
  static const double frameSize = 50;
  static const double stepTime = 0.1;
  static const double moveSpeed = 60;
  static const double sizeMultiplier = 2.0;

  final NgocRongGame game;
  final LocalPlayer player;

  late SpriteAnimationComponent sprite;
  double health = 20;
  double maxHealth = 20;
  bool dead = false;
  bool _appeared = false;
  double _appearTimer = 0;
  double _patrolTimer = 0;
  int _directionX = 1;

  BossMinion({
    required this.game,
    required this.player,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center, priority: 0);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(frameSize * sizeMultiplier);
    sprite = SpriteAnimationComponent(
      anchor: Anchor.center,
      position: size / 2,
    );
    add(sprite);

    final img = await Flame.images.load('enemies/undead_boss/summonAppear.png');
    final spriteList = <Sprite>[];
    for (int i = 0; i < 3; i++) {
      spriteList.add(
        Sprite(
          img,
          srcPosition: Vector2(i * frameSize, 0),
          srcSize: Vector2.all(frameSize),
        ),
      );
    }
    sprite.animation = SpriteAnimation.spriteList(
      spriteList,
      stepTime: stepTime,
      loop: false,
    );
    sprite.size = Vector2.all(frameSize * sizeMultiplier);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (dead) return;
    // Only active on map 2; preserve minion while hidden.
    if (game.currentMap != 2) {
      sprite.scale = Vector2.zero();
      return;
    }
    sprite.scale = Vector2.all(1);
    // Remove if player dead
    if (player.health <= 0) {
      removeFromParent();
      return;
    }

    if (!_appeared) {
      _appearTimer += dt;
      if (_appearTimer >= 3 * stepTime) {
        _appeared = true;
        _loadIdleAnim();
      }
      return;
    }

    _patrolTimer -= dt;
    if (_patrolTimer <= 0) {
      _directionX = (Random().nextBool() ? 1 : -1);
      _patrolTimer = 2.0 + Random().nextDouble() * 2.0;
    }
    // Keep inside map 2 arena.
    final minX = game.size.x * 0.05;
    final maxX = game.size.x * 0.95;
    if (position.x <= minX || position.x >= maxX) _directionX *= -1;
    position.x = position.x.clamp(minX, maxX);
    position.x += _directionX * moveSpeed * dt;
    // Sync Y with player only when player on ground (not jumping)
    if (player.isOnGround) {
      position.y = player.position.y;
    }

    if ((player.position - position).length < frameSize * 1.2) {
      player.takeDamage(DamageConfig.bossMinionDamage);
      if (kDebugMode) print('Minion attacked player: -5 HP');
    }
  }

  Future<void> _loadIdleAnim() async {
    final img = await Flame.images.load('enemies/undead_boss/summonIdle.png');
    final spriteList = <Sprite>[];
    for (int i = 0; i < 4; i++) {
      spriteList.add(
        Sprite(
          img,
          srcPosition: Vector2(i * frameSize, 0),
          srcSize: Vector2.all(frameSize),
        ),
      );
    }
    sprite.animation = SpriteAnimation.spriteList(
      spriteList,
      stepTime: stepTime,
      loop: true,
    );
    sprite.size = Vector2.all(frameSize * sizeMultiplier);
  }

  void takeDamage(double dmg) {
    health -= dmg;
    if (health <= 0) {
      dead = true;
      _playDeathAnim();
    }
  }

  Future<void> _playDeathAnim() async {
    final img = await Flame.images.load('enemies/undead_boss/summonDeath.png');
    final spriteList = <Sprite>[];
    for (int i = 0; i < 3; i++) {
      spriteList.add(
        Sprite(
          img,
          srcPosition: Vector2(i * frameSize, 0),
          srcSize: Vector2.all(frameSize),
        ),
      );
    }
    sprite.animation = SpriteAnimation.spriteList(
      spriteList,
      stepTime: stepTime,
      loop: false,
    );
    sprite.size = Vector2.all(frameSize * sizeMultiplier);

    await Future.delayed(const Duration(milliseconds: 300));
    removeFromParent();
  }
}
