import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game.dart';

class ShieldBadge extends PositionComponent with HasGameReference<NgocRongGame> {
  final LocalPlayer player;
  late final SpriteComponent _shieldIcon;
  late final Sprite _fullShield;
  late final Sprite _brokenShield;
  late final TextComponent _text;

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

// Shield value text (black, centered inside the icon, slightly lower)
    _text = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(0, iconSize * 0.25),
    );
    _text.paint = Paint()..color = const Color(0xFF000000);
    add(_text);

    // Hide badge until player starts shielding
    _shieldIcon.opacity = 0;
    _text.opacity = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.setValues(
      player.position.x,
      player.position.y - player.size.y * 0.6,
    );
    scale = Vector2.all(1);

    // Show badge only while shielding
    final show = player.isShielding ? 1.0 : 0.0;
    _shieldIcon.opacity = show;
    _text.opacity = show;

    // Update shield value text
    final shieldValue = player.shield.toInt();
    _text.text = shieldValue.toString();

    // Switch icon sprite based on shield value
    _shieldIcon.sprite = player.shield <= 0 ? _brokenShield : _fullShield;
  }
}