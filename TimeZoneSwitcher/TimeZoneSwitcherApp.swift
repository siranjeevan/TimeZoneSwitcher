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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create Popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 500, height: 270)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
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
    
    private func updateMenuBarTitle(with date: Date) {
        let format = SettingsManager.shared.menuBarFormat
        
        if format == .iconOnly {
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.title = "🌍"
            }
            return
        }
        
        let indFormatter = DateFormatter()
        indFormatter.timeZone = TimeZone(identifier: "Asia/Calcutta")
        
        let laFormatter = DateFormatter()
        laFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        
        switch format {
        case .modern:
            indFormatter.dateFormat = "h:mm a"
            laFormatter.dateFormat = "h:mm a"
            let indString = indFormatter.string(from: date)
            let laString = laFormatter.string(from: date)
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.title = "🇮🇳 \(indString)  ❙  🇺🇸 \(laString)"
            }
            
        case .developer:
            indFormatter.dateFormat = "h:mm a"
            laFormatter.dateFormat = "h:mm a"
            let indString = indFormatter.string(from: date)
            let laString = laFormatter.string(from: date)
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.title = "IN • \(indString)  |  US • \(laString)"
            }
            
        case .dayNight:
            indFormatter.dateFormat = "h:mm a"
            laFormatter.dateFormat = "h:mm a"
            let indString = indFormatter.string(from: date)
            let laString = laFormatter.string(from: date)
            
            // Determine if day or night (6am to 6pm is day)
            let indHour = Calendar.current.component(.hour, from: date)
            let indSunMoon = (6...18).contains(indHour) ? "☀️" : "🌙"
            
            let laHour = Calendar.current.component(.hour, from: date)
            let laSunMoon = (6...18).contains(laHour) ? "☀️" : "🌙"
            
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.title = "\(indSunMoon) \(indString)  ❙  \(laSunMoon) \(laString)"
            }
            
        case .classic:
            indFormatter.dateFormat = "E d / h.mm a"
            laFormatter.dateFormat = "E d / h.mm a"
            let indString = indFormatter.string(from: date)
            let laString = laFormatter.string(from: date)
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.title = "🌍 Ind: \(indString) , Los: \(laString)"
            }
            
        case .iconOnly:
            break
        }
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
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
