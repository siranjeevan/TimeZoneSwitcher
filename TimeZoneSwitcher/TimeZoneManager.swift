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
    public let region: String
    public let gmtOffset: String
    public let rawOffset: Int
    public let searchTerms: String
    
    public init(identifier: String) {
        self.id = identifier
        let friendly = FriendlyTimeZoneMapper.shared.getLocation(for: identifier)
        self.city = friendly.city
        self.country = friendly.country
        self.flag = friendly.flag
        self.region = friendly.region
        
        let tz = TimeZone(identifier: identifier) ?? TimeZone.current
        let seconds = tz.secondsFromGMT()
        self.rawOffset = seconds
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        let offsetStr = String(format: "UTC%+d:%02d", hours, minutes)
        self.gmtOffset = offsetStr
        
        var terms = [friendly.country, friendly.city, identifier, offsetStr, offsetStr.replacingOccurrences(of: "UTC", with: "GMT")]
        terms.append(contentsOf: friendly.aliases)
        self.searchTerms = terms.joined(separator: " ").lowercased()
    }
    
    public func matchScore(for query: String) -> Int {
        let exactTerms = searchTerms.split(separator: " ").map { String($0) }
        if exactTerms.contains(query) { return 100 }
        if city.lowercased() == query { return 90 }
        if city.lowercased().hasPrefix(query) { return 80 }
        if country.lowercased() == query { return 70 }
        if country.lowercased().hasPrefix(query) { return 60 }
        return 0
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
    
    public var popularTimeZones: [TimeZoneModel] {
        FriendlyTimeZoneMapper.shared.popularIdentifiers.compactMap { id in
            allTimeZones.first(where: { $0.id == id })
        }
    }
    
    public var regions: [String] {
        ["Africa", "America", "Asia", "Europe", "Australia", "Pacific", "Indian", "Atlantic", "Antarctica", "Standard Time"]
    }
    
    public func timeZones(for region: String) -> [TimeZoneModel] {
        allTimeZones.filter { $0.region == region }
    }
    
    public var filteredTimeZones: [TimeZoneModel] {
        if searchQuery.isEmpty {
            return allTimeZones
        }
        let q = searchQuery.lowercased().trimmingCharacters(in: .whitespaces)
        
        let filtered = allTimeZones.filter { tz in
            tz.city.lowercased().contains(q) ||
            tz.country.lowercased().contains(q) ||
            tz.id.lowercased().contains(q) ||
            tz.searchTerms.contains(q)
        }
        
        return filtered.sorted { tz1, tz2 in
            let score1 = tz1.matchScore(for: q)
            let score2 = tz2.matchScore(for: q)
            if score1 != score2 { return score1 > score2 }
            return tz1.city < tz2.city
        }
    }
    
    public var favoriteTimeZones: [String] = UserDefaults.standard.stringArray(forKey: "favoriteTimeZones") ?? ["Asia/Calcutta", "America/Los_Angeles"] {
        didSet {
            UserDefaults.standard.set(favoriteTimeZones, forKey: "favoriteTimeZones")
        }
    }
    
    public var recentTimeZones: [String] = UserDefaults.standard.stringArray(forKey: "recentTimeZones") ?? [] {
        didSet {
            UserDefaults.standard.set(recentTimeZones, forKey: "recentTimeZones")
        }
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
    
    public enum MoveDirection {
        case left, right
    }
    
    public func moveFavorite(_ id: String, direction: MoveDirection) {
        var favs = favoriteTimeZones
        guard let index = favs.firstIndex(of: id) else { return }
        switch direction {
        case .left:
            if index > 0 {
                favs.swapAt(index, index - 1)
            }
        case .right:
            if index < favs.count - 1 {
                favs.swapAt(index, index + 1)
            }
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
import Foundation

public struct FriendlyLocation {
    public let country: String
    public let city: String
    public let flag: String
    public let region: String
    public let aliases: [String]
}

public class FriendlyTimeZoneMapper {
    public static let shared = FriendlyTimeZoneMapper()
    
    // Explicit mappings for the requested popular timezones
    public let popularMappings: [String: FriendlyLocation] = [
        "America/Los_Angeles": FriendlyLocation(country: "United States", city: "Los Angeles", flag: "🇺🇸", region: "America", aliases: ["USA", "California", "PST", "PDT", "Pacific Time"]),
        "America/New_York": FriendlyLocation(country: "United States", city: "New York", flag: "🇺🇸", region: "America", aliases: ["USA", "EST", "EDT", "Eastern Time"]),
        "America/Chicago": FriendlyLocation(country: "United States", city: "Chicago", flag: "🇺🇸", region: "America", aliases: ["USA", "CST", "CDT", "Central Time"]),
        "America/Phoenix": FriendlyLocation(country: "United States", city: "Phoenix", flag: "🇺🇸", region: "America", aliases: ["USA", "MST", "Mountain Time"]),
        "America/Toronto": FriendlyLocation(country: "Canada", city: "Toronto", flag: "🇨🇦", region: "America", aliases: ["EST", "EDT", "Eastern Time"]),
        "Europe/London": FriendlyLocation(country: "United Kingdom", city: "London", flag: "🇬🇧", region: "Europe", aliases: ["UK", "Britain", "England", "GMT", "BST"]),
        "Europe/Paris": FriendlyLocation(country: "France", city: "Paris", flag: "🇫🇷", region: "Europe", aliases: ["CET", "CEST"]),
        "Europe/Berlin": FriendlyLocation(country: "Germany", city: "Berlin", flag: "🇩🇪", region: "Europe", aliases: ["CET", "CEST"]),
        "Europe/Rome": FriendlyLocation(country: "Italy", city: "Rome", flag: "🇮🇹", region: "Europe", aliases: ["CET", "CEST"]),
        "Europe/Madrid": FriendlyLocation(country: "Spain", city: "Madrid", flag: "🇪🇸", region: "Europe", aliases: ["CET", "CEST"]),
        "Asia/Dubai": FriendlyLocation(country: "United Arab Emirates", city: "Dubai", flag: "🇦🇪", region: "Asia", aliases: ["UAE", "Gulf Standard Time"]),
        "Asia/Singapore": FriendlyLocation(country: "Singapore", city: "Singapore", flag: "🇸🇬", region: "Asia", aliases: ["SGT"]),
        "Asia/Tokyo": FriendlyLocation(country: "Japan", city: "Tokyo", flag: "🇯🇵", region: "Asia", aliases: ["JST", "JP"]),
        "Asia/Seoul": FriendlyLocation(country: "South Korea", city: "Seoul", flag: "🇰🇷", region: "Asia", aliases: ["KST", "Korea", "KR"]),
        "Australia/Sydney": FriendlyLocation(country: "Australia", city: "Sydney", flag: "🇦🇺", region: "Australia", aliases: ["AEST", "AEDT", "AU"]),
        "Asia/Calcutta": FriendlyLocation(country: "India", city: "New Delhi", flag: "🇮🇳", region: "Asia", aliases: ["IST", "Mumbai", "Kolkata", "IN", "Bharat"]),
        "Asia/Kolkata": FriendlyLocation(country: "India", city: "New Delhi", flag: "🇮🇳", region: "Asia", aliases: ["IST", "Mumbai", "Calcutta", "IN", "Bharat"]),
        "Asia/Hong_Kong": FriendlyLocation(country: "Hong Kong", city: "Hong Kong", flag: "🇭🇰", region: "Asia", aliases: ["HKT"]),
        "Asia/Shanghai": FriendlyLocation(country: "China", city: "Shanghai", flag: "🇨🇳", region: "Asia", aliases: ["CST", "Beijing", "CN"])
    ]
    
    public let popularIdentifiers: [String] = [
        "America/New_York", "America/Los_Angeles", "America/Chicago", "America/Phoenix", "America/Toronto",
        "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Rome", "Europe/Madrid",
        "Asia/Dubai", "Asia/Singapore", "Asia/Tokyo", "Asia/Seoul", "Australia/Sydney",
        "Asia/Calcutta", "Asia/Hong_Kong", "Asia/Shanghai"
    ]
    
    // Country flag mapping for procedural generation
    let countryToFlag: [String: String] = [
        "United States": "🇺🇸", "Canada": "🇨🇦", "United Kingdom": "🇬🇧", "France": "🇫🇷",
        "Germany": "🇩🇪", "Italy": "🇮🇹", "Spain": "🇪🇸", "Japan": "🇯🇵", "China": "🇨🇳",
        "India": "🇮🇳", "Australia": "🇦🇺", "Brazil": "🇧🇷", "Mexico": "🇲🇽", "Russia": "🇷🇺",
        "South Korea": "🇰🇷", "Singapore": "🇸🇬", "United Arab Emirates": "🇦🇪"
    ]
    
    public func getLocation(for identifier: String) -> FriendlyLocation {
        if let explicit = popularMappings[identifier] {
            return explicit
        }
        
        let components = identifier.split(separator: "/")
        let regionRaw = components.first.map(String.init) ?? "Unknown"
        let cityRaw = components.last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        
        let country = resolveCountry(region: regionRaw, city: cityRaw)
        let flag = countryToFlag[country] ?? getContinentFlag(region: regionRaw)
        
        return FriendlyLocation(
            country: country,
            city: cityRaw,
            flag: flag,
            region: regionRaw,
            aliases: []
        )
    }
    
    private func getContinentFlag(region: String) -> String {
        switch region {
        case "America", "US": return "🌎"
        case "Europe": return "🇪🇺"
        case "Asia": return "🌏"
        case "Australia": return "🇦🇺"
        case "Africa": return "🌍"
        case "Pacific": return "🏝️"
        case "Indian": return "🌊"
        case "Atlantic": return "🌊"
        case "Antarctica": return "🐧"
        case "GMT", "Etc": return "⏱️"
        default: return "🌐"
        }
    }
    
    private func resolveCountry(region: String, city: String) -> String {
        if region == "America" { return "Americas" }
        if region == "Etc" || region == "GMT" { return "Standard Time" }
        return region
    }
}
