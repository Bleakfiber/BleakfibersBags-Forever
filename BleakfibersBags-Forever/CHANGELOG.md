# Changelog - Bleakfiber's Bags (Forever)

All notable changes to **Bleakfiber's Bags - Forever** are documented below.

## [1.3.0] - 2026-10-08: Phase 4 Native Configuration GUI & Profile Engine

### Added
- **Native Dark Slate & Gold Configuration Panel (`UI.lua`)**:
  - Full-featured, modular options interface styled with signature Dark Slate & Gold theme aesthetics.
  - Tabbed organization:
    - **General & Layout**: Configurable bag columns (6 to 20), button size (24 to 52px), slot spacing, view mode toggle (Classic Grid vs Categorized), and granular NPC auto-open/close event triggers.
    - **Display & Overlays**: Toggles for item quality border glow, vendor junk coin indicators, quest item golden borders, equipment item level overlays, bag slots drawer, and live search bar.
    - **Bank & Vault**: Bank columns slider (8 to 24), bank display mode, bank bag slots drawer, offline snapshot caching toggle, cross-character tooltip tracking, and clear cache utility.
    - **Automation & Sorting**: Auto-sell grey junk, auto-repair equipment at vendors, Shift-key bypass guidelines, and direct actions for bag sorting, bank sorting, and trade goods deposit.
    - **Profiles & Positioning**: AceDB-3.0 non-destructive profile creation, profile switching, settings copying, reset to defaults, and independent mover controls.
- **Dual-Mode Rendering (`isMasterHub`)**:
  - Seamlessly integrates into `BleakfibersAddonConfig-Forever` when installed, inheriting Master Hub styling, global movers, and synchronized profile switching.
  - Standalone fallback window with drag handle and ESC close support when opened via `/bfb config` without BAC installed.
- **Dynamic Responsive Reflow & Smart Scrollbars**:
  - Automatically shifts between a balanced 2-column layout (`width >= 470px`) and single-column vertical stack (`width < 470px`) to prevent text overlap and clipping.
  - Smart auto-hiding scrollbar (`SetupAutoScroll`) disables wheel scrolling and hides scrollbars when content fits within the viewport.

## [1.2.0] - 2026-10-08: Phase 3 Bank, Vault & Reagent Integration

### Added
- **Unified Bank & Vault Frame (`BankFrame.lua`)**:
  - Full Dark Slate & Gold container frame consolidating Main Bank (Bag -1) and all 6 Bank Bags (Bags 5 to 10) into a single unified window.
  - Seamlessly supports both All-in-One Grid mode and Intelligent Categorized sections.
  - Expandable Bank Bags Drawer displaying equipped bank bags, slot capacities, and unpurchased bank slots with purchase cost tooltips and one-click purchase support.
  - Live search filtering input box dimming non-matching bank items on keystroke.
- **Quick Deposit & Stacking Actions**:
  - **Deposit All Trade Goods**: One-click transfer transferring all crafting reagents and consumables from inventory into available bank slots.
  - **Stack to Bank**: Automatically detects matching incomplete item stacks between your bags and the bank, merging them with a single click.
- **Offline Bank Caching & Alt Tooltips (`BankCache.lua`)**:
  - Automatically caches bank inventory snapshots into SavedVariables on bank visits.
  - Allows inspecting bank contents from anywhere in the world (`/bfb bank`) with an amber `[Cached]` header indicator.
  - Tooltip integration: Hovering over any item in your bags displays total stock in the bank, including breakdowns across alternate characters on the realm.
- **Side-by-Side Window Orchestration**:
  - Visiting a banker automatically opens player bags and the bank container side-by-side without overlapping.
  - Closing the bank safely dismisses both frames.
  - Suppressed default Blizzard `BankFrame` popup.
- **Independent Mover Coordination**:
  - Persistent bank coordinates stored in `db.bankPosition`, with mover overlay support via `/bfb mover` and `/bac mover`.

---

## [1.1.0] - 2026-10-08: Phase 2 Categorization & Intelligent Organization Engine

### Added
- **Intelligent Categorization Engine (`CategoryEngine.lua`)**:
  - Automatic classification of inventory items into dedicated sections: *Quest Items*, *Equipment & Gear*, *Consumables*, *Trade Goods & Crafting*, *Recipes & Plans*, *Miscellaneous*, *Junk / Trash*, and *Free Slots*.
  - Collapsible category header bars styled in Dark Slate & Gold with item counters (e.g. `Equipment & Gear (14)`) and persistent state memory.
- **Dual View Modes (Grid vs Categorized)**:
  - Instant one-click toggle button in the header bar to alternate between the classic All-in-One Grid and Intelligent Categorized sections.
  - Supports `/bfb view` slash command for fast switching.
- **Automated Bag Compactor & Sorter (`Sorting.lua`)**:
  - Safe, non-blocking inventory sorting engine triggered via the header Sort button or `/bfb sort`.
  - Automatically merges incomplete partial stacks across all equipped bags.
  - Prioritizes items systematically: Category Order > Quality > Item Level > Alphabetical Name.
  - Combat lockdown safety guards prevent script errors or action blockages during combat.
- **Merchant Automation (Auto-Sell & Auto-Repair)**:
  - Automatically sells all Poor-quality junk items upon visiting a merchant vendor, reporting total items sold and copper/silver/gold earned in chat.
  - Automatically repairs equipped gear and inventory items with player funds.
  - Hold `Shift` when opening a vendor to temporarily bypass auto-sell and auto-repair.

---

## [1.0.0] - 2026-10-08: Phase 1 Foundation & Core Architecture

### Added
- **All-in-One Container Frame**: Unified, high-performance container window replacing default Blizzard bag popups with a single, streamlined Dark Slate & Gold interface.
- **Pooled Item Button Grid**: Memory-efficient button pooling system with customizable column width (`columns = 10`), button sizing, and spacing.
- **Real-Time Search Bar**: Live search input box with placeholder and instant clear button that dims non-matching items on keystroke (`SetAlpha(0.2)`).
- **Item Quality Glow & Overlays**: Crisp 1.5px border colored by item quality (Common, Uncommon, Rare, Epic, Legendary), vendor junk coin icons on poor-quality items, and quest item glow indicators.
- **Equipped Bag Slots Drawer**: Expandable/collapsible drawer displaying equipped bags with slot counts and inventory item tooltips.
- **Capacity & Currency Footer**: Real-time free slots counter with color-coded alerts and detailed bag breakdown tooltip, paired with a formatted Gold/Silver/Copper currency tracker.
- **Mover System & Suite Integration**: Full positioning persistence with interactive mover overlay (`/bfb mover`) and soft registration into `BleakfibersAddonConfig-Forever`.
- **Game Interaction Automation**: Configurable auto-open and auto-close triggers for merchants, banks, mailboxes, auctions, and trade windows.
