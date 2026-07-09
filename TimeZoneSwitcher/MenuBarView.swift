import SwiftUI

struct MenuBarView: View {
    @Bindable var timeManager = TimeZoneManager.shared
    @State private var clockManager = ClockManager.shared
    @State private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(manager: timeManager)
                .padding()
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Favorites Section
                    if !timeManager.favoriteTimeZones.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("⭐ Favorites")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(timeManager.favoriteTimeZones, id: \.self) { id in
                                        if let model = timeManager.allTimeZones.first(where: { $0.id == id }) {
                                            ClockCard(
                                                model: model,
                                                currentDate: clockManager.currentDate,
                                                isActive: timeManager.currentSystemTimeZone.identifier == model.id
                                            )
                                            .onTapGesture {
                                                timeManager.setSystemTimeZone(to: model.id)
                                            }
                                            .contextMenu {
                                                Button(timeManager.favoriteTimeZones.contains(model.id) ? "Unpin" : "Pin") {
                                                    timeManager.toggleFavorite(model.id)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    
                    // Recents Section
                    if !timeManager.recentTimeZones.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(timeManager.recentTimeZones.prefix(5), id: \.self) { id in
                                        if let model = timeManager.allTimeZones.first(where: { $0.id == id }) {
                                            ClockCard(
                                                model: model,
                                                currentDate: clockManager.currentDate,
                                                isActive: timeManager.currentSystemTimeZone.identifier == model.id
                                            )
                                            .onTapGesture {
                                                timeManager.setSystemTimeZone(to: model.id)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    
                    // Search Bar
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search City, Country, or Timezone...", text: $timeManager.searchQuery)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Search Results List
                        VStack(spacing: 0) {
                            ForEach(timeManager.filteredTimeZones.prefix(20)) { tz in
                                HStack {
                                    Text(tz.flag)
                                        .font(.system(size: 16))
                                    VStack(alignment: .leading) {
                                        Text(tz.city)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                        Text(tz.id)
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    if timeManager.favoriteTimeZones.contains(tz.id) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 10))
                                            .padding(.trailing, 4)
                                    }
                                    
                                    Text(tz.gmtOffset)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(4)
                                        .background(Color.primary.opacity(0.06))
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    timeManager.setSystemTimeZone(to: tz.id)
                                }
                                .contextMenu {
                                    Button(timeManager.favoriteTimeZones.contains(tz.id) ? "Unpin" : "Pin") {
                                        timeManager.toggleFavorite(tz.id)
                                    }
                                }
                                
                                Divider()
                                    .padding(.leading, 40)
                                    .opacity(0.5)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            // Footer
            FooterView(settings: settings)
                .padding()
        }
        .frame(width: 550, height: 650)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .preferredColorScheme(settings.theme.colorScheme)
        .overlay {
            if timeManager.showSetupPrompt {
                SetupView(manager: timeManager)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: timeManager.showSetupPrompt)
    }
}

// MARK: - Header
struct HeaderView: View {
    let manager: TimeZoneManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🌍 TimeZone Switcher")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                
                HStack {
                    Text("Current:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(manager.currentSystemTimeZone.identifier)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            Button(action: {
                manager.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Footer
struct FooterView: View {
    @Bindable var settings: SettingsManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("System: \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(AppTheme.allCases) { theme in
                    Button(action: {
                        settings.theme = theme
                    }) {
                        Text(theme.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                settings.theme == theme ? Color.primary.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(6)
            
            Button(action: {
                exit(0)
            }) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Setup View
struct SetupView: View {
    @Bindable var manager: TimeZoneManager
    @State private var password = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = NSApp.applicationIconImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            } else {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text("First-Time Setup")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Text("To instantly switch timezones in the background, TimeZone Switcher requires your Mac password once. It is securely encrypted in your Apple Keychain and never transmitted.")
                    .font(.system(size: 11, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Password for \(NSUserName())")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                
                SecureField("Enter Mac Password", text: $password)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .onSubmit {
                        saveAndAuthenticate()
                    }
            }
            .padding(.horizontal, 30)
            
            if let error = manager.errorMessage {
                Text(error)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    manager.showSetupPrompt = false
                    manager.errorMessage = nil
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(8)
                
                Button(action: {
                    saveAndAuthenticate()
                }) {
                    Text("Save & Authenticate")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(password.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(password.isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .popover, blendingMode: .withinWindow)
                .ignoresSafeArea()
        )
        .onAppear {
            isFocused = true
        }
    }
    
    private func saveAndAuthenticate() {
        guard !password.isEmpty else { return }
        _ = KeychainHelper.shared.savePassword(password)
        manager.showSetupPrompt = false
    }
}

// Helper to provide native visual effect blur in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
