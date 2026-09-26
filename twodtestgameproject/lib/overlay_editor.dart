import 'package:flutter/material.dart';

import 'overlay_layout.dart';

class OverlayEditorPage extends StatefulWidget {
  const OverlayEditorPage({super.key});
  @override
  State<OverlayEditorPage> createState() => _OverlayEditorPageState();
}

class _OverlayEditorPageState extends State<OverlayEditorPage> {
  OverlayLayout? _layout;
  OverlayButtonId? _selected;
  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadOverlayLayout().then((l) {
      if (mounted) setState(() => _layout = l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    if (layout == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final sel = _selected;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tùy chỉnh nút'),
        actions: [
          IconButton(
            tooltip: 'Đặt lại',
            onPressed: () async {
              await resetOverlayLayout();
              if (mounted) setState(() => _layout = OverlayLayout.defaults());
            },
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: 'Lưu',
            onPressed: () async {
              await saveOverlayLayout(layout);
              if (context.mounted) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return Stack(
            key: _stackKey,
            children: [
              for (final id in OverlayButtonId.values)
                _buildButton(layout, id, size),
              if (sel != null) _buildControls(layout, sel, size),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton(OverlayLayout layout, OverlayButtonId id, Size size) {
    final cfg = layout.buttons[id]!;
    final isSel = _selected == id;
    final w = 72 * cfg.scale;
    return Positioned(
      left: (cfg.anchor.dx * size.width - w / 2).clamp(0.0, size.width - w),
      top: (cfg.anchor.dy * size.height - w / 2).clamp(0.0, size.height - w),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selected = id),
        onPanStart: (d) => setState(() => _selected = id),
        onPanUpdate: (d) {
          final box =
              _stackKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(d.globalPosition);
          final p = (local.dx / size.width).clamp(0.0, 1.0);
          final q = (local.dy / size.height).clamp(0.0, 1.0);
          setState(
            () => _layout = layout.copyWithButton(
              id,
              cfg.copyWith(anchor: Offset(p, q)),
            ),
          );
        },
        child: Opacity(
          opacity: cfg.opacity,
          child: Transform.scale(
            scale: cfg.scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
                border: Border.all(
                  color: isSel ? Colors.yellow : Colors.white70,
                  width: isSel ? 3 : 2,
                ),
              ),
              child: Icon(_iconOf(id), color: Colors.white, size: 36),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(OverlayLayout layout, OverlayButtonId id, Size size) {
    final cfg = layout.buttons[id]!;
    final px = cfg.anchor.dx * size.width;
    final py = cfg.anchor.dy * size.height;
    const panelW = 190.0, panelH = 116.0;
    final left = px + 44 + panelW <= size.width
        ? px + 44
        : (px - 44 - panelW).clamp(8.0, size.width - panelW);
    final top = (py - panelH / 2).clamp(0.0, size.height - panelH);
    return Positioned(
      left: left.clamp(0.0, size.width - panelW).clamp(0.0, size.width),
      top: top,
      child: Container(
        width: panelW,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kích cỡ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _icBtn(
                  Icons.remove_circle,
                  Colors.red,
                  () => setState(
                    () => _layout = layout.copyWithButton(
                      id,
                      cfg.copyWith(scale: (cfg.scale - 0.1).clamp(0.5, 2.0)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(cfg.scale * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                _icBtn(
                  Icons.add_circle,
                  Colors.green,
                  () => setState(
                    () => _layout = layout.copyWithButton(
                      id,
                      cfg.copyWith(scale: (cfg.scale + 0.1).clamp(0.5, 2.0)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Độ mờ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _icBtn(
                  Icons.remove_circle,
                  Colors.red,
                  () => setState(
                    () => _layout = layout.copyWithButton(
                      id,
                      cfg.copyWith(
                        opacity: (cfg.opacity - 0.1).clamp(0.2, 1.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(cfg.opacity * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                _icBtn(
                  Icons.add_circle,
                  Colors.green,
                  () => setState(
                    () => _layout = layout.copyWithButton(
                      id,
                      cfg.copyWith(
                        opacity: (cfg.opacity + 0.1).clamp(0.2, 1.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _icBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    onPressed: onTap,
    icon: Icon(icon, color: color, size: 20),
    visualDensity: VisualDensity.compact,
  );

  static IconData _iconOf(OverlayButtonId id) => switch (id) {
    OverlayButtonId.moveLeft => Icons.keyboard_arrow_left,
    OverlayButtonId.moveRight => Icons.keyboard_arrow_right,
    OverlayButtonId.shield => Icons.shield,
    OverlayButtonId.run => Icons.directions_run,
    OverlayButtonId.throwRock => Icons.landscape,
    OverlayButtonId.attack => Icons.local_fire_department,
    OverlayButtonId.jump => Icons.keyboard_arrow_up,
  };

  static String _labelOf(OverlayButtonId id) => switch (id) {
    OverlayButtonId.moveLeft => 'TRÁI',
    OverlayButtonId.moveRight => 'PHẢI',
    OverlayButtonId.shield => 'KHIÊN',
    OverlayButtonId.run => 'CHẠY',
    OverlayButtonId.throwRock => 'NÉM ĐÁ',
    OverlayButtonId.attack => 'TẤN CÔNG',
    OverlayButtonId.jump => 'NHẢY',
  };
}
