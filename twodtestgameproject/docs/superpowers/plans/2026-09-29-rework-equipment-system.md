# Rework Equipment System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the equipment system from 8 generic slots to 12 specific equipment slots (2 Rings, 1 Necklace, 2 Bracers, 1 Armor, 2 Weapons/Shield, 1 Helm, 1 Boots, 1 Belt, 1 Artifact).

**Architecture:** 
- Update `InventoryItem` or create an `Equipment` enum for slot types.
- Update `InventoryState` to manage 12 specific slots instead of a generic `equippedIds` set.
- Refactor `InventoryWidget` to render the new equipment layout (paper-doll or designated slots) based on the new asset layout.

**Tech Stack:** Flutter, Dart.

**Spec:** Redesign of the existing `lib/inventory.dart` and `assets/images/ui/inventory/` UI flow.

## Global Constraints

- Dart language, Flutter framework.
- 12 specific equipment slots: 2 Rings, 1 Necklace, 2 Bracers, 1 Armor, 2 Weapons/Shields, 1 Helm, 1 Boots, 1 Belt, 1 Artifact.
- Maintain existing CSV data structure (with commas removed).

## Review Focus

1. **Dual Wielding Logic:** Ensure the system handles Weapon+Weapon vs Weapon+Shield logic.
2. **UI Layout:** Ensure the new asset (`Inventory1.png`) is correctly mapped to 12 designated slots.
3. **Data Migration:** Ensure existing save files (if any) are compatible with the new equipment structure.
4. **Equip Logic:** Ensure only one item can be equipped per specific slot type.
5. **Stats Aggregation:** Update the logic that sums stats based on the new 12-slot system.

---

### Task 1: Update Data Structure for Equipment Slots

**Files:**
- Modify: `lib/inventory.dart`

**Interfaces:**
- Produces: `enum EquipmentSlot`, updated `InventoryState` to hold equipment map `Map<EquipmentSlot, InventoryItem?>`

- [ ] **Step 1: Define `EquipmentSlot` enum and update `InventoryItem` to include slot compatibility.**
- [ ] **Step 2: Update `InventoryState` to store equipped items as `Map<EquipmentSlot, InventoryItem?>`.**
- [ ] **Step 3: Update `equip` and `unequip` logic to validate based on `EquipmentSlot`.**

### Task 2: Implement UI Layout

**Files:**
- Modify: `lib/inventory.dart`

**Interfaces:**
- Consumes: New equipment map from `InventoryState`.

- [ ] **Step 1: Update `InventoryWidget` to render 12 specific equipment slots overlay on the new `Inventory1.png`.**
- [ ] **Step 2: Refactor `_showItemDetailDialog` to reflect "Equip to [Slot]" actions based on item type.**

### Task 3: Final Verification

**Files:**
- Modify: None.

- [ ] **Step 1: Verify stat aggregation logic correctly calculates total stats.**
- [ ] **Step 2: Run application and test equipment/unequipment across all 12 slots.**
- [ ] **Step 3: Commit all changes.**
