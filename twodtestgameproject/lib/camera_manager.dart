import 'package:flame/camera.dart';
import 'package:flame/game.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;

/// Dead-zone camera: Player tại 30–70% width không move camera.
/// Chỉ khi vượt ngưỡng thì camera theo. Clamp map boundary.
class CameraManager {
  final FlameGame game;
  late double deadZoneLeft;
  late double deadZoneRight;
  late double mapWidth;
  late double mapHeight;

  /// Parallax layers: index 0 (bg xa nhất) → factor 0.2, index 5 (foreground gần) → factor 0.9
  final List<double> parallaxFactors = [0.2, 0.3, 0.45, 0.55, 0.7, 0.9];
  
  /// Camera world position (không phải screen position)
  vm.Vector2 cameraWorldPos = vm.Vector2.zero();
  
  /// Previous camera pos để track parallax delta
  final vm.Vector2 _prevCameraWorldPos = vm.Vector2.zero();

  CameraManager(this.game, this.mapWidth, this.mapHeight) {
    // Dead-zone: 30% left, 70% right của viewport
    deadZoneLeft = game.size.x * 0.3;
    deadZoneRight = game.size.x * 0.7;
    
    // Viewfinder mặc định dùng tâm viewport.
    cameraWorldPos.setValues(game.size.x / 2, game.size.y / 2);
  }

  /// Update camera position dựa Player pos (world coords).
  /// Dead-zone logic: chỉ move khi Player vượt 30–70% vùng.
  void update(vm.Vector2 playerWorldPos, double dt) {
    _prevCameraWorldPos.setFrom(cameraWorldPos);
    
    // Player screen position dựa camera hiện tại
    // screenX = 0 (left edge), screenX = screenW (right edge)
    final playerScreenX = playerWorldPos.x - cameraWorldPos.x + game.size.x / 2;
    
    // Dead-zone check
    if (playerScreenX < deadZoneLeft) {
      // Player ở bên trái dead-zone → move camera trái để player vào 30% edge
      final targetX = playerWorldPos.x - (game.size.x * 0.3 - game.size.x / 2);
      cameraWorldPos.x = _clampX(targetX);
    } else if (playerScreenX > deadZoneRight) {
      // Player ở bên phải dead-zone → move camera phải để player vào 70% edge
      final targetX = playerWorldPos.x - (game.size.x * 0.7 - game.size.x / 2);
      cameraWorldPos.x = _clampX(targetX);
    }
    // Nếu ở giữa dead-zone: camera đứng yên (không update cameraWorldPos.x)
  }

  /// Clamp camera X sao cho không vượt ra ngoài map
  double _clampX(double targetX) {
    final viewportWidth = game.size.x;
    final minX = viewportWidth / 2; // Cam không để viewport vượt qua x=0
    final maxX = mapWidth - viewportWidth / 2; // Cam không để viewport vượt qua x=mapWidth
    return targetX.clamp(minX, maxX);
  }

  /// Lấy camera delta (movement từ frame trước)
  vm.Vector2 getCameraDelta() {
    return vm.Vector2(cameraWorldPos.x - _prevCameraWorldPos.x, 0);
  }

  /// Apply camera offset đến Flame camera (viewfinder position)
  void applyToFlameCamera(CameraComponent flameCamera) {
    // Flame's viewfinder.position = world coords ở center viewport
    flameCamera.viewfinder.position = cameraWorldPos;
  }
}
