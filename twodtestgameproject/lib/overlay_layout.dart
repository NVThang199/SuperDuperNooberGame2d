import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OverlayButtonId {
  moveLeft,
  moveRight,
  shield,
  run,
  throwRock,
  attack,
  jump,
}

class OverlayButtonConfig {
  final Offset anchor;
  final double scale;
  final double opacity;
  const OverlayButtonConfig({
    required this.anchor,
    this.scale = 1.0,
    this.opacity = 0.85,
  });
  OverlayButtonConfig copyWith({
    Offset? anchor,
    double? scale,
    double? opacity,
  }) => OverlayButtonConfig(
    anchor: anchor ?? this.anchor,
    scale: scale ?? this.scale,
    opacity: opacity ?? this.opacity,
  );
  Map<String, dynamic> toJson() => {
    'x': anchor.dx,
    'y': anchor.dy,
    'scale': scale,
    'opacity': opacity,
  };
  factory OverlayButtonConfig.fromJson(Map<String, dynamic> j) =>
      OverlayButtonConfig(
        anchor: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        scale: (j['scale'] as num?)?.toDouble() ?? 1.0,
        opacity: (j['opacity'] as num?)?.toDouble() ?? 0.85,
      );
}

class OverlayLayout {
  final Map<OverlayButtonId, OverlayButtonConfig> buttons;
  const OverlayLayout(this.buttons);
  static OverlayLayout defaults() => OverlayLayout({
    OverlayButtonId.moveLeft: const OverlayButtonConfig(
      anchor: Offset(0.06, 0.86),
      scale: 0.8,
    ),
    OverlayButtonId.moveRight: const OverlayButtonConfig(
      anchor: Offset(0.17, 0.86),
      scale: 0.8,
    ),
    OverlayButtonId.shield: const OverlayButtonConfig(
      anchor: Offset(0.73, 0.70),
      scale: 0.8,
    ),
    OverlayButtonId.run: const OverlayButtonConfig(
      anchor: Offset(0.84, 0.70),
      scale: 0.8,
    ),
    OverlayButtonId.throwRock: const OverlayButtonConfig(
      anchor: Offset(0.95, 0.70),
      scale: 0.8,
    ),
    OverlayButtonId.jump: const OverlayButtonConfig(
      anchor: Offset(0.79, 0.88),
      scale: 0.8,
    ),
    OverlayButtonId.attack: const OverlayButtonConfig(
      anchor: Offset(0.91, 0.88),
      scale: 0.8,
    ),
  });
  Map<String, dynamic> toJson() => {
    for (final e in buttons.entries) e.key.name: e.value.toJson(),
  };
  factory OverlayLayout.fromJson(Map<String, dynamic> j) {
    final d = defaults();
    final m = <OverlayButtonId, OverlayButtonConfig>{};
    for (final id in OverlayButtonId.values) {
      final v = j[id.name];
      m[id] = v == null
          ? d.buttons[id]!
          : OverlayButtonConfig.fromJson(v as Map<String, dynamic>);
    }
    return OverlayLayout(m);
  }

  OverlayLayout copyWithButton(OverlayButtonId id, OverlayButtonConfig c) {
    final n = Map<OverlayButtonId, OverlayButtonConfig>.from(buttons);
    n[id] = c;
    return OverlayLayout(n);
  }
}

const _prefsKey = 'overlay_layout_v2';

Future<OverlayLayout> loadOverlayLayout() async {
  final p = await SharedPreferences.getInstance();
  final s = p.getString(_prefsKey);
  if (s == null) return OverlayLayout.defaults();
  try {
    return OverlayLayout.fromJson(jsonDecode(s) as Map<String, dynamic>);
  } catch (_) {
    return OverlayLayout.defaults();
  }
}

Future<void> saveOverlayLayout(OverlayLayout layout) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_prefsKey, jsonEncode(layout.toJson()));
}

Future<void> resetOverlayLayout() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(_prefsKey);
}
