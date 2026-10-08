# Bleakfiber's Bags - Forever

**Bleakfiber's Bags** is a lightweight, high-performance inventory and container management suite crafted specifically for **World of Warcraft: Forever** (Interface 16001).

Engineered to replace cluttered individual bag and bank windows with an elegant **Dark Slate & Gold** (`#141A21` / `#D1AE47`) container interface, it combines memory-efficient pooled item buttons with intelligent dynamic categorization, real-time search filtering, one-click stack sorting, offline bank caching with multi-alt stock tooltips, merchant automation, and seamless integration with the **Bleakfiber Addon Suite**.

Runs 100% standalone out of the box with zero required external dependencies or mandatory addons, and automatically embeds into **Bleakfiber's Addon Config** when installed.

---

## Key Highlights

- **Zero Required External Dependencies**: Pure, lightweight native WoW Lua engine. Runs completely standalone or seamlessly leverages LibSharedMedia when present.
- **Unified Bags & Bank Containers**:
  - Replaces fragmented default bag and bank frames with matching Dark Slate & Gold container windows that open side-by-side cleanly without overlapping.
  - Consolidates Main Bank and all 6 Bank Bags into a single cohesive interface with purchasable slot drawer.
- **Intelligent Categorization Engine**:
  - Groups items automatically into collapsible sections: *Recent Items*, *Quest Items*, *Equipment & Gear*, *Consumables*, *Trade Goods & Crafting*, *Recipes & Plans*, *Miscellaneous*, and *Junk / Trash*.
  - Each header includes an item count badge and persistent collapse/expand state memory.
- **Dual View Modes (Grid vs Categorized)**:
  - Instant one-click toggle button in the header bar (`/bfb view`) to alternate between the classic All-in-One Grid and Intelligent Categorized sections.
- **Recent Items Engine**:
  - Automatically captures looted items from chat log (`CHAT_MSG_LOOT`) and surfaces them into a high-priority "Recent Items" section at the top of the categorized bag window.
  - Displays an eye-catching cyan diamond corner indicator on newly acquired items with a configurable duration window.
- **Equipment Usability Scanner & Red Tint**:
  - Hidden tooltip scanner detecting character level requirements, class restrictions, and armor/weapon proficiencies.
  - Applies a subtle red overlay to unusable gear so you know at a glance what cannot be equipped.
- **Specialty Container Slot Recognition**:
  - Detects profession and class bags (Soul Bags, Herb Bags, Mining Sacks, Enchanting Bags, and Quivers/Ammo pouches) and color-codes empty specialty slots.
- **Custom Category Overrides & In-Game Context Menu**:
  - Alt + Right-Click any item in your bags or bank to open an instant Dark Slate & Gold context menu and reassign it to any desired category.
- **Quick Reagent Transfer & Stacking**:
  - One-click **Deposit Trade Goods** and **Stack to Bank** buttons transfer crafting reagents and merge incomplete stacks instantly.
- **Offline Bank Caching & Alt Tooltips**:
  - Browse bank contents from anywhere in the world (`/bfb bank`) with an amber `[Cached]` header indicator.
  - Tooltip integration displaying realm-wide character stock counts across all your alts.
- **Automated Bag Compactor & Sorter**:
  - Consolidates partial item stacks and sorts inventory items safely in non-blocking steps to avoid client freezes, automatically pausing during combat.
- **Merchant Automation (Auto-Sell & Auto-Repair)**:
  - Automatically sells Poor-quality junk items upon visiting a merchant vendor and repairs equipped gear with personal funds.
  - Hold `Shift` when opening a vendor to temporarily bypass auto-sell and auto-repair.
- **Advanced Search Keyword Syntax**:
  - Real-time search filter supporting item names, types, binding status (`boe`, `bop`, `soulbound`), category keywords (`quest`, `junk`, `gear`, `consumable`, `reagent`), rarity keywords (`poor`, `common`, `uncommon`, `rare`, `epic`), and numeric level comparison queries (`>30`, `<20`).
- **Equipped Bags & Keyring Drawers**:
  - Expandable drawer displaying equipped containers with slot capacities, plus direct one-click Keyring access in the header.
- **Free Space & Currency Tracking**:
  - Real-time free slots counter with color-coded alerts and detailed bag breakdown tooltip, paired with a formatted Gold/Silver/Copper currency tracker.
- **Dual-Mode Configuration GUI (`/bfb config`)**:
  - **Standalone Mode**: Draggable Dark Slate & Gold options window with ESC-close handling.
  - **Master Hub Integration**: Embeds directly into **`BleakfibersAddonConfig-Forever`** with 2-column responsive reflow, smart scrollbars, master movers (`/bac mover`), and non-destructive profile synchronization.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/bfb` or `/bags` | Toggle the all-in-one bag container window |
| `/bfb bank` | Open or toggle the bank container window (active or cached) |
| `/bfb sort` | Compress partial stacks and sort bag inventory |
| `/bfb view` | Toggle between All-in-One Grid and Categorized view |
| `/bfb mover` | Unlock or lock the bag and bank frames for dragging |
| `/bfb reset` | Reset the bag and bank positions to their default locations |
| `/bfb config` | Open the graphical configuration panel |

---

## Installation

1. Download the latest release from the [Releases](https://github.com/Bleakfiber/BleakfibersBags-Forever/releases) tab.
2. Extract the archive into your World of Warcraft directory:
   ```
   World of Warcraft\_classic_\Interface\AddOns\
   ```
3. Ensure the folder is named `BleakfibersBags-Forever` (not nested inside a duplicate folder).
4. Launch World of Warcraft and verify the addon is enabled on your character selection screen.

---

## License

Bleakfiber's Bags is released under the **Source-Available Restricted License**. All rights reserved. Free for personal gameplay use and private code inspection. Unauthorized commercial distribution or derivative modifications are prohibited.
