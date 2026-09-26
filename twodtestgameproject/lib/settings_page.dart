import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'overlay_editor.dart';

class SettingsPage extends StatefulWidget {
  final GameSettings settings;
  final VoidCallback onChanged;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late GameSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  void _set(
    LogicalKeyboardKey Function(GameSettings) read,
    void Function(LogicalKeyboardKey) write,
  ) async {
    final key = await showDialog<LogicalKeyboardKey>(
      context: context,
      builder: (_) => _KeyCaptureDialog(current: read(_s)),
    );
    if (key != null) {
      setState(() => write(key));
      widget.onChanged();
    }
  }

  String _name(LogicalKeyboardKey key) =>
      key.keyLabel.isNotEmpty ? key.keyLabel : (key.debugName ?? 'Key');

  @override
  Widget build(BuildContext context) {
    final bindings = <String, List<dynamic>>{
      'Di chuyển trái': [_s.leftKey, (LogicalKeyboardKey k) => _s.leftKey = k],
      'Di chuyển phải': [
        _s.rightKey,
        (LogicalKeyboardKey k) => _s.rightKey = k,
      ],
      'Nhảy': [_s.jumpKey, (LogicalKeyboardKey k) => _s.jumpKey = k],
      'Tấn công': [_s.attackKey, (LogicalKeyboardKey k) => _s.attackKey = k],
      'Ném đá': [_s.throwKey, (LogicalKeyboardKey k) => _s.throwKey = k],
      'Khiên': [_s.shieldKey, (LogicalKeyboardKey k) => _s.shieldKey = k],
      'Chạy': [_s.runKey, (LogicalKeyboardKey k) => _s.runKey = k],
      'Mở rương': [_s.chestKey, (LogicalKeyboardKey k) => _s.chestKey = k],
    };

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CÀI ĐẶT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final entry in bindings.entries)
                  ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _set(
                        (_) => entry.value[0] as LogicalKeyboardKey,
                        entry.value[1] as void Function(LogicalKeyboardKey),
                      ),
                      child: Text(_name(entry.value[0] as LogicalKeyboardKey)),
                    ),
                  ),
                ListTile(
                  title: const Text(
                    'Tùy chỉnh vị trí nút',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OverlayEditorPage(),
                        ),
                      );
                      if (changed == true && context.mounted)
                        widget.onChanged();
                    },
                    child: const Text('MỞ'),
                  ),
                ),
                SwitchListTile(
                  title: const Text(
                    'Hiện điều khiển cảm ứng',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _s.showMobileControls,
                  onChanged: (value) {
                    setState(() => _s.showMobileControls = value);
                    widget.onChanged();
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Điều khiển bằng chuột',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Di chuyển theo con trỏ, click để tấn công',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _s.mouseControl,
                  onChanged: (value) {
                    setState(() => _s.mouseControl = value);
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _KeyCaptureDialog extends StatefulWidget {
  final LogicalKeyboardKey current;
  const _KeyCaptureDialog({required this.current});

  @override
  State<_KeyCaptureDialog> createState() => _KeyCaptureDialogState();
}

class _KeyCaptureDialogState extends State<_KeyCaptureDialog> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhấn phím muốn gán'),
      content: KeyboardListener(
        focusNode: _focus,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) Navigator.pop(context, event.logicalKey);
        },
        child: Text('Hiện tại: ${widget.current.keyLabel}'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
