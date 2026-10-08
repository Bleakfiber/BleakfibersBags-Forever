# Bleakfiber's Bags - Forever

[![Interface](https://img.shields.io/badge/Interface-16001%20(WoW%20Forever)-0078D7.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersBags-Forever)
[![Release](https://img.shields.io/badge/Release-v1.3.0-ffd100.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersBags-Forever/releases)
[![License](https://img.shields.io/badge/License-Source--Available-crimson.svg?style=flat-square)](LICENSE.md)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-2ea44f.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersBags-Forever)
[![Suite](https://img.shields.io/badge/Suite-Bleakfiber's%20Addon%20Suite-8a2be2.svg?style=flat-square)](https://github.com/Bleakfiber)

**Bleakfiber's Bags** is a lightweight, high-performance inventory and container management suite crafted specifically for **World of Warcraft: Forever** (Interface 16001).

Engineered to replace cluttered individual bag and bank windows with an elegant **Dark Slate & Gold** container interface, it combines memory-efficient pooled item buttons with intelligent dynamic categorization, real-time search filtering, one-click stack sorting, offline bank caching with multi-alt stock tooltips, merchant automation, and seamless integration with the **Bleakfiber Addon Suite**.

Runs **100% standalone out of the box** with zero required external dependencies or mandatory addons.

---

## 📑 Table of Contents

- [Key Highlights](#-key-highlights)
- [Feature Showcase](#-feature-showcase)
  - [1. Intelligent Categorization Engine](#1-intelligent-categorization-engine)
  - [2. Dual View Modes (Grid vs Categorized)](#2-dual-view-modes-grid-vs-categorized)
  - [3. Unified Bank & Vault Frame](#3-unified-bank--vault-frame)
  - [4. Quick Deposit & Stacking Actions](#4-quick-deposit--stacking-actions)
  - [5. Offline Bank Caching & Alt Tooltips](#5-offline-bank-caching--alt-tooltips)
  - [6. Inventory Compactor & Sorter](#6-inventory-compactor--sorter)
  - [7. Real-Time Search Filtering](#7-real-time-search-filtering)
  - [8. Item Quality Glow & Status Overlays](#8-item-quality-glow--status-overlays)
  - [9. Merchant Automation (Auto-Sell & Repair)](#9-merchant-automation-auto-sell--repair)
  - [10. Equipped Bags Drawer](#10-equipped-bags-drawer)
  - [11. Free Space & Currency Tracking](#11-free-space--currency-tracking)
  - [12. Mover Coordination & Suite Integration](#12-mover-coordination--suite-integration)
  - [13. Native Configuration GUI & Profiles](#13-native-configuration-gui--profiles)
- [Slash Commands](#-slash-commands)
- [Installation Guide](#-installation-guide)
- [License & Support](#-license--support)

---

## 🌟 Key Highlights

* **Unified Bags & Bank**: Replaces fragmented default bag and bank frames with matching Dark Slate & Gold container windows that open side-by-side cleanly.
* **Intelligent Categorization**: Automatically groups items into logical collapsible sections: *Quest Items*, *Gear*, *Consumables*, *Trade Goods*, *Recipes*, *Miscellaneous*, and *Junk*.
* **Dual View Modes**: Switch seamlessly between the classic All-in-One Grid and Intelligent Categorized sections with a single click.
* **Quick Reagent Transfer**: One-click "Deposit Trade Goods" and "Stack to Bank" buttons transfer reagents and merge incomplete stacks instantly.
* **Offline Bank Caching**: Browse your bank contents from anywhere in the world (`/bfb bank`), with multi-character item counts shown on item tooltips.
* **One-Click Bag Compactor & Sorter**: Consolidates partial item stacks and sorts inventory items by category, quality, item level, and name without lag spikes.
* **Instant Keystroke Search**: Dims non-matching items in real time as you type, making locating target items instantaneous.
* **Merchant Automation**: Automatically sells vendor junk and repairs equipment upon opening a merchant window (with Shift-key safety bypass).
* **Master Mover Support**: Drag-and-drop repositioning with independent coordinates for Bags and Bank, unified via `/bfb mover` or `/bac mover`.
* **Zero Overhead**: Fully pooled frame architecture ensures zero garbage generation during routine bag opening and inventory scans.

---

## 🎯 Feature Showcase

### 1. Intelligent Categorization Engine
Items are automatically classified and organized under sleek Dark Slate & Gold header bars:
- **Quest Items**: Active quest items, starters, and keys.
- **Equipment & Gear**: Weapons, armor, rings, trinkets, shields, and off-hands.
- **Consumables**: Food, drink, potions, elixirs, bandages, and scrolls.
- **Trade Goods & Crafting**: Crafting reagents, cloth, ore, herbs, leather, and gems.
- **Recipes & Plans**: Tradeskill recipes, schematics, and patterns.
- **Miscellaneous**: Tools, containers, Hearthstone, mounts, and vanity items.
- **Junk / Trash**: Poor-quality grey items ready for vendor resale.

Each category header features an item count badge and can be individually collapsed or expanded with instant state persistence.

### 2. Dual View Modes (Grid vs Categorized)
Click the View Mode icon in the header bar (or type `/bfb view`) to alternate instantly between:
- **All-in-One Grid**: Classic contiguous item grid displaying all equipped slots in sequential order.
- **Categorized Sections**: Grouped categories with dedicated headers and dynamic vertical spacing.

### 3. Unified Bank & Vault Frame
Consolidates your Main Bank container (Bag -1) and all 6 Bank Bags (Bags 5 to 10) into a single cohesive interface. Displays purchasable bank bag slots, purchase cost tooltips, and confirmation prompts.

### 4. Quick Deposit & Stacking Actions
- **Deposit All Trade Goods**: Transfers all crafting reagents from your inventory into free bank slots with one click.
- **Stack to Bank**: Scans your bags for items that already exist in the bank with incomplete stacks, merging them automatically.

### 5. Offline Bank Caching & Alt Tooltips
- **Offline Inspection**: Open your bank anywhere in the world by typing `/bfb bank` to view a cached snapshot.
- **Alt Stock Tracking**: Hovering over any item in your bags displays how many you have stored in the bank, complete with a character breakdown across your account on that realm.

### 6. Inventory Compactor & Sorter
Click the Sort icon in the header (or type `/bfb sort`) to initiate automated bag compaction:
- **Partial Stack Merging**: Detects incomplete stacks of identical items and consolidates them.
- **Systematic Ordering**: Arranges items by Category > Quality > Item Level > Name.
- **Non-Blocking Safety**: Executes across timed intervals, honoring container locks and aborting safely during combat lockdown.

### 7. Real-Time Search Filtering
Type any keyword into the integrated header search box to instantly highlight items matching your query. Non-matching items are smoothly dimmed to 20% opacity, allowing target items to stand out prominently without hiding your inventory layout.

### 8. Item Quality Glow & Status Overlays
- **Rarity Borders**: Vibrant quality color-coding applied directly to item borders.
- **Junk Indicator**: Vendor trash items display a discreet gold coin marker in the corner for effortless vendor selling passes.
- **Quest Item Glow**: Quest items and objective triggers receive a prominent gold glow.
- **Cooldown Sweeps**: Standard radial cooldown animations for usable trinkets, bandages, food, and potions.

### 9. Merchant Automation (Auto-Sell & Repair)
Streamline vendor visits with automated convenience:
- **Auto-Sell Junk**: Instantly liquidates all grey Poor-quality items, outputting total items sold and earnings in chat.
- **Auto-Repair**: Automatically restores item durability using player funds when visiting a repair-capable NPC.
- **Shift Bypass**: Hold `Shift` when opening a vendor to temporarily suspend all automated selling and repairing.

### 10. Equipped Bags Drawer
Click the bag icon in the header to expand an upper drawer revealing all equipped containers. Displays slot capacities and supports drag-and-drop equipping of newly looted bags.

### 11. Free Space & Currency Tracking
- **Free Space Counter**: Monitored in real time with dynamic color alerts (Green > Orange > Red). Hovering provides a granular breakdown by bag type.
- **Currency Tracker**: Live formatted Gold, Silver, and Copper display in the footer bar updating on every transaction.

### 12. Mover Coordination & Suite Integration
Reposition both Bags and Bank containers anywhere on your display with `/bfb mover`. When installed alongside `BleakfibersAddonConfig-Forever`, Bleakfiber's Bags responds to master mover unlocking (`/bac mover`) and non-destructive profile capture.

### 13. Native Configuration GUI & Profiles
A comprehensive, native Dark Slate & Gold graphical configuration panel accessible via `/bfb config` or `/bags config`:
- **Categorized Tabs**:
  - **General & Layout**: Adjust bag columns (6 to 20), button sizes (24 to 52px), slot padding, display modes (Classic Grid vs Categorized), and automated NPC interaction events.
  - **Display & Overlays**: Toggle item quality rarity borders, vendor junk coin markers, quest item golden glows, equipment item levels, bag bar drawers, and live search bars.
  - **Bank & Vault**: Customize bank columns (8 to 24), bank display modes, bank drawer visibility, offline snapshot caching, cross-character tooltip tracking, and cache flushing.
  - **Automation & Sorting**: Auto-sell grey junk, auto-repair equipment at vendors (with Shift-key bypass), and one-click bag/bank sorting and reagent depositing.
  - **Profiles & Positioning**: AceDB-3.0 non-destructive profile creation, profile switching, settings copying, reset to defaults, and independent mover controls.
- **Dual-Mode Rendering**: Embeds natively inside `BleakfibersAddonConfig-Forever` when installed, or displays as an independent draggable standalone window with ESC close handling.
- **Dynamic Reflow & Smart Scrollbars**: Features 2-column wide layout (`w >= 470px`) vs 1-column compact reflow (`w < 470px`) with automatic scrollbar management (`SetupAutoScroll`).

---

## ⌨️ Slash Commands

| Command | Action |
| :--- | :--- |
| `/bfb` or `/bags` | Toggle the all-in-one bag container window. |
| `/bfb bank` | Open or toggle the bank container window (active or cached). |
| `/bfb sort` | Compress partial stacks and sort bag inventory. |
| `/bfb view` | Toggle between All-in-One Grid and Categorized view. |
| `/bfb mover` | Unlock or lock the bag and bank frames for dragging. |
| `/bfb reset` | Reset the bag and bank positions to their default locations. |
| `/bfb config` | Open the graphical configuration panel. |

---

## 📥 Installation Guide

1. Download the latest version of **BleakfibersBags-Forever** from the [Releases](https://github.com/Bleakfiber/BleakfibersBags-Forever/releases) tab.
2. Extract the archive into your World of Warcraft directory:
   ```
   World of Warcraft\_classic_\Interface\AddOns\
   ```
3. Ensure the folder is named `BleakfibersBags-Forever` (not nested inside a duplicate folder).
4. Launch World of Warcraft and verify the addon is enabled on your character selection screen.

---

## 📜 License & Support

Bleakfiber's Bags is released under the **Source-Available Restricted License**. All rights reserved. Free for personal gameplay use and private code inspection. Unauthorized commercial distribution or derivative modifications are prohibited.
