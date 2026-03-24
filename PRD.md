# Fringer - macOS Menu Bar Manager

## Overview

Fringer is a macOS menu bar management app that lets users organize, hide, and customize their menu bar icons. It aims to replicate and extend the functionality of Bartender, the popular (but now acquired) menu bar manager.

**Target**: macOS 14+ (Sonoma and later)
**Language**: Swift / SwiftUI + AppKit
**Distribution**: Non-sandboxed, notarized, direct distribution (DMG)

---

## 1. Core Features

### 1.1 Menu Bar Icon Visibility Management
- Three visibility states per icon: **Shown** (always visible), **Hidden** (in overflow bar, revealed on demand), **Always Hidden** (only accessible via search)
- Drag-and-drop reordering within settings and via Cmd+drag in the live menu bar
- Auto-detection of new menu bar items as apps launch
- Persistent arrangement across app restarts

### 1.2 Fringer Bar (Secondary Overflow Bar)
- A custom panel that slides out below the menu bar containing all "hidden" items
- Triggered by clicking the Fringer icon, hotkey, or hover (configurable)
- Auto-dismisses after configurable delay when mouse leaves
- Icons are fully interactive — clicking them triggers the real menu bar item
- Displays captured icon images of hidden items

### 1.3 Quick Reveal
- Hovering over the menu bar area temporarily reveals all hidden icons inline
- Configurable: enable/disable, trigger on hover or Option+hover
- Auto-hides after configurable delay

### 1.4 Section Separators
- NSStatusItem-based separator icons define section boundaries
- Visual spacers can be inserted between icons for grouping
- Spacers can display custom labels or emoji

---

## 2. Triggers & Automation

### 2.1 Per-Icon "Show for Updates"
- **Any Change**: Show a hidden icon whenever its appearance changes
- **Script Trigger**: Run a shell script; show the icon based on exit code

### 2.2 Global Triggers (Activate Presets)
- **Battery**: On battery / charging / specific percentage
- **Wi-Fi**: Connected/disconnected, specific network name
- **Time/Date**: Scheduled times, days of week
- **App-based**: Activate preset when specific app launches/quits

### 2.3 Interaction Triggers
- Click Fringer icon to toggle overflow bar
- Hover over Fringer icon or empty menu bar space
- Configurable global hotkey

---

## 3. Presets / Profiles

- Named configurations of which icons are shown/hidden
- Switch manually or automatically via triggers
- Use cases: "Meeting mode", "Focus mode", "Recording mode"
- Each preset stores its own icon arrangement and visibility

---

## 4. Customization

### 4.1 Menu Bar Appearance
- **Tint/Color**: Solid color or gradient overlay on the menu bar
- **Border**: Configurable thickness and color
- **Shadow**: Drop shadow beneath the menu bar
- **Pill Shape**: Rounded "pill" shape with optional left/right split
- **Spacing**: Normal / Small / No spacing between icons

### 4.2 Menu Bar Item Groups
- Consolidate multiple icons under a single custom icon
- Custom icon from SF Symbols or emoji
- Click or hover to expand and show contained items

### 4.3 Widgets
- Custom menu bar items not tied to any app
- Can trigger actions: open URL, run script, open app
- Customizable icon (SF Symbols) and label

---

## 5. Search & Quick Access

### 5.1 Quick Search
- Global hotkey to invoke search bar in the menu bar area
- Type to filter/find any menu bar item by name
- Press Return to activate the found item
- Works across all visibility states

### 5.2 Per-Item Hotkeys
- Assign global keyboard shortcut to any menu bar item
- Actions: left-click, right-click, left/right-click with Option, or "Just Show"

---

## 6. System Integration

### 6.1 Permissions Required
| Permission | Purpose |
|---|---|
| Accessibility | Enumerate and interact with other apps' menu bar items |
| Screen Recording | Capture menu bar item icons for display in overflow bar |

### 6.2 Notch Compatibility
- Detect MacBook notch and manage icon overflow
- Provide access to icons hidden behind the notch
- Calculate available space from screen geometry

### 6.3 Multi-Display Support
- Manage menu bars across all connected displays

