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
    final selCfg = sel == null ? null : layout.buttons[sel];
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
            children: [
              for (final id in OverlayButtonId.values)
                _buildButton(layout, id, size),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selected = id),
            onPanUpdate: (d) {
              final p = (cfg.anchor.dx * size.width + d.delta.dx) / size.width;
              final q =
                  (cfg.anchor.dy * size.height + d.delta.dy) / size.height;
              setState(
                () => _layout = layout.copyWithButton(
                  id,
                  cfg.copyWith(
                    anchor: Offset(p.clamp(0.0, 1.0), q.clamp(0.0, 1.0)),
                  ),
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
          if (isSel)
            Positioned(
              right: -30,
              top: -30,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => _layout = layout.copyWithButton(
                        id,
                        cfg.copyWith(scale: (cfg.scale - 0.1).clamp(0.5, 2.0)),
                      ),
                    ),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _layout = layout.copyWithButton(
                        id,
                        cfg.copyWith(scale: (cfg.scale + 0.1).clamp(0.5, 2.0)),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

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
