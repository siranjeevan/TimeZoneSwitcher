# TimeZone Switcher

<p align="left">
  <a href="https://github.com/siranjeevan/TimeZoneSwitcher/releases/latest/download/TimeZoneSwitcher.dmg">
    <img src="https://img.shields.io/badge/Download-TimeZoneSwitcher.dmg-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Download DMG" />
  </a>
  <a href="https://github.com/siranjeevan/TimeZoneSwitcher/releases/latest">
    <img src="https://img.shields.io/github/v/release/siranjeevan/TimeZoneSwitcher?style=for-the-badge&color=28a745" alt="Latest Release" />
  </a>
  <img src="https://img.shields.io/badge/macOS-14.0+-black?style=for-the-badge&logo=apple" alt="macOS 14.0+" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License" />
</p>

TimeZone Switcher is a premium, beautifully crafted native macOS menu bar utility designed in SwiftUI. It provides an elegant command-center interface to browse, search, and dynamically switch system timezones effortlessly.

---

### ⬇️ [Click Here to Download Latest DMG](https://github.com/siranjeevan/TimeZoneSwitcher/releases/latest/download/TimeZoneSwitcher.dmg)

---

## Key Features

- **Dynamic Search**: Instantly find any IANA timezone by city, country, alias, or offset (using `⌘K` Command Palette).
- **Regions Browser**: Effortlessly browse timezones organized cleanly by continental regions (Asia, America, Europe, etc.).
- **Pinned Timezones**: Keep your favorite locations docked on your dashboard and view their real-time clocks directly in the macOS menu bar.
- **Direct Switch & Pin**: Switch your system timezone or pin/unpin favorites directly from search/browse lists.
- **Auto-Dismiss & Lock**: Hover out to automatically hide the app, with smart anchor locking under the status icon.

---

## Installation

### 1. Download DMG Directly (Recommended)

1. Download **[TimeZoneSwitcher.dmg](https://github.com/siranjeevan/TimeZoneSwitcher/releases/latest/download/TimeZoneSwitcher.dmg)**.
2. Open the downloaded `.dmg` file.
3. Drag **TimeZone Switcher** into your **Applications** folder.

### 2. Via Homebrew

To install TimeZone Switcher via Homebrew Cask:

```bash
# Add the tap
brew tap siranjeevan/tap

# Install the application
brew install --cask timezone-switcher
```

---

## Maintenance & Commands

### Upgrade
To check for and install updates:
```bash
brew update
brew upgrade timezone-switcher
```

### Uninstall
To completely remove the application, including configuration and support files:
```bash
brew uninstall --cask timezone-switcher
```

---

## Developer Guide

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later

### Building from Source
Clone the repository and build:
```bash
git clone https://github.com/siranjeevan/TimeZoneSwitcher.git
cd TimeZoneSwitcher
xcodebuild -project TimeZoneSwitcher.xcodeproj -scheme TimeZoneSwitcher -sdk macosx build
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
