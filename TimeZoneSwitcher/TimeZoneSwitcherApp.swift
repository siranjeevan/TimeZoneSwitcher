import SwiftUI
import AppKit

@main
struct TimeZoneSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var isClosing = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create Popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 500, height: 270)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        popover.delegate = self
        self.popover = popover
        
        // Create Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Start updates
        updateMenuBarTitle(with: Date())
        ClockManager.shared.onTick = { [weak self] date in
            self?.updateMenuBarTitle(with: date)
        }
        
        // Listen to close popover requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: Notification.Name("ClosePopover"),
            object: nil
        )
    }
    
    @objc private func closePopover() {
        DispatchQueue.main.async { [weak self] in
            self?.popover?.performClose(nil)
        }
    }
    
    private func getShortLabel(for model: TimeZoneModel) -> String {
        switch model.country.lowercased() {
        case "india": return "IN"
        case "united states": return "US"
        case "united kingdom": return "UK"
        case "japan": return "JP"
        case "south korea": return "KR"
        case "australia": return "AU"
        case "germany": return "DE"
        case "france": return "FR"
        case "singapore": return "SG"
        default:
            return String(model.city.prefix(3)).uppercased()
        }
    }

    private func updateMenuBarTitle(with date: Date) {
        let format = SettingsManager.shared.menuBarFormat
        
        if format == .iconOnly {
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.title = "🌍"
            }
            return
        }
        
        let favIds = TimeZoneManager.shared.favoriteTimeZones
        let timeZonesToShow: [TimeZoneModel]
        if favIds.isEmpty {
            timeZonesToShow = [TimeZoneModel(identifier: TimeZone.current.identifier)]
        } else {
            timeZonesToShow = favIds.map { id in
                TimeZoneManager.shared.allTimeZones.first(where: { $0.id == id }) ?? TimeZoneModel(identifier: id)
            }
        }
        
        var segments = [String]()
        
        for model in timeZonesToShow {
            guard let tz = TimeZone(identifier: model.id) else { continue }
            let formatter = DateFormatter()
            formatter.timeZone = tz
            
            let label = getShortLabel(for: model)
            
            switch format {
            case .modern:
                formatter.dateFormat = "h:mm a"
                let timeStr = formatter.string(from: date)
                segments.append("\(label) \(timeStr)")
                
            case .developer:
                formatter.dateFormat = "h:mm a"
                let timeStr = formatter.string(from: date)
                segments.append("\(label) • \(timeStr)")
                
            case .dayNight:
                formatter.dateFormat = "h:mm a"
                let timeStr = formatter.string(from: date)
                let localHour = Calendar.current.dateComponents(in: tz, from: date).hour ?? 12
                let sunMoon = (6...18).contains(localHour) ? "☀️" : "🌙"
                segments.append("\(sunMoon) \(label) \(timeStr)")
                
            case .classic:
                formatter.dateFormat = "E d / h.mm a"
                let timeStr = formatter.string(from: date)
                segments.append("\(label): \(timeStr)")
                
            case .iconOnly:
                break
            }
        }
        
        let separator: String
        switch format {
        case .modern, .dayNight:
            separator = "  ❙  "
        case .developer:
            separator = "  |  "
        case .classic:
            separator = " , "
        default:
            separator = " "
        }
        
        let titleString = segments.joined(separator: separator)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusItem?.button?.title = titleString
        }
    }
    
    func popoverWillClose(_ notification: Notification) {
        isClosing = true
    }
    
    func popoverDidClose(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isClosing = false
        }
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if isClosing {
            return
        }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                // Small delay lets window focus settle so the popover positions correctly under the menu bar
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    popover.contentViewController?.view.window?.makeKey()
                }
            }
        }
    }
}
