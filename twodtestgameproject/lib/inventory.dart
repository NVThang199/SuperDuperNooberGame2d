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
  final Set<String> equippedIds = {};
  int page;
  int selected;
  static const int slotsPerPage = 20;
  static const int maxEquippedItems = 8;

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

  int get equippedCount => equippedIds.length;

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
    if (equippedIds.length >= maxEquippedItems) return false;
    equippedIds.add(item.id);
    return true;
  }

  bool unequip(InventoryItem item) {
    return equippedIds.remove(item.id);
  }

  void clear() {
    items.clear();
    equippedIds.clear();
  }
}

class InventoryWidget extends StatefulWidget {
  final InventoryState inventory;
  final VoidCallback onClose;
  final VoidCallback onGiveAll;
  final ValueChanged<InventoryItem> onUseItem;
  final ValueChanged<InventoryItem> onUnequipItem;

  const InventoryWidget({
    super.key,
    required this.inventory,
    required this.onClose,
    required this.onGiveAll,
    required this.onUseItem,
    required this.onUnequipItem,
  });

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  static const _frameW = 448.0;
  static const _frameH = 448.0;
  static const _cols = 5;
  static const _rows = 4;
  static const _gridLeft = 68.0;
  static const _gridTop = 68.0;
  static const _gridRight = 376.0;
  static const _gridBottom = 312.0;

  static const _frames = [
    'assets/images/ui/inventory/Inventory1.png',
    'assets/images/ui/inventory/Inventory2.png',
    'assets/images/ui/inventory/Inventory3.png',
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
    _filteredInventory.equippedIds.addAll(widget.inventory.equippedIds);
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.inventory;
    return LayoutBuilder(
      builder: (context, box) {
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
              onTapUp: (d) => _onTap(d.localPosition, scale, _filteredInventory),
              child: Stack(
                children: [
                  ..._frames.map(
                    (path) => Positioned.fill(
                      child: Image.asset(
                        path,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  _highlight(_filteredInventory, scale),
                  Positioned(
                    left: 38.0 * scale,
                    top: 169.0 * scale,
                    width: 30.0 * scale,
                    height: 40.0 * scale,
                    child: IgnorePointer(
                      child: Container(color: const Color(0x00000000)),
                    ),
                  ),
                  Positioned(
                    left: 380.0 * scale,
                    top: 169.0 * scale,
                    width: 30.0 * scale,
                    height: 40.0 * scale,
                    child: IgnorePointer(
                      child: Container(color: const Color(0x00000000)),
                    ),
                  ),
                  _label('${_filteredInventory.page + 1}/${_filteredInventory.maxPages}', scale),
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
                  Positioned(
                    left: w * 0.18,
                    top: h * 0.88,
                    child: GestureDetector(
                      onTap: widget.onGiveAll,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Give All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * 0.52,
                    top: h * 0.88,
                    child: GestureDetector(
                      onTap: () {
                        widget.inventory.clear();
                        setState(() => _rebuildFilteredInventory());
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Delete All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: w * 0.25,
                    top: h * 0.02,
                    child: Text(
                      '${inv.equippedCount}/8',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: w * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: h * 0.02,
                      child: Center(
                        child: DropdownButton<String?>(
                          value: _filterRarity,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tất cả', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 'common', child: Text('Common', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 'uncommon', child: Text('Uncommon', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 'rare', child: Text('Rare', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 'epic', child: Text('Epic', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 'legendary', child: Text('Legendary', style: TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                          onChanged: (v) => setState(() {
                            _filterRarity = v;
                            _rebuildFilteredInventory();
                          }),
                          dropdownColor: Colors.grey.shade800,
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
    final x = _gridLeft * scale + col * slotW;
    final y = _gridTop * scale + row * slotH;
    final isSelected = inv.selected == idx;
    final isEquipped = inv.equippedIds.contains(item.id);

    return Positioned(
      left: x,
      top: y,
      width: slotW,
      height: slotH,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Colors.yellow
                    : (isEquipped ? Colors.green : Colors.grey),
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
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
      inv.nextPage();
      setState(() {});
      return;
    }

    // Slot tap -> show detail dialog
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
    final isEquipped = widget.inventory.equippedIds.contains(item.id);
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
          else if (widget.inventory.equippedCount <
              InventoryState.maxEquippedItems)
            TextButton(
              onPressed: () {
                widget.inventory.equip(item);
                widget.onUseItem(item);
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Trang bị'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã đủ 8 món'),
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