### 6.4 General
- Launch at login (via SMAppService)
- Auto-update support (via Sparkle)
- Reduce energy usage on battery option

---

## 7. UI/UX

### 7.1 Settings Window
Tabs:
1. **Menu Bar Items** — Three-section list (Shown/Hidden/Always Hidden) with drag-and-drop
2. **Appearance** — Tint, gradient, border, shadow, pill shape, spacing
3. **Hotkeys** — Global hotkeys and per-item assignments
4. **Triggers** — Configure automatic preset activation
5. **Presets** — Create and manage saved layouts
6. **General** — Launch at login, energy saving, update preferences

### 7.2 Fringer Menu Bar Icon
- Small icon (e.g., three dots or custom) in the menu bar
- Left-click: Toggle Fringer Bar
- Right-click: Open settings
- The icon itself can be customized or hidden

### 7.3 First-Run Experience
- Permission request flow: Accessibility, then Screen Recording
- Setup wizard to drag-and-drop items into sections
- Brief introduction to core concepts

---

## 8. Technical Architecture

### 8.1 Core Components
```
FringerApp.swift              — @main SwiftUI entry point (LSUIElement)
MenuBarController             — Owns NSStatusItem dividers, handles toggle
MenuBarItemManager            — Discovers items via CGWindowList + Accessibility
AppearanceManager             — Tinting, shapes, styling
HotkeyManager                 — Global hotkey registration via CGEvent taps
SettingsManager               — UserDefaults + JSON persistence
PermissionsManager            — Accessibility/Screen Recording prompting
LaunchAtLoginManager          — SMAppService integration
```

### 8.2 Key APIs
- `CGWindowListCopyWindowInfo` (layer 25) — Discover menu bar item windows
- `CGWindowListCreateImage` — Capture icon images
- `AXUIElement` — Interact with other apps' items
- `CGEvent` taps — Global hotkeys and mouse tracking
- `NSStatusBar` / `NSStatusItem` — Section dividers
- `NSWindow` / `NSPanel` — Overflow bar

### 8.3 Architecture Pattern
- SwiftUI for all settings/preferences UI
- AppKit for menu bar management, window management, system integration
- `@Observable` for state management (macOS 14+)
- Single `AppState` shared via SwiftUI environment

---

## 9. Development Phases

### Phase 1: MVP — Basic Show/Hide
- [ ] Xcode project setup (LSUIElement, non-sandboxed)
- [ ] Menu bar icon with Fringer presence
- [ ] Discover other apps' menu bar items
- [ ] Section-based hiding (visible/hidden) with NSStatusItem separators
- [ ] Click to toggle hidden section
- [ ] Settings window with item list and drag-and-drop
- [ ] Accessibility permission flow
- [ ] Launch at login

### Phase 2: Fringer Bar & Polish
- [ ] Custom overflow panel (Fringer Bar) with captured icons
- [ ] Screen Recording permission flow
- [ ] Hotkey to toggle Fringer Bar
- [ ] Quick reveal on hover
- [ ] Persistent arrangement across restarts
- [ ] Multi-display support

### Phase 3: Advanced Features
- [ ] Quick Search
- [ ] Per-item hotkeys
- [ ] Presets/Profiles
- [ ] Menu bar appearance customization (tint, pill, spacing)
- [ ] Spacers and groups
- [ ] Auto-update via Sparkle

### Phase 4: Automation & Triggers
- [ ] Show-for-updates triggers
- [ ] Battery/Wi-Fi/Time triggers
- [ ] App-based triggers
- [ ] Script triggers
- [ ] Widgets

---

## 10. Dependencies

| Library | Purpose |
|---|---|
| [HotKey](https://github.com/soffes/HotKey) | Global hotkey registration |
| [Sparkle](https://github.com/sparkle-project/Sparkle) | Auto-updates |
| [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin-Modern) | SMAppService wrapper |

---

## 11. Reference Projects

- [Ice](https://github.com/jordanbaird/Ice) — Most feature-rich open source alternative (GPL-3.0)
- [Hidden Bar](https://github.com/dwarvesf/hidden) — Simplest implementation
- [Dozer](https://github.com/Mortennn/Dozer) — Three-divider system
