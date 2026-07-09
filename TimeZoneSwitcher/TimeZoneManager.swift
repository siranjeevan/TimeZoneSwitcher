import Foundation
import AppKit
import UserNotifications
import Combine
import CoreLocation

// MARK: - TimeZone Model
public struct TimeZoneModel: Identifiable, Hashable {
    public let id: String
    public let city: String
    public let country: String
    public let flag: String
    public let gmtOffset: String
    public let rawOffset: Int
    
    public init(identifier: String) {
        self.id = identifier
        let components = identifier.split(separator: "/")
        self.city = components.last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        self.country = components.first.map(String.init) ?? "Unknown"
        
        let tz = TimeZone(identifier: identifier) ?? TimeZone.current
        let seconds = tz.secondsFromGMT()
        self.rawOffset = seconds
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        self.gmtOffset = String(format: "GMT%+d:%02d", hours, minutes)
        
        // Simple flag mapping based on continent
        switch self.country {
        case "America", "US": self.flag = "🇺🇸"
        case "Europe": self.flag = "🇪🇺"
        case "Asia":
            if self.city == "Calcutta" || self.city == "Kolkata" { self.flag = "🇮🇳" }
            else if self.city == "Tokyo" { self.flag = "🇯🇵" }
            else if self.city == "Seoul" { self.flag = "🇰🇷" }
            else if self.city == "Dubai" { self.flag = "🇦🇪" }
            else { self.flag = "🌏" }
        case "Australia": self.flag = "🇦🇺"
        case "Africa": self.flag = "🌍"
        case "Pacific": self.flag = "🏝️"
        default: self.flag = "🌐"
        }
    }
}

@Observable
public final class TimeZoneManager {
    public static let shared = TimeZoneManager()
    
    // Status and state
    public var currentSystemTimeZone: TimeZone = TimeZone.current
    public var lastSwitchedDate: Date? {
        get {
            UserDefaults.standard.object(forKey: "lastSwitchedDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastSwitchedDate")
        }
    }
    
    public var errorMessage: String?
    public var showPermissionAlert = false
    public var isSwitching = false
    
    private init() {
        refresh()
        loadAllTimeZones()
        // Register to receive notifications when system time zone changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemTimeZoneDidChange),
            name: Notification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )
    }
    
    @objc private func systemTimeZoneDidChange() {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    public func refresh() {
        // Reset TimeZone cache to get fresh info
        NSTimeZone.resetSystemTimeZone()
        currentSystemTimeZone = TimeZone.current
    }
    
    public var allTimeZones: [TimeZoneModel] = []
    public var searchQuery: String = ""
    
    public var filteredTimeZones: [TimeZoneModel] {
        if searchQuery.isEmpty {
            return allTimeZones
        }
        let q = searchQuery.lowercased()
        return allTimeZones.filter { tz in
            tz.city.lowercased().contains(q) ||
            tz.country.lowercased().contains(q) ||
            tz.id.lowercased().contains(q)
        }
    }
    
    public var favoriteTimeZones: [String] {
        get { UserDefaults.standard.stringArray(forKey: "favoriteTimeZones") ?? ["Asia/Calcutta", "America/Los_Angeles"] }
        set { UserDefaults.standard.set(newValue, forKey: "favoriteTimeZones") }
    }
    
    public var recentTimeZones: [String] {
        get { UserDefaults.standard.stringArray(forKey: "recentTimeZones") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "recentTimeZones") }
    }
    
    public func toggleFavorite(_ id: String) {
        var favs = favoriteTimeZones
        if let idx = favs.firstIndex(of: id) {
            favs.remove(at: idx)
        } else {
            favs.append(id)
        }
        favoriteTimeZones = favs
    }
    
    private func addToRecents(_ id: String) {
        var recs = recentTimeZones
        recs.removeAll(where: { $0 == id })
        recs.insert(id, at: 0)
        if recs.count > 20 { recs = Array(recs.prefix(20)) }
        recentTimeZones = recs
    }
    
    private func loadAllTimeZones() {
        let identifiers = TimeZone.knownTimeZoneIdentifiers
        self.allTimeZones = identifiers.map { TimeZoneModel(identifier: $0) }
            .sorted { $0.city < $1.city }
    }
    
    public var gmtOffsetString: String {
        let seconds = currentSystemTimeZone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs((seconds % 3600) / 60)
        let sign = hours >= 0 ? "+" : "-"
        return "GMT\(sign)\(abs(hours)):\(String(format: "%02d", minutes))"
    }
    
    public var utcOffsetString: String {
        let seconds = currentSystemTimeZone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs((seconds % 3600) / 60)
        let sign = hours >= 0 ? "+" : "-"
        return "UTC\(sign)\(String(format: "%02d", abs(hours))):\(String(format: "%02d", minutes))"
    }
    
    public var currentLocale: String {
        Locale.current.identifier
    }
    
    public var currentRegion: String {
        Locale.current.region?.identifier ?? "Unknown"
    }
    
    public var is24HourFormat: Bool {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let dateString = formatter.string(from: Date())
        let amSymbol = formatter.amSymbol ?? "AM"
        let pmSymbol = formatter.pmSymbol ?? "PM"
        return !dateString.contains(amSymbol) && !dateString.contains(pmSymbol)
    }
    
    public var macOSVersion: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
    }
    
    public var currentUser: String {
        NSUserName()
    }
    
    public var showSetupPrompt = false
    
    public func setSystemTimeZone(to identifier: String) {
        isSwitching = true
        errorMessage = nil
        showSetupPrompt = false
        
        let password = KeychainHelper.shared.getPassword()
        
        // If there's no password saved, immediately prompt the user
        if password == nil || password!.isEmpty {
            self.isSwitching = false
            self.showSetupPrompt = true
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            // Using systemsetup here instead of ln -sf to properly notify the macOS time daemon (timed) of the change!
            let command = "echo \"\(password!)\" | sudo -S systemsetup -settimezone \(identifier)"
            process.arguments = ["-c", command]
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                DispatchQueue.main.async {
                    self.isSwitching = false
                    if process.terminationStatus != 0 {
                        self.errorMessage = "Failed: \(errorString ?? "Unknown shell error")"
                        // If it fails, likely password was changed/wrong, so delete it and prompt again
                        KeychainHelper.shared.deletePassword()
                        self.showSetupPrompt = true
                    } else {
                        // Success
                        self.addToRecents(identifier)
                        self.lastSwitchedDate = Date()
                        self.refresh()
                        self.showSuccessNotification(for: identifier)
                        NotificationCenter.default.post(name: Notification.Name("ClosePopover"), object: nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSwitching = false
                    self.errorMessage = error.localizedDescription
                    self.showSetupPrompt = true
                }
            }
        }
    }
    
    private func showSuccessNotification(for identifier: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Timezone Switched Successfully"
            content.body = identifier == "Asia/Calcutta" ? "Switched to India (Asia/Calcutta)" : "Switched to America (America/Los_Angeles)"
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}

// MARK: - Keychain Helper
public class KeychainHelper {
    public static let shared = KeychainHelper()
    private let service = "com.jeevith.TimeZoneSwitcher"
    private let account = "sudoPassword"
    
    public func savePassword(_ password: String) -> Bool {
        let data = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    public func getPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    public func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
