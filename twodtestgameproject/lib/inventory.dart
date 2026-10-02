import 'package:flutter/material.dart';

class InventoryItem {
  final String id;
  final String name;
  final String imagePath;
  final String rarity;
  final int hpBonus;
  final int mpBonus;
  final int staminaBonus;
  final int dmgBonus;
  final int defenseBonus;
  final String type;
  final String description;

  InventoryItem({
    required this.id,
    required this.name,
    this.imagePath = '',
    this.rarity = '',
    this.hpBonus = 0,
    this.mpBonus = 0,
    this.staminaBonus = 0,
    this.dmgBonus = 0,
    this.defenseBonus = 0,
    this.type = '',
    this.description = '',
  });
}

class InventoryState {
  final List<InventoryItem> items;
  final Map<String, String?> equippedSlots = {
    'ring1': null,
    'helm': null,
    'ring2': null,
    'weapon1': null,
    'armor': null,
    'weapon2': null,
    'belt': null,
    'boots': null,
    'artifact': null,
    'bracer1': null,
    'necklace': null,
    'cape': null,
  };
  int page;
  int selected;
  static const int slotsPerPage = 16;
  static const int maxEquippedItems = 12;

  InventoryState({List<InventoryItem>? items, this.page = 0, this.selected = 0})
    : items = items ?? [];

  static Map<String, List<String>> _slotTypeCompatibility() => {
    'ring1': ['ring'],
    'ring2': ['ring'],
    'helm': ['helm', 'light helm', 'medium helm', 'heavy helm'],
    'weapon1': ['weapon', 'shield', 'bow'],
    'armor': ['armor', 'light armor', 'medium armor', 'heavy armor'],
    'weapon2': ['weapon', 'shield', 'bow'],
    'belt': ['belt'],
    'boots': ['boots', 'light boots', 'medium boots', 'heavy boots'],
    'artifact': ['artifact'],
    'bracer1': ['bracer'],
    'necklace': ['necklace'],
    'cape': ['cape'],
  };

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

  int get equippedCount => equippedSlots.values.where((v) => v != null).length;

  String get rollWeight {
    final types = ['helm', 'armor', 'boots'].map((slot) {
      final id = equippedSlots[slot];
      if (id == null) return null;
      return items.cast<InventoryItem?>().firstWhere(
        (item) => item?.id == id,
        orElse: () => null,
      )?.type;
    }).whereType<String>();
    if (types.any((type) => type.startsWith('heavy '))) return 'heavy';
    if (types.any((type) => type.startsWith('medium '))) return 'medium';
    if (types.any((type) => type.startsWith('light '))) return 'light';
    return 'none';
  }

  double get rollSpeedMultiplier => switch (rollWeight) {
    'heavy' => 1.4,
    'medium' => 1.6,
    'light' => 1.8,
    _ => 2.0,
  };

  int get rollIframeStart => switch (rollWeight) {
    'heavy' => 5,
    'medium' => 4,
    _ => 3,
  };

  int get rollIframeEnd => switch (rollWeight) {
    'heavy' => 6,
    'medium' => 7,
    _ => 8,
  };

  double get rollCooldown => switch (rollWeight) {
    'heavy' => 2.6,
    'medium' => 2.1,
    'light' => 1.5,
    _ => 1.1,
  };

  double get rollStaminaCost => switch (rollWeight) {
    'heavy' => 30.0,
    'medium' => 25.0,
    'light' => 20.0,
    _ => 15.0,
  };

  List<InventoryItem> search(String query, [List<InventoryItem>? items]) {
    final searchItems = items ?? this.items;
    final q = query.toLowerCase();
    return searchItems.where((item) => 
      item.name.toLowerCase().contains(q) || 
      item.description.toLowerCase().contains(q)
    ).toList();
  }

  List<InventoryItem> filter({String? rarity, String? type}) {
    return items.where((item) {
      if (rarity != null && item.rarity != rarity) return false;
      if (type != null && item.type != type) return false;
      return true;
    }).toList();
  }

  bool equip(InventoryItem item) {
    if (equippedSlots.containsValue(item.id)) return true;
    if (item.type == 'weapon' || item.type == 'bow') {
      equippedSlots['weapon1'] = null;
      equippedSlots['weapon2'] = null;
      equippedSlots['weapon1'] = item.id;
      return true;
    }
    if (item.type == 'shield') {
      for (final slot in ['weapon1', 'weapon2']) {
        if (equippedSlots[slot] == null) {
          equippedSlots[slot] = item.id;
          return true;
        }
      }
    }

    final compatibleSlots = _slotTypeCompatibility().entries
      .where((entry) => entry.value.contains(item.type))
      .map((entry) => entry.key)
      .toList();

    for (final slot in compatibleSlots) {
      if (equippedSlots[slot] == null) {
        equippedSlots[slot] = item.id;
        return true;
      }
    }
    return false;
  }

  bool unequip(InventoryItem item) {
    for (final entry in equippedSlots.entries) {
      if (entry.value == item.id) {
        equippedSlots[entry.key] = null;
        return true;
      }
    }
    return false;
  }

