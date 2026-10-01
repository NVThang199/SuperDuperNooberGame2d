import 'package:flutter/foundation.dart';

@immutable
class SkillConfig {
  final int id; // 0–11 for 4×3 grid
  final String name; // Vietnamese
  final String description;
  final String iconAssetPath; // e.g., 'assets/images/skill_icons/skill_0.png'

  const SkillConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAssetPath,
  });

  // Default 12 skills (customize names/descriptions)
  static const List<SkillConfig> allSkills = [
    SkillConfig(id: 0, name: 'Tấn Công Mạnh', description: 'Tăng 50% sát thương', iconAssetPath: 'assets/images/skill_icons/skill_0.png'),
    SkillConfig(id: 1, name: 'Khiên Bất Khả Xâm Phạm', description: 'Giảm 40% sát thương nhận', iconAssetPath: 'assets/images/skill_icons/skill_1.png'),
    SkillConfig(id: 2, name: 'Nhảy Cao', description: 'Nhảy cao thêm 30%', iconAssetPath: 'assets/images/skill_icons/skill_2.png'),
    SkillConfig(id: 3, name: 'Chạy Nhanh', description: 'Tăng tốc độ chạy 25%', iconAssetPath: 'assets/images/skill_icons/skill_3.png'),
    SkillConfig(id: 4, name: 'Phục Hồi Sức Khỏe', description: 'Hồi 20% HP mỗi 5s', iconAssetPath: 'assets/images/skill_icons/skill_4.png'),
    SkillConfig(id: 5, name: 'Đôi Mắt Rồng', description: 'Nhìn xa gấp đôi', iconAssetPath: 'assets/images/skill_icons/skill_5.png'),
    SkillConfig(id: 6, name: 'Combo Vàng', description: '+100% sát thương combo', iconAssetPath: 'assets/images/skill_icons/skill_6.png'),
    SkillConfig(id: 7, name: 'Độn Thân', description: 'Né được 1 đòn/5s', iconAssetPath: 'assets/images/skill_icons/skill_7.png'),
    SkillConfig(id: 8, name: 'Quyết Tử', description: 'Sát thương tối đa khi HP dưới 30%', iconAssetPath: 'assets/images/skill_icons/skill_8.png'),
    SkillConfig(id: 9, name: 'Kỹ Năng 9', description: 'Mô tả kỹ năng 9', iconAssetPath: 'assets/images/skill_icons/skill_9.png'),
    SkillConfig(id: 10, name: 'Kỹ Năng 10', description: 'Mô tả kỹ năng 10', iconAssetPath: 'assets/images/skill_icons/skill_10.png'),
    SkillConfig(id: 11, name: 'Kỹ Năng 11', description: 'Mô tả kỹ năng 11', iconAssetPath: 'assets/images/skill_icons/skill_11.png'),
  ];
}
