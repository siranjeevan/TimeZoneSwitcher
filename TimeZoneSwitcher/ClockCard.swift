import SwiftUI

struct ClockCard: View {
    let model: TimeZoneModel
    let currentDate: Date
    let isActive: Bool
    
    @State private var isHovered = false
    
    private var timeZone: TimeZone? {
        TimeZone(identifier: model.id)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        if let timeZone { formatter.timeZone = timeZone }
        return formatter.string(from: currentDate)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        if let timeZone { formatter.timeZone = timeZone }
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: City and UTC Offset
            HStack {
                Text("\(model.city.uppercased())")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                    .lineLimit(1)
                
                Spacer()
                
                Text(model.gmtOffset)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
            }
            
            // Time Display
            Text(formattedTime)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isActive ?
                    AnyShapeStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ) :
                    AnyShapeStyle(Color.primary.opacity(0.75))
                )
                .contentTransition(.numericText())
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Footer: Date & Active Indicator
            HStack {
                Text(formattedDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 2)
                        
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    isActive ?
                    AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color(NSColor.windowBackgroundColor).opacity(0.55),
                                Color(NSColor.windowBackgroundColor).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) :
                    AnyShapeStyle(Color(NSColor.windowBackgroundColor).opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isActive ?
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.primary.opacity(0.06), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isActive ? 1.5 : 1.0
                        )
                )
        )
        .shadow(
            color: isActive ? Color.accentColor.opacity(0.06) : Color.black.opacity(0.02),
            radius: isActive ? 8 : 2,
            x: 0,
            y: isActive ? 4 : 1
        )
    }
}