  String get weaponType {
    final weapon1Id = equippedSlots['weapon1'];
    final weapon2Id = equippedSlots['weapon2'];

    if (weapon1Id != null) {
      final item = items.firstWhere(
        (i) => i.id == weapon1Id,
        orElse: () => InventoryItem(id: '', name: '', type: ''),
      );
      if (item.type == 'weapon') return 'sword';
      if (item.type == 'bow') return 'bow';
    }
    if (weapon2Id != null) {
      final item = items.firstWhere(
        (i) => i.id == weapon2Id,
        orElse: () => InventoryItem(id: '', name: '', type: ''),
      );
      if (item.type == 'weapon') return 'sword';
      if (item.type == 'bow') return 'bow';
    }
    return 'none';
  }
}

class InventoryWidget extends StatefulWidget {
  final InventoryState inventory;
  final VoidCallback onClose;
  final VoidCallback onGiveAll;
  final ValueChanged<InventoryItem> onUseItem;
  final ValueChanged<InventoryItem> onUnequipItem;
  final bool debugMode;

  const InventoryWidget({
    super.key,
    required this.inventory,
    required this.onClose,
    required this.onGiveAll,
    required this.onUseItem,
    required this.onUnequipItem,
    this.debugMode = false,
  });

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  static const _frameW = 147.0;
  static const _frameH = 84.0;
  static const _cols = 4;
  static const _rows = 4;
  static const _gridLeft = 74.0;
  static const _gridTop = 19.0;
  static const _gridRight = _gridLeft + 3.9 * 13;
  static const _gridBottom = _gridTop + 4 * 13;

  static const _eqLeft = 17.0;
  static const _eqRight = _eqLeft + 2.9 * 12.5;
  static const _eqTop = 19.0;
  static const _eqBottom = _eqTop + 4.05 * 12.5;
  static const _eqCols = 3;
  static const _eqRows = 4;

  static const _frames = [
    'assets/images/ui/inventory/Inventory1.png',
    'assets/images/ui/inventory/Inventory2.png',
  ];

  static final _eqSlotOrder = [
    'ring1', 'helm', 'ring2',
    'weapon1', 'armor', 'weapon2',
    'belt', 'boots', 'artifact',
    'bracer1', 'necklace', 'cape',
  ];

  String? _filterRarity;

  late InventoryState _filteredInventory;

  @override
  void initState() {
    super.initState();
    _rebuildFilteredInventory();
  }

