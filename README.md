# Bleakfiber's Bags - Forever

[![Interface](https://img.shields.io/badge/Interface-16001%20(WoW%20Forever)-0078D7.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersBags-Forever)
[![Release](https://img.shields.io/badge/Release-v1.0.0-ffd100.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersBags-Forever/releases)
[![License](https://img.shields.io/badge/License-Source--Available-crimson.svg?style=flat-square)](LICENSE.md)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-2ea44f.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersBags-Forever)
[![Suite](https://img.shields.io/badge/Suite-Bleakfiber's%20Addon%20Suite-8a2be2.svg?style=flat-square)](https://github.com/Bleakfiber)

**Bleakfiber's Bags** is a lightweight, high-performance all-in-one inventory and container management suite crafted specifically for **World of Warcraft: Forever** (Interface 16001).

Engineered to replace cluttered individual bag windows with a unified, elegant **Dark Slate & Gold** container frame, it combines memory-efficient pooled item buttons with real-time search filtering, item quality borders, vendor junk detection, capacity metrics, and seamless integration with the **Bleakfiber Addon Suite**.

Runs **100% standalone out of the box** with zero required external dependencies or mandatory addons.

---

## 📑 Table of Contents

- [Key Highlights](#-key-highlights)
- [Feature Showcase](#-feature-showcase)
  - [1. Unified All-in-One Container](#1-unified-all-in-one-container)
  - [2. Real-Time Search Filtering](#2-real-time-search-filtering)
  - [3. Item Quality Glow & Status Overlays](#3-item-quality-glow--status-overlays)
  - [4. Equipped Bags Drawer](#4-equipped-bags-drawer)
  - [5. Free Space & Currency Tracking](#5-free-space--currency-tracking)
  - [6. Interaction Automation](#6-interaction-automation)
  - [7. Mover Coordination & Suite Integration](#7-mover-coordination--suite-integration)
- [Slash Commands](#-slash-commands)
- [Installation Guide](#-installation-guide)
- [License & Support](#-license--support)

---

## 🌟 Key Highlights

* **Unified All-in-One View**: Aggregates your backpack and all 4 equipped bags into a single, cohesive, modern interface.
* **Instant Keystroke Search**: Dims non-matching items in real time as you type, making locating quest items, reagents, or gear instantaneous.
* **Item Quality Borders**: Crisp, beveled border highlights indicating item rarity (Uncommon, Rare, Epic, Legendary).
* **Vendor Junk & Quest Detection**: Subtle coin icons mark vendor trash (`quality == 0`), while bright indicators highlight active quest items.
* **Capacity Breakdown**: Live free slots counter with color-coded warning levels and a detailed hover tooltip summarizing slot counts across each equipped bag.
* **Master Mover Support**: Drag-and-drop repositioning with full coordinate persistence and unified mover unlocking via `/bfb mover` or `/bac mover`.
* **Zero Overhead**: Fully pooled frame architecture ensures zero garbage generation during routine bag opening and inventory scans.

---

## 🎯 Feature Showcase

### 1. Unified All-in-One Container
Replaces Blizzard's fragmented multi-window bag popups with a singular, cleanly organized inventory grid. Automatically calculates rows and columns based on your total available slots and scales seamlessly.

### 2. Real-Time Search Filtering
Type any keyword into the integrated header search box to instantly highlight items matching your query. Non-matching items are smoothly dimmed to 20% opacity, allowing target items to stand out prominently without hiding your inventory layout.

### 3. Item Quality Glow & Status Overlays
- **Rarity Borders**: Vibrant quality color-coding applied directly to item borders.
- **Junk Indicator**: Vendor trash items display a discreet gold coin marker in the corner for effortless vendor selling passes.
- **Quest Item Glow**: Quest items and objective triggers receive a prominent gold glow.
- **Cooldown Sweeps**: Standard radial cooldown animations for usable trinkets, bandages, food, and potions.

### 4. Equipped Bags Drawer
Click the bag icon in the header to expand an upper drawer revealing all 5 equipped containers (Backpack + Bags 1–4). Displays slot capacities and supports drag-and-drop equipping of newly looted bags.

### 5. Free Space & Currency Tracking
- **Free Space Counter**: Monitored in real time with dynamic color alerts (Green > Orange > Red). Hovering provides a granular breakdown by bag type.
- **Currency Tracker**: Live formatted Gold, Silver, and Copper display in the footer bar updating on every transaction.

### 6. Interaction Automation
Configure automated opening and closing behaviors when interacting with:
- Merchant vendors
- Bank vaults
- Mailboxes
- Auction houses
- Trade windows

### 7. Mover Coordination & Suite Integration
Reposition the container anywhere on your display with `/bfb mover`. When installed alongside `BleakfibersAddonConfig-Forever`, Bleakfiber's Bags responds to master mover unlocking (`/bac mover`) and non-destructive profile capture.

---

## ⌨️ Slash Commands

| Command | Action |
| :--- | :--- |
| `/bfb` or `/bags` | Toggle the all-in-one bag container window. |
| `/bfb mover` | Unlock or lock the bag frame for dragging. |
| `/bfb reset` | Reset the bag frame position to the default location. |
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
