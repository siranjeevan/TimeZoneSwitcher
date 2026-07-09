# TimeZone Switcher

TimeZone Switcher is a premium, beautifully crafted native macOS menu bar utility designed in SwiftUI. It provides an elegant command-center interface to browse, search, and dynamically switch system timezones effortlessly.

## Key Features

- **Dynamic Search**: Instantly find any IANA timezone by city, country, alias, or offset (using `⌘K` Command Palette).
- **Regions Browser**: Effortlessly browse timezones organized cleanly by continental regions (Asia, America, Europe, etc.).
- **Pinned Timezones**: Keep your favorite locations docked on your dashboard and view their real-time clocks directly in the macOS menu bar.
- **Direct Switch & Pin**: Switch your system timezone or pin/unpin favorites directly from search/browse lists.
- **Auto-Dismiss & Lock**: Hover out to automatically hide the app, with smart anchor locking under the status icon.

---

## Installation

### Via Homebrew (Recommended)

To install TimeZone Switcher via Homebrew Cask, tap the repository and install:

```bash
# Add the tap
brew tap myusername/tap

# Install the application
brew install --cask timezone-switcher
```

### Manual Installation

Download the latest `TimeZoneSwitcher.dmg` from the [Releases](https://github.com/myusername/TimeZoneSwitcher/releases) page, mount the image, and drag **TimeZone Switcher** to your `Applications` folder.

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
git clone https://github.com/myusername/TimeZoneSwitcher.git
cd TimeZoneSwitcher
xcodebuild -project TimeZoneSwitcher.xcodeproj -scheme TimeZoneSwitcher -sdk macosx build
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