  void _rebuildFilteredInventory() {
    var items = widget.inventory.items;
    if (_filterRarity != null) {
      items = widget.inventory.filter(rarity: _filterRarity);
    }
    _filteredInventory = InventoryState(items: items, page: 0, selected: 0);
    _filteredInventory.equippedSlots
      ..clear()
      ..addAll(widget.inventory.equippedSlots);
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.inventory;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight * 0.8;
        final w = h * (_frameW / _frameH);
        final scale = h / _frameH;

        return Align(
          alignment: const FractionalOffset(0.5, 0.6),
          child: SizedBox(
            width: w,
            height: h,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTap(d.localPosition, scale, _filteredInventory),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Transform.scale(
                        scale: 3.5,
                        child: Image.asset(
                          _frames[0],
                          filterQuality: FilterQuality.none,
                          fit: BoxFit.none,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * 0.4 - 4,
                    top: 40,
                    width: w * 0.6,
                    height: h,
                    child: Transform.scale(
                      scale: 0.72,
                      child: Image.asset(
                        _frames[1],
                        fit: BoxFit.none,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  _equipmentSlots(inv, scale),
                  _highlight(_filteredInventory, scale),
                  _label('${_filteredInventory.page + 1}/${_filteredInventory.maxPages}', scale                  ),
                  Positioned(
                  left: 68 * scale,
                  top: 43 * scale,
                  child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _filteredInventory.page > 0
                  ? () => setState(() => _filteredInventory.prevPage())
                  : null,
                  child: Container(
                    width: 4 * scale,
                    height: 6 * scale,
                    decoration: BoxDecoration(
                      border: widget.debugMode ? Border.all(color: Colors.red) : null,
                    ),
                  ),
                  ),
                  ),
                  Positioned(
                  left: 130 * scale,
                  top: 43 * scale,
                    child: GestureDetector(
                    onTap: _filteredInventory.page < _filteredInventory.maxPages - 1
                      ? () => setState(() => _filteredInventory.nextPage())
                      : null,
                  child: Container(
                    width: 4 * scale,
                    height: 6 * scale,
                    decoration: BoxDecoration(
                      border: widget.debugMode ? Border.all(color: Colors.red) : null,
                    ),
                  ),
                  ),
                  ),
                  Positioned(
                    right: w * 0.05,
                    top: h * 0.03,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onClose,
                      child: Container(
                         width: w * 0.08,
                         height: w * 0.08,
                         decoration: BoxDecoration(
                           border: widget.debugMode ? Border.all(color: Colors.red) : null,
                         ),
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

  Widget _equipmentSlots(InventoryState inv, double scale) {
    final slotW = ((_eqRight - _eqLeft) / _eqCols) * scale;
    final slotH = ((_eqBottom - _eqTop) / _eqRows) * scale;

    return Stack(
      children: [
        for (int i = 0; i < _eqSlotOrder.length; i++)
          _eqSlot(inv, i, scale, slotW, slotH),
      ],
    );
  }

  Widget _eqSlot(InventoryState inv, int idx, double scale, double slotW, double slotH) {
    final col = idx % _eqCols;
    final row = idx ~/ _eqCols;
    final x = _eqLeft * scale + col * (slotW + 2.0 * scale);
    final y = _eqTop * scale + row * (slotH + 2.0 * scale);
    final slotId = _eqSlotOrder[idx];
    final itemId = inv.equippedSlots[slotId];
    final item = itemId == null ? null : inv.items.firstWhere(
      (it) => it.id == itemId,
      orElse: () => InventoryItem(id: '', name: '', type: ''),
    );

    return Positioned(
      left: x,
      top: y,
      width: slotW,
      height: slotH,
      child: GestureDetector(
        onTap: item != null && item.id.isNotEmpty
          ? () => _showItemDetailDialog(item)
          : null,
        child: Container(
          decoration: BoxDecoration(
            border: widget.debugMode ? Border.all(color: Colors.red) : null,
            color: Colors.transparent,
          ),
          child: item != null && item.imagePath.isNotEmpty
            ? Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey),
              )
            : SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _highlight(InventoryState inv, double scale) {
    if (inv.pageItems.isEmpty) return const SizedBox.shrink();

    final slotW = ((_gridRight - _gridLeft) / _cols) * scale;
    final slotH = ((_gridBottom - _gridTop) / _rows) * scale;

    return Stack(
      children: [
        for (int i = 0; i < inv.pageItems.length; i++)
          _slot(inv.pageItems[i], i, inv, scale, slotW, slotH),
      ],
    );
  }

  Widget _slot(
    InventoryItem item,
    int idx,
    InventoryState inv,
    double scale,
    double slotW,
    double slotH,
  ) {
    final col = idx % _cols;
    final row = idx ~/ _cols;
    final x = _gridLeft * scale + col * (slotW + 1.5 * scale);
    final y = _gridTop * scale + row * (slotH + 1.5 * scale);
    final isEquipped = inv.equippedSlots.containsValue(item.id);

    return Positioned(
      left: x,
      top: y,
      width: slotW,
      height: slotH,
      child: Container(
        decoration: BoxDecoration(
          border: widget.debugMode ? Border.all(color: Colors.red) : null,
        ),
        child: Stack(
          children: [
          if (item.imagePath.isNotEmpty)
            Image.asset(
              item.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey),
            ),
          if (isEquipped)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: slotW * 0.25,
                height: slotH * 0.25,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: slotW * 0.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, double scale) {
    return Positioned(
      right: 8 * scale,
      bottom: 2 * scale,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: scale * 5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _onTap(Offset local, double scale, InventoryState inv) {
    final gridLeft = _gridLeft * scale;
    final gridTop = _gridTop * scale;
    final gridW = (_gridRight - _gridLeft) * scale;
    final gridH = (_gridBottom - _gridTop) * scale;

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
        final item = inv.pageItems[slotIdx];
        setState(() => inv.selected = slotIdx);
        _showItemDetailDialog(item);
      }
    }
  }

  void _showItemDetailDialog(InventoryItem item) {
    final isEquipped = widget.inventory.equippedSlots.containsValue(item.id);
    String? slotInfo;
    if (isEquipped) {
      final slot = widget.inventory.equippedSlots.entries
        .firstWhere((e) => e.value == item.id, orElse: () => const MapEntry('', null))
        .key;
      slotInfo = 'Đang trang bị ở: $slot';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imagePath.isNotEmpty)
                Image.asset(item.imagePath, width: 64, height: 64),
              const SizedBox(height: 12),
              if (slotInfo != null) ...[
                Text(slotInfo, style: TextStyle(color: Colors.green.shade400)),
                const SizedBox(height: 4),
              ],
              Text('Loại: ${item.type}'),
              Text('Độ hiếm: ${item.rarity}'),
              const Divider(),
              Text('HP: +${item.hpBonus}'),
              Text('MP: +${item.mpBonus}'),
              Text('Stamina: +${item.staminaBonus}'),
              Text('Sát thương: +${item.dmgBonus}'),
              Text('Phòng thủ: +${item.defenseBonus}'),
              if (item.description.isNotEmpty) ...[
                const Divider(),
                Text(item.description),
              ],
            ],
          ),
        ),
        actions: [
          if (isEquipped)
            TextButton(
              onPressed: () {
                widget.inventory.unequip(item);
                widget.onUnequipItem(item);
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Tháo'),
            )
          else if (widget.inventory.equippedCount < InventoryState.maxEquippedItems)
            TextButton(
              onPressed: () {
                final success = widget.inventory.equip(item);
                if (success) {
                  widget.onUseItem(item);
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Trang bị'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hết chỗ'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
