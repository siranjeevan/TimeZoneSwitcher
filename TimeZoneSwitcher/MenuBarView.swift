import SwiftUI

enum NavigationDestination: Hashable {
    case region(String)
    case browseRegionsList
    case search
    case detail(String) // TimeZone ID
}

struct MenuBarView: View {
    @Bindable var timeManager = TimeZoneManager.shared
    @State private var clockManager = ClockManager.shared
    @State private var settings = SettingsManager.shared
    
    @State private var navPath = NavigationPath()
    @State private var localSearchQuery = ""
    
    // Command Palette focus
    @FocusState private var isSearchFocused: Bool
    
    @State private var hasMouseEntered = false
    @State private var dismissWorkItem: DispatchWorkItem? = nil
    
    var body: some View {
        NavigationStack(path: $navPath) {
            HomeView(
                manager: timeManager,
                clockManager: clockManager,
                settings: settings,
                navPath: $navPath,
                localSearchQuery: $localSearchQuery,
                isSearchFocused: _isSearchFocused
            )
            .navigationDestination(for: NavigationDestination.self) { dest in
                switch dest {
                case .region(let region):
                    RegionListView(
                        region: region,
                        manager: timeManager,
                        clockManager: clockManager,
                        navPath: $navPath
                    )
                    .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
                case .browseRegionsList:
                    BrowseRegionsListView(
                        manager: timeManager,
                        navPath: $navPath
                    )
                    .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
                case .search:
                    SearchListView(
                        manager: timeManager,
                        clockManager: clockManager,
                        navPath: $navPath,
                        query: $localSearchQuery,
                        isSearchFocused: _isSearchFocused
                    )
                    .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
                case .detail(let id):
                    if let model = timeManager.allTimeZones.first(where: { $0.id == id }) {
                        DetailView(
                            model: model,
                            manager: timeManager,
                            clockManager: clockManager,
                            navPath: $navPath
                        )
                        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
                    }
                }
            }
        }
        .frame(width: 500, height: 530)
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
        // Command Palette global listener within app
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.keyCode == 40 { // CMD+K
                    if navPath.isEmpty {
                        isSearchFocused = true
                    } else {
                        navPath.removeLast(navPath.count)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFocused = true
                        }
                    }
                    return nil // consume event
                }
                return event
            }
        }
        .onHover { hovering in
            if hovering {
                dismissWorkItem?.cancel()
                hasMouseEntered = true
            } else if hasMouseEntered {
                dismissWorkItem?.cancel()
                let work = DispatchWorkItem {
                    NotificationCenter.default.post(name: Notification.Name("ClosePopover"), object: nil)
                }
                dismissWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Bindable var manager: TimeZoneManager
    let clockManager: ClockManager
    @Bindable var settings: SettingsManager
    @Binding var navPath: NavigationPath
    @Binding var localSearchQuery: String
    @FocusState var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TimeZone Switcher")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Spacer()
                Button(action: { manager.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider().background(Color.primary.opacity(0.1))
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search City, Country, or Timezone (⌘K)...", text: $localSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .focused($isSearchFocused)
                    .onChange(of: localSearchQuery) { _ in
                        if !localSearchQuery.isEmpty {
                            manager.searchQuery = localSearchQuery
                            navPath.append(NavigationDestination.search)
                        }
                    }
            }
            .padding(10)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(8)
            .padding()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Pinned
                    if !manager.favoriteTimeZones.isEmpty {
                        SectionHeader(title: "Pinned")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(manager.favoriteTimeZones, id: \.self) { id in
                                    if let model = manager.allTimeZones.first(where: { $0.id == id }) {
                                        ClockCard(model: model, currentDate: clockManager.currentDate, isActive: manager.currentSystemTimeZone.identifier == model.id)
                                            .onTapGesture { navPath.append(NavigationDestination.detail(model.id)) }
                                            .contextMenu {
                                                Button("Unpin") { manager.toggleFavorite(model.id) }
                                                
                                                if manager.favoriteTimeZones.first != id {
                                                    Button("Move Left") { manager.moveFavorite(model.id, direction: .left) }
                                                }
                                                if manager.favoriteTimeZones.last != id {
                                                    Button("Move Right") { manager.moveFavorite(model.id, direction: .right) }
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }


                    // Browse By Region
                    Button(action: {
                        navPath.append(NavigationDestination.browseRegionsList)
                    }) {
                        HStack {
                            Text("Switch Region")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            
            Divider().background(Color.primary.opacity(0.1))
            FooterView(settings: settings, manager: manager)
        }
    }
}

// MARK: - Search List View
struct SearchListView: View {
    @Bindable var manager: TimeZoneManager
    let clockManager: ClockManager
    @Binding var navPath: NavigationPath
    @Binding var query: String
    @FocusState var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Button(action: {
                    query = ""
                    manager.searchQuery = ""
                    navPath.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                TextField("Search...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .focused($isSearchFocused)
                    .onChange(of: query) { _ in
                        manager.searchQuery = query
                    }
                
                if !query.isEmpty {
                    Button(action: {
                        query = ""
                        manager.searchQuery = ""
                        navPath.removeLast()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(8)
            .padding()
            
            Divider().background(Color.primary.opacity(0.1))
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(manager.filteredTimeZones.prefix(50)) { tz in
                        ListRow(model: tz, isCurrent: manager.currentSystemTimeZone.identifier == tz.id, navPath: $navPath)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            manager.searchQuery = query
        }
    }
}

// MARK: - Region List View
struct RegionListView: View {
    let region: String
    @Bindable var manager: TimeZoneManager
    let clockManager: ClockManager
    @Binding var navPath: NavigationPath
    
    @State private var searchQuery = ""
    
    private var filteredTimeZones: [TimeZoneModel] {
        let zones = manager.timeZones(for: region)
        if searchQuery.isEmpty {
            return zones
        }
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return zones.filter { zone in
            zone.city.lowercased().contains(query) ||
            zone.country.lowercased().contains(query) ||
            zone.id.lowercased().contains(query)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { navPath.removeLast() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                Text(region)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.left").opacity(0) // Balance
            }
            .padding()
            
            Divider().background(Color.primary.opacity(0.1))
            
            // Region Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search in \(region)...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider().background(Color.primary.opacity(0.1))
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(filteredTimeZones) { tz in
                        ListRow(model: tz, isCurrent: manager.currentSystemTimeZone.identifier == tz.id, navPath: $navPath)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Browse Regions List View
struct BrowseRegionsListView: View {
    @Bindable var manager: TimeZoneManager
    @Binding var navPath: NavigationPath
    
    @State private var searchQuery = ""
    
    private var filteredRegions: [String] {
        if searchQuery.isEmpty {
            return manager.regions
        }
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return manager.regions.filter { $0.lowercased().contains(query) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { navPath.removeLast() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                Text("Browse Regions")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.left").opacity(0)
            }
            .padding()
            
            Divider().background(Color.primary.opacity(0.1))
            
            // Search Regions Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search Regions...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider().background(Color.primary.opacity(0.1))
            
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredRegions, id: \.self) { region in
                        Button(action: {
                            navPath.append(NavigationDestination.region(region))
                        }) {
                            HStack {
                                Text(region)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Detail View
struct DetailView: View {
    let model: TimeZoneModel
    @Bindable var manager: TimeZoneManager
    let clockManager: ClockManager
    @Binding var navPath: NavigationPath
    
    private var timeZone: TimeZone {
        TimeZone(identifier: model.id) ?? TimeZone.current
    }
    
    private var isCurrent: Bool {
        manager.currentSystemTimeZone.identifier == model.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { navPath.removeLast() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { manager.toggleFavorite(model.id) }) {
                    Image(systemName: manager.favoriteTimeZones.contains(model.id) ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(manager.favoriteTimeZones.contains(model.id) ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Giant Clock
                    VStack(spacing: 8) {
                        Text("\(model.city.uppercased())")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(2)
                        
                        Text(formatter(for: "h:mm:ss a").string(from: clockManager.currentDate))
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundColor(isCurrent ? .green : .primary)
                        
                        Text(formatter(for: "EEEE, MMMM d, yyyy").string(from: clockManager.currentDate))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Stats Grid
                    VStack(spacing: 16) {
                        StatRow(title: "Country / Region", value: "\(model.country)")
                        StatRow(title: "UTC Offset", value: model.gmtOffset)
                        
                        let dstOffset = timeZone.daylightSavingTimeOffset(for: clockManager.currentDate)
                        StatRow(title: "Daylight Saving", value: dstOffset > 0 ? "Active (+\(Int(dstOffset/3600))h)" : "Not Active")
                        
                        let diff = (timeZone.secondsFromGMT() - manager.currentSystemTimeZone.secondsFromGMT()) / 3600
                        let diffStr = diff == 0 ? "Same Time" : (diff > 0 ? "\(diff) hours ahead" : "\(abs(diff)) hours behind")
                        StatRow(title: "Time Difference", value: diffStr)
                        
                        StatRow(title: "Timezone Identifier", value: model.id, isMonospaced: true)
                    }
                    .padding()
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                    
                    Spacer(minLength: 40)
                    
                    // Switch Button
                    Button(action: {
                        manager.setSystemTimeZone(to: model.id)
                    }) {
                        Text(isCurrent ? "Currently Active" : "Switch To This Timezone")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isCurrent ? Color.green : Color.accentColor)
                            .cornerRadius(12)
                            .shadow(color: (isCurrent ? Color.green : Color.accentColor).opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCurrent)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func formatter(for template: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = template
        f.timeZone = timeZone
        return f
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
}

struct ListRow: View {
    let model: TimeZoneModel
    let isCurrent: Bool
    @Binding var navPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Info block tap to navigate
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.city)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text(model.country)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(model.gmtOffset)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(6)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    navPath.append(NavigationDestination.detail(model.id))
                }
                
                // Pin button
                Button(action: {
                    TimeZoneManager.shared.toggleFavorite(model.id)
                }) {
                    Image(systemName: TimeZoneManager.shared.favoriteTimeZones.contains(model.id) ? "star.fill" : "star")
                        .foregroundColor(TimeZoneManager.shared.favoriteTimeZones.contains(model.id) ? .yellow : .secondary)
                        .font(.system(size: 13, weight: .bold))
                        .padding(6)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Switch / Active status
                if isCurrent {
                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(6)
                } else {
                    Button(action: {
                        TimeZoneManager.shared.setSystemTimeZone(to: model.id)
                    }) {
                        Text("Switch")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.accentColor)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            
            Divider().padding(.leading, 16).opacity(0.4)
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    var isMonospaced = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: isMonospaced ? .monospaced : .rounded))
        }
    }
}

// MARK: - Footer
struct FooterView: View {
    @Bindable var settings: SettingsManager
    let manager: TimeZoneManager
    
    var body: some View {
        HStack {
            Button(action: { /* TODO: Open settings */ }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { exit(0) }) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.02))
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

// MARK: - Setup View
struct SetupView: View {
    @Bindable var manager: TimeZoneManager
    @State private var password = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("First-Time Setup")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("To instantly switch timezones in the background, TimeZone Switcher requires your Mac password once.")
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                SecureField("Enter Mac Password", text: $password)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .onSubmit { saveAndAuthenticate() }
            }
            .padding(.horizontal, 30)
            
            if let error = manager.errorMessage {
                Text(error).font(.system(size: 10)).foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel") {
                    manager.showSetupPrompt = false
                    manager.errorMessage = nil
                }
                .buttonStyle(.plain)
                .padding()
                
                Button(action: saveAndAuthenticate) {
                    Text("Save & Authenticate")
                        .bold()
                        .padding()
                        .background(password.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(password.isEmpty)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow).ignoresSafeArea())
        .onAppear { isFocused = true }
    }
    
    private func saveAndAuthenticate() {
        guard !password.isEmpty else { return }
        _ = KeychainHelper.shared.savePassword(password)
        manager.showSetupPrompt = false
    }
}
