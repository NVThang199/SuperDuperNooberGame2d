import 'dart:ui';

import 'package:flutter/material.dart';

import 'skill_config.dart';

// Kích thước chuẩn của trang sách.
const double _skill1W = 150;  // Skill1 (trái) - chiều rộng
const double _skill1H = 150;  // Skill1 (trái) - chiều cao
const double _bookW = 590;
const double _bookH = 520;

// Lưới 4x3: ô 56x56, gap 6.
const double _cell = 56;
const double _gap = 6;
const double _cellRadius = 7;
const double _cellBorder = 2.5;
const double _framePad = 12;
const double _frameRadius = 6;

const Color _beadColor = Color(0xFFE8A644); // vàng cam
const Color _frameBg = Color(0xFF15151C); // xám đen (nền trong khung ngoài)
const Color _cellBg = Color(0xFF3A3B47); // xám tím đậm
const Color _cellBgSelected = Color(0xFF4A4557);

class SkillSelectionPage extends StatefulWidget {
  const SkillSelectionPage({super.key, this.initialSkill});

  final SkillConfig? initialSkill;

  @override
  State<SkillSelectionPage> createState() => _SkillSelectionPageState();
}

class _SkillSelectionPageState extends State<SkillSelectionPage> {
  late SkillConfig _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSkill ?? SkillConfig.allSkills.first;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: _SkillBook(
          selected: _selected,
          onSelect: (s) => setState(() => _selected = s),
          onConfirm: () => Navigator.pop(context, _selected),
        ),
      ),
    );
  }
}

class _SkillBook extends StatefulWidget {
  const _SkillBook({
    required this.selected,
    required this.onSelect,
    required this.onConfirm,
  });

  final SkillConfig selected;
  final ValueChanged<SkillConfig> onSelect;
  final VoidCallback onConfirm;

  @override
  State<_SkillBook> createState() => _SkillBookState();
}

class _SkillBookState extends State<_SkillBook> {
  int _currentPage = 0; // Trang hiện tại (0 = skills 0-11, 1 = skills 12-23, ...)

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _bookW,
      height: _bookH,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/skill_select/UIBook.png'),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                // Trái: Skill1.png + 2 dòng text bên dưới.
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: _skill1W,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Image.asset(
                              'assets/images/skill_select/Skill1.png',
                              width: _skill1W,
                              height: _skill1H,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Vùng text cố định chiều cao: text ngắn/dài
                          // không đẩy ảnh Skill1 nhảy nữa.
                          SizedBox(
                            height: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.selected.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: Text(
                                    widget.selected.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Phải: lưới 2×3.
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, top: 40),
                      child: _grid(widget.selected, widget.onSelect, _currentPage),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 0),
            // Nút lướt trái phải - vị trí tùy chỉnh
            Padding(
              padding: const EdgeInsets.only(left: 280),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: _beadColor, size: 28),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text(
                    'Trang ${_currentPage + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: _beadColor, size: 28),
                    onPressed: (_currentPage + 1) * 12 < SkillConfig.allSkills.length
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _beadColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Xác Nhận',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(SkillConfig selected, ValueChanged<SkillConfig> onSelect, int page) {
    final frameW = _cell * 3 + _gap * 2 + _framePad * 2 + 16;
    final frameH = _cell * 4 + _gap * 3 + _framePad * 2 + 16;
    return CustomPaint(
      foregroundPainter: _BeadedBorderPainter(
        color: _beadColor,
        radius: _frameRadius,
        thickness: 3.5,
      ),
      child: Container(
        width: frameW,
        height: frameH,
        padding: const EdgeInsets.all(_framePad),
        decoration: BoxDecoration(
          color: _frameBg,
          borderRadius: BorderRadius.circular(_frameRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 4; row++) ...[
              if (row > 0) const SizedBox(height: _gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    if (col > 0) const SizedBox(width: _gap),
                    _cellWidget(
                      skill: SkillConfig.allSkills[page * 12 + row * 3 + col],
                      selected: selected,
                      onSelect: onSelect,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cellWidget({
    required SkillConfig skill,
    required SkillConfig selected,
    required ValueChanged<SkillConfig> onSelect,
  }) {
    final isSelected = skill.id == selected.id;
    return GestureDetector(
      onTap: () => onSelect(skill),
      child: Container(
        width: _cell,
        height: _cell,
        decoration: BoxDecoration(
          color: isSelected ? _cellBgSelected : _cellBg,
          border: Border.all(color: _beadColor, width: _cellBorder),
          borderRadius: BorderRadius.circular(_cellRadius),
        ),
        // Chưa có icon: chỉ vòng chọn vànggold khi được chọn.
        child: isSelected
            ? Center(
                child: Container(
                  width: _cell - 18,
                  height: _cell - 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    borderRadius: BorderRadius.circular(_cellRadius - 3),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

/// Viền vàng cam dạng "hạt" (beaded) quanh khung ngoài.
class _BeadedBorderPainter extends CustomPainter {
  _BeadedBorderPainter({
    required this.color,
    required this.radius,
    required this.thickness,
  });

  final Color color;
  final double radius;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final dot = thickness / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    // Khoảng cách giữa 2 hạt ~ đường kính hạt => viền liền nhưng vẫn lộ hạt.
    const step = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, dot, paint);
        }
        d += step;
      }
    }
  }

  @override
  bool shouldRepaint(_BeadedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      thickness != oldDelegate.thickness;
}
