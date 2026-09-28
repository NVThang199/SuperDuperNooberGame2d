import 'package:flutter/material.dart';

class InventoryItem {
  final String name;
  int count;
  InventoryItem({required this.name, required this.count});
}

class InventoryState {
  final List<InventoryItem> items;
  int page;
  int selected;
  static const int slotsPerPage = 20; // 4 rows × 5 cols

  InventoryState({List<InventoryItem>? items, this.page = 0, this.selected = 0})
    : items = items ?? [];

  int get maxPages => (items.length / slotsPerPage).ceil().clamp(1, 999);
  List<InventoryItem> get pageItems {
    final start = page * slotsPerPage;
    final end = (start + slotsPerPage).clamp(0, items.length);
    return items.sublist(start, end);
  }

  void nextPage() {
    if (page < maxPages - 1) page++;
  }

  void prevPage() {
    if (page > 0) page--;
  }
}

class InventoryWidget extends StatefulWidget {
  final InventoryState inventory;
  final VoidCallback onClose;

  const InventoryWidget({
    super.key,
    required this.inventory,
    required this.onClose,
  });

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  // Frame: 448×448. Grid: 4 rows × 5 cols (upscaled 4×)
  static const _frameW = 448.0;
  static const _frameH = 448.0;
  static const _cols = 5;
  static const _rows = 4;
  // Grid pixels: 4× scaled (17,17)-(94,78) -> (68,68)-(376,312)
  static const _gridLeft = 68.0;
  static const _gridTop = 68.0;
  static const _gridRight = 376.0;
  static const _gridBottom = 312.0;

  static const _frames = [
    'assets/images/ui/inventory/Inventory1.png',
    'assets/images/ui/inventory/Inventory2.png',
    'assets/images/ui/inventory/Inventory3.png',
  ];

  Offset? _lastTapLocal;
  double? _lastScale;

  @override
  Widget build(BuildContext context) {
    final inv = widget.inventory;
    return LayoutBuilder(
      builder: (context, box) {
        // Scale to fill ~80% height, keep 448:448 aspect
        final h = box.maxHeight * 0.80;
        final w = h * (_frameW / _frameH);
        final scale = h / _frameH;

        return Align(
          alignment: const FractionalOffset(0.5, 0.6),
          child: SizedBox(
            width: w,
            height: h,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTap(d.localPosition, scale, inv),
              child: Stack(
                children: [
                  // 4 frame layers
                  ..._frames.map(
                    (path) => Positioned.fill(
                      child: Image.asset(
                        path,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  // Slot highlight (amber border on selected)
                  _highlight(inv, scale),
                  // Debug: arrow hitbox rectangles (invisible, ontap only)
                  Positioned(
                    left: 38.0 * scale,
                    top: 169.0 * scale,
                    width: 30.0 * scale,
                    height: 40.0 * scale,
                    child: IgnorePointer(
                      child: Container(
                        color: const Color(0x00000000),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 380.0 * scale,
                    top: 169.0 * scale,
                    width: 30.0 * scale,
                    height: 40.0 * scale,
                    child: IgnorePointer(
                      child: Container(
                        color: const Color(0x00000000),
                      ),
                    ),
                  ),
                  // Page label
                  _label('${inv.page + 1}/${inv.maxPages}', scale),
                  // Close button
                  Positioned(
                    right: w * 0.09,
                    top: h * 0.02,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: w * 0.08,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _highlight(InventoryState inv, double scale) {
    if (inv.pageItems.isEmpty) return const SizedBox.shrink();
    final i = inv.selected.clamp(0, inv.pageItems.length - 1);
    final col = i % _cols;
    final row = i ~/ _cols;

    final slotW = ((_gridRight - _gridLeft) / _cols) * scale;
    final slotH = ((_gridBottom - _gridTop) / _rows) * scale;
    final x = _gridLeft * scale + col * slotW;
    final y = _gridTop * scale + row * slotH;

    return Positioned(
      left: x,
      top: y,
      width: slotW,
      height: slotH,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.yellow, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, double scale) {
    final labelX = _gridLeft * scale;
    final labelY = (_gridBottom + 6) * scale;
    return Positioned(
      left: labelX,
      top: labelY,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _onTap(Offset local, double scale, InventoryState inv) {
    setState(() {
      _lastTapLocal = local;
      _lastScale = scale;
    });
    print('Inventory tap: local=$local, scale=$scale');

    final gridLeft = _gridLeft * scale;
    final gridTop = _gridTop * scale;
    final gridW = (_gridRight - _gridLeft) * scale;
    final gridH = (_gridBottom - _gridTop) * scale;

    // Left arrow: (38, 169) on 448×448 frame, 30×40 px
    final leftArrowX = 38.0 * scale;
    final leftArrowY = 169.0 * scale;
    final leftArrowW = 30.0 * scale;
    final leftArrowH = 40.0 * scale;

    // Right arrow: (380, 169) on 448×448 frame, 30×40 px
    final rightArrowX = 380.0 * scale;
    final rightArrowY = 169.0 * scale;
    final rightArrowW = 30.0 * scale;
    final rightArrowH = 40.0 * scale;

    if (local.dx >= leftArrowX &&
        local.dx < leftArrowX + leftArrowW &&
        local.dy >= leftArrowY &&
        local.dy < leftArrowY + leftArrowH) {
      inv.prevPage();
      setState(() {});
      return;
    }

    if (local.dx >= rightArrowX &&
        local.dx < rightArrowX + rightArrowW &&
        local.dy >= rightArrowY &&
        local.dy < rightArrowY + rightArrowH) {
      print('Right arrow hit! Current page: ${inv.page}, max: ${inv.maxPages}');
      inv.nextPage();
      setState(() {});
      return;
    }

    // Slot tap
    if (local.dx >= gridLeft &&
        local.dx < gridLeft + gridW &&
        local.dy >= gridTop &&
        local.dy < gridTop + gridH) {
      final col = ((local.dx - gridLeft) / (gridW / _cols)).floor().clamp(
        0,
        _cols - 1,
      );
      final row = ((local.dy - gridTop) / (gridH / _rows)).floor().clamp(
        0,
        _rows - 1,
      );
      final slotIdx = row * _cols + col;
      if (slotIdx < inv.pageItems.length) {
        setState(() => inv.selected = slotIdx);
      }
    }
  }
}
