import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game.dart';

class ShieldBadge extends PositionComponent with HasGameReference<NgocRongGame> {
  final LocalPlayer player;
  late final SpriteComponent _shieldIcon;
  late final Sprite _fullShield;
  late final Sprite _brokenShield;

  ShieldBadge({required this.player}) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await game.images.load('action/shieldfull.png');
    await game.images.load('action/shieldbroken.png');

    _fullShield = Sprite(game.images.fromCache('action/shieldfull.png'));
    _brokenShield = Sprite(game.images.fromCache('action/shieldbroken.png'));

    final iconSize = player.size.x * 0.45;

    // Shield icon (full or broken)
    _shieldIcon = SpriteComponent(
      sprite: _fullShield,
      size: Vector2.all(iconSize),
      anchor: Anchor.center,
    );
    add(_shieldIcon);

    // Hide badge until player starts shielding
    _shieldIcon.opacity = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.setValues(
      player.position.x,
      player.position.y - player.size.y * 0.5,
    );
    scale = Vector2.all(1);

    final show = player.isShielding ? 1.0 : 0.0;
    _shieldIcon.opacity = show;

    final isBroken = player.isShieldBroken || player.stamina <= 0;
    _shieldIcon.sprite = isBroken ? _brokenShield : _fullShield;
    final iconSize = player.size.x * (isBroken ? 0.4 : 0.45);
    _shieldIcon.size = Vector2.all(iconSize);
  }
}