import SwiftUI

struct SystemInfoView: View {
    let manager: TimeZoneManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DIAGNOSTICS & SYSTEM INFO")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
                
                Spacer()
                
                Image(systemName: "cpu")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                InfoRow(label: "macOS Version", value: manager.macOSVersion, icon: "macpro.gen3.fill")
                InfoRow(label: "Current User", value: manager.currentUser, icon: "person.crop.circle.fill")
                InfoRow(label: "Current Locale", value: manager.currentLocale, icon: "globe.badge.chevron.backward")
                InfoRow(label: "UTC Offset", value: manager.utcOffsetString, icon: "clock.fill")
                InfoRow(label: "Time Format", value: manager.is24HourFormat ? "24-Hour" : "12-Hour", icon: "calendar.badge.clock")
                InfoRow(label: "Last Switched", value: lastSwitchedString, icon: "arrow.triangle.2.circlepath")
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
        }
    }
    
    private var lastSwitchedString: String {
        guard let date = manager.lastSwitchedDate else {
            return "Never Switched"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(isHovered ? Color.accentColor : Color.secondary)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
