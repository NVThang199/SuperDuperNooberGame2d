import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;

/// Parallax layer: image + parallax factor.
/// Factor 0.2 = layer move 20% camera movement (xa, chậm).
/// Factor 0.9 = layer move 90% camera movement (gần, nhanh).
class ParallaxLayer {
  final List<SpriteComponent> tiles; // 3 copies tiling
  final double parallaxFactor;
  final double tileWidth;
  final double baseX;
  
  /// Accumulate camera delta để smooth parallax
  double _accumulatedDelta = 0;

  ParallaxLayer({
    required this.tiles,
    required this.parallaxFactor,
    required this.tileWidth,
    required this.baseX,
  });

  /// Update layer position dựa camera delta.
  /// Camera sang phải → nền di trái.
  void update(double cameraDeltaX) {
    _accumulatedDelta -= cameraDeltaX * parallaxFactor;
    
    // Proper modulo: result always positive [0, tileWidth)
    var wrappedDelta = _accumulatedDelta % tileWidth;
    if (wrappedDelta < 0) wrappedDelta += tileWidth;
    
    for (int i = 0; i < tiles.length; i++) {
      tiles[i].position.x = baseX + wrappedDelta + (i - 1) * tileWidth;
    }
  }

  /// Reset layer về base position (khi switch map)
  void reset() {
    _accumulatedDelta = 0;
    for (int i = 0; i < tiles.length; i++) {
      tiles[i].position.x = baseX + (i - 1) * tileWidth;
    }
  }
}

/// Parallax manager: quản lý 5 layers NightForest (bỏ 5.png).
/// Dựa trên camera movement, không independent.
class ParallaxManager {
  late List<ParallaxLayer> layers = [];
  double mapWidth;
  double gameHeight;
  double gameWidth;

  ParallaxManager(this.gameWidth, this.gameHeight, this.mapWidth);

  /// Tạo 5 layers từ map3 assets (bỏ 5.png khói). Mỗi layer gồm 3 tiles tiling.
  /// Layer 0–3 (1.png–4.png), Layer 4 (6.png) = gần nhất, factor 0.9.
  Future<void> initialize(Images images) async {
    final baseY = gameHeight * 0.5; // Center viewport vertically
    final factors = [0.2, 0.3, 0.45, 0.55, 0.9]; // Bỏ 0.7 (layer 5 khói)
    final fileNames = ['background/map3/1.png', 'background/map3/2.png', 'background/map3/3.png', 'background/map3/4.png', 'background/map3/6.png']; // Bỏ 5.png
    // Layer image size: 620×360 — seam khi wrap do filter
    final tileHeight = gameHeight;
    final tileWidth = gameWidth;
    final displayWidth = tileWidth + 2; // overlap 2px che khe filter giữa tile

    for (int i = 0; i < fileNames.length; i++) {
      try {
        final img = await images.load(fileNames[i]);

        final isForeground = fileNames[i].endsWith('/6.png');
        if (kDebugMode) print('[PARALLAX] ${fileNames[i]} isForeground=$isForeground');

        // Tạo 3 tiles tiling (trái, giữa, phải) — overlap 2px để che seam
        final tiles = <SpriteComponent>[];
        for (int t = 0; t < 3; t++) {
          final tile = SpriteComponent(
            sprite: Sprite(img),
            size: Vector2(displayWidth, tileHeight),
            position: Vector2(
              gameWidth / 2 + (t - 1) * tileWidth,
              isForeground ? baseY + tileHeight * 0.01 : baseY,
            ),
            anchor: Anchor.center,
            priority: -10 + i,
          );
          tile.paint.filterQuality = FilterQuality.low;
          tile.paint.isAntiAlias = false;
          tiles.add(tile);
        }
        
        // Tô màu layer theo độ xa: layer xa = tối hơn (fog effect)
        // 4.png (i=3) phải giữ nguyên độ đục, không nhìn xuyên qua.
        final opacity = i == 3 ? 1.0 : 1.0 - (i * 0.05);
        for (final tile in tiles) {
          tile.paint.colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: opacity),
            BlendMode.modulate,
          );
        }
        
        layers.add(ParallaxLayer(
          tiles: tiles,
          parallaxFactor: factors[i],
          tileWidth: tileWidth,
          baseX: gameWidth / 2,
        ));
        if (kDebugMode) print('[PARALLAX] Layer $i: opacity=$opacity');
      } catch (e) {
        if (kDebugMode) print('ParallaxLayer $i load error: $e');
      }
    }
  }

  /// Update layers dựa camera delta.
  void updateParallax(double cameraDeltaX) {
    for (final layer in layers) {
      layer.update(cameraDeltaX);
    }
    if (kDebugMode && cameraDeltaX.abs() > 0.01) {
      print('[PARALLAX] cameraDelta=$cameraDeltaX layer0.x=${layers[0].tiles[1].position.x.toStringAsFixed(1)}');
    }
  }

  /// Reset tất cả layers về base position
  void resetLayers() {
    for (final layer in layers) {
      layer.reset();
    }
  }

  /// Thêm tất cả layers vào game
  void addToGame(FlameGame game) {
    if (kDebugMode) print('[PARALLAX] Adding ${layers.length} layers to game');
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      for (final tile in layer.tiles) {
        game.add(tile);
      }
      if (kDebugMode) {
        print('[PARALLAX] Layer $i: tiles=${layer.tiles.length} priority=${layer.tiles.first.priority}');
      }
    }
  }

  /// Remove tất cả layers từ game
  void removeFromGame(FlameGame game) {
    for (final layer in layers) {
      for (final tile in layer.tiles) {
        tile.removeFromParent();
      }
    }
  }
}
