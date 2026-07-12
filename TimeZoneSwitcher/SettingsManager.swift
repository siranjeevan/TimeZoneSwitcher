import Foundation
import SwiftUI
import ServiceManagement

@Observable
public final class SettingsManager {
    public static let shared = SettingsManager()
    
    private init() {}
    
    public var theme: AppTheme {
        get {
            let value = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
            return AppTheme(rawValue: value) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appTheme")
        }
    }
    
    public var refreshInterval: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "refreshInterval")
            return value == 0 ? 1.0 : value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "refreshInterval")
        }
    }
    
    public var launchAtLogin: Bool {
        get {
            // Synchronize with SMAppService state to ensure accuracy
            return SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
            } catch {
                print("Failed to toggle Launch at Login SMAppService: \(error)")
            }
        }
    }
    
    public var menuBarFormat: MenuBarFormat {
        get {
            let value = UserDefaults.standard.string(forKey: "menuBarFormat") ?? MenuBarFormat.developer.rawValue
            return MenuBarFormat(rawValue: value) ?? .developer
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "menuBarFormat")
        }
    }
}

public enum MenuBarFormat: String, CaseIterable, Identifiable {
    case modern = "Modern Flags (🇮🇳 12:00 AM  ❙  🇺🇸 12:00 AM)"
    case developer = "Developer Dot (IN • 12:00 AM  |  US • 12:00 AM)"
    case dayNight = "Day & Night (☀️ 12:00 AM  ❙  🌙 12:00 AM)"
    case classic = "Classic Info (Ind: Thu 9 / 12.00 AM , Los: Thu 9 / 12.00 AM)"
    case iconOnly = "Icon Only"
    
    public var id: String { self.rawValue }
}

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { self.rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
