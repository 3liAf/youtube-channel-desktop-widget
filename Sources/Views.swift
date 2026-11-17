import SwiftUI

public struct PopoverView: View {
    @ObservedObject var fetcher: ChannelFetcher
    var onToggleDesktopWidget: () -> Void
    var onQuit: () -> Void
    
    public init(fetcher: ChannelFetcher, onToggleDesktopWidget: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.fetcher = fetcher
        self.onToggleDesktopWidget = onToggleDesktopWidget
        self.onQuit = onQuit
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation & Account Switcher Bar
            HStack(spacing: 8) {
                if fetcher.isShowingSettings {
                    Button(action: { fetcher.isShowingSettings = false }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Settings & Accounts")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { fetcher.isShowingSettings = false }) {
                        Text("Done")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Account Selector Menu
                    Menu {
                        Section("YouTube Accounts") {
                            ForEach(fetcher.channels) { channel in
                                Button(action: {
                                    fetcher.selectChannel(id: channel.id)
                                }) {
                                    HStack {
                                        Text(channel.title.isEmpty ? channel.handle : channel.title)
                                        if !fetcher.isCombinedView && fetcher.selectedChannelId == channel.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            fetcher.setCombinedView(true)
                        }) {
                            HStack {
                                Text("🌟 All Accounts (Combined)")
                                if fetcher.isCombinedView {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            fetcher.isShowingSettings = true
                        }) {
                            Label("Settings & Add Accounts...", systemImage: "gearshape")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if fetcher.isCombinedView {
                                Image(systemName: "rectangle.stack.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                Text("All Accounts")
                                    .font(.system(size: 13, weight: .bold))
                            } else if let active = fetcher.activeChannel {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                Text(active.title.isEmpty ? active.handle : active.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                            } else {
                                Text("Select Channel")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .frame(maxWidth: 210, alignment: .leading)
                    
                    Spacer()
                    
                    // Refresh Button
                    Button(action: {
                        Task {
                            await fetcher.refreshAll()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .rotationEffect(.degrees(fetcher.isGlobalRefreshing ? 360 : 0))
                            .animation(fetcher.isGlobalRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: fetcher.isGlobalRefreshing)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh All Accounts")
                    
                    // Desktop Widget Toggle
                    Button(action: onToggleDesktopWidget) {
                        Image(systemName: fetcher.showFloatingDesktopWidget ? "macwindow.badge.plus" : "macwindow")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(fetcher.showFloatingDesktopWidget ? .red : .primary)
                    }
                    .buttonStyle(.plain)
                    .help(fetcher.showFloatingDesktopWidget ? "Hide Desktop Widget" : "Show Desktop Widget")
                    
                    // Settings Gear Button
                    Button(action: { fetcher.isShowingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings & Accounts")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            Divider()
            
            // Body Content
            if fetcher.isShowingSettings {
                SettingsView(fetcher: fetcher, onDone: { fetcher.isShowingSettings = false })
            } else if fetcher.isCombinedView {
                ScrollView(.vertical, showsIndicators: false) {
                    CombinedStatsView(fetcher: fetcher, onSelectChannel: { id in
                        fetcher.selectChannel(id: id)
                    })
                    .padding(16)
                }
                .frame(maxHeight: 400)
            } else if let active = fetcher.activeChannel {
                SingleChannelView(
                    stats: active,
                    fetcher: fetcher,
                    onToggleDesktopWidget: onToggleDesktopWidget
                )
                .padding(16)
            } else {
                VStack(spacing: 12) {
                    Text("No channel configured.")
                        .foregroundColor(.secondary)
                    Button("Open Settings") {
                        fetcher.isShowingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(30)
            }
            
            Divider()
            
            // Footer
            HStack {
                let lastDate = fetcher.isCombinedView ? fetcher.combinedStats.lastUpdated : (fetcher.activeChannel?.lastUpdated ?? Date())
                Text("Updated \(timeFormatted(lastDate))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Single Channel View

public struct SingleChannelView: View {
    let stats: ChannelStats
    @ObservedObject var fetcher: ChannelFetcher
    var onToggleDesktopWidget: () -> Void
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header Identity
            HStack(spacing: 12) {
                if let avatar = stats.avatarURL, let url = URL(string: avatar) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            Circle()
                                .fill(Color.red.opacity(0.85))
                                .overlay(Image(systemName: "play.fill").foregroundColor(.white))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                    .shadow(radius: 2)
                } else {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "play.fill").foregroundColor(.white))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(stats.title)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    Text(stats.handle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await fetcher.refreshSingle(id: stats.id)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(stats.isLoading ? 360 : 0))
                        .animation(stats.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: stats.isLoading)
                }
                .buttonStyle(.plain)
                .help("Refresh this channel")
            }
            
            // Stat Cards Grid
            HStack(spacing: 10) {
                StatCard(
                    title: "Subscribers",
                    value: stats.subscribersText
                        .replacingOccurrences(of: " subscriber", with: "")
                        .replacingOccurrences(of: "s", with: ""),
                    icon: "person.2.fill",
                    color: Color.red
                )
                
                StatCard(
                    title: "Total Videos",
                    value: stats.videosText
                        .replacingOccurrences(of: " videos", with: "")
                        .replacingOccurrences(of: " video", with: ""),
                    icon: "film.stack.fill",
                    color: Color.orange
                )
            }
            
            // Milestone Tracker
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Goal: \(formatNumber(stats.nextMilestone)) Subs")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(stats.milestoneProgress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
                
                ProgressView(value: stats.milestoneProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 5)
                
                Text(stats.remainingToMilestone > 0 ? "\(formatNumber(stats.remainingToMilestone)) more to reach next milestone!" : "Milestone reached! 🎉")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Action Links
            HStack(spacing: 8) {
                if let url = URL(string: "https://www.youtube.com/\(stats.handle)") {
                    Link(destination: url) {
                        Label("Channel", systemImage: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                if !stats.channelId.isEmpty, let studioUrl = URL(string: "https://studio.youtube.com/channel/\(stats.channelId)") {
                    Link(destination: studioUrl) {
                        Label("Studio", systemImage: "chart.bar.xaxis")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Button(action: onToggleDesktopWidget) {
                    Label(fetcher.showFloatingDesktopWidget ? "Hide Widget" : "Desktop Widget", systemImage: "macwindow")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Combined Stats View

public struct CombinedStatsView: View {
    @ObservedObject var fetcher: ChannelFetcher
    var onSelectChannel: (UUID) -> Void
    
    public var body: some View {
        VStack(spacing: 14) {
            // Network Overview Banner
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Multi-Channel Network")
                        .font(.system(size: 14, weight: .bold))
                    Text("\(fetcher.channels.count) Connected YouTube Accounts")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Total Stats Grid
            HStack(spacing: 10) {
                StatCard(
                    title: "Combined Subs",
                    value: fetcher.combinedStats.formattedSubscribers,
                    icon: "person.3.sequence.fill",
                    color: Color.red
                )
                
                StatCard(
                    title: "Combined Videos",
                    value: fetcher.combinedStats.formattedVideos,
                    icon: "film.stack.fill",
                    color: Color.orange
                )
            }
            
            // Combined Milestone
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Total Goal: \(formatNumber(fetcher.combinedStats.nextMilestone)) Subs")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(Int(fetcher.combinedStats.milestoneProgress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
                
                ProgressView(value: fetcher.combinedStats.milestoneProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 5)
                
                Text(fetcher.combinedStats.remainingToMilestone > 0 ? "\(formatNumber(fetcher.combinedStats.remainingToMilestone)) more to combined milestone" : "Milestone reached! 🎉")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Account Breakdown Header
            HStack {
                Text("Channel Breakdown")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 4)
            
            // Channel List Rows
            VStack(spacing: 8) {
                ForEach(fetcher.channels) { ch in
                    Button(action: {
                        onSelectChannel(ch.id)
                    }) {
                        HStack(spacing: 10) {
                            if let avatar = ch.avatarURL, let url = URL(string: avatar) {
                                AsyncImage(url: url) { phase in
                                    if let img = phase.image {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(Color.red.opacity(0.8))
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                    .overlay(Image(systemName: "play.fill").font(.system(size: 11)).foregroundColor(.white))
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ch.title.isEmpty ? ch.handle : ch.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(ch.handle)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(ch.subscribersText.replacingOccurrences(of: " subscriber", with: "").replacingOccurrences(of: "s", with: ""))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                Text(ch.videosText.replacingOccurrences(of: " videos", with: "").replacingOccurrences(of: " video", with: ""))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Settings & Configuration View

public struct SettingsView: View {
    @ObservedObject var fetcher: ChannelFetcher
    var onDone: () -> Void
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Section 1: Add New Account
                VStack(alignment: .leading, spacing: 10) {
                    Label("Add YouTube Account", systemImage: "person.badge.plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        TextField("@handle or youtube.com/@...", text: Binding(
                            get: { fetcher.newHandleInput },
                            set: { fetcher.newHandleInput = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .onSubmit {
                            Task {
                                await fetcher.addCurrentInput()
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await fetcher.addCurrentInput()
                            }
                        }) {
                            if fetcher.isAddingAccount {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Add")
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(fetcher.newHandleInput.trimmingCharacters(in: .whitespaces).isEmpty || fetcher.isAddingAccount)
                    }
                    
                    if let msg = fetcher.addAccountMessage {
                        Text(msg)
                            .font(.system(size: 11))
                            .foregroundColor(fetcher.addAccountError ? .red : .green)
                    } else {
                        Text("Enter any channel handle (e.g. @MrBeast, @BrandItQuiz) or channel URL.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                
                // Section 2: Manage Existing Accounts
                VStack(alignment: .leading, spacing: 10) {
                    Label("Configured Accounts (\(fetcher.channels.count))", systemImage: "list.bullet.rectangle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 6) {
                        ForEach(fetcher.channels) { ch in
                            HStack(spacing: 8) {
                                if let avatar = ch.avatarURL, let url = URL(string: avatar) {
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image {
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Circle().fill(Color.red.opacity(0.8))
                                        }
                                    }
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.red.opacity(0.8))
                                        .frame(width: 28, height: 28)
                                        .overlay(Image(systemName: "play.fill").font(.system(size: 9)).foregroundColor(.white))
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(ch.title.isEmpty ? ch.handle : ch.title)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(ch.handle)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if fetcher.selectedChannelId == ch.id && !fetcher.isCombinedView {
                                    Text("Active")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                } else {
                                    Button("Set Active") {
                                        fetcher.selectChannel(id: ch.id)
                                    }
                                    .font(.system(size: 9))
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                                
                                if fetcher.channels.count > 1 {
                                    Button(action: {
                                        fetcher.removeChannel(id: ch.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.red.opacity(0.85))
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove account")
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                
                // Section 3: Menu Bar Display Settings
                VStack(alignment: .leading, spacing: 10) {
                    Label("Menu Bar Display", systemImage: "menubar.rectangle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Display Format:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: Binding(
                            get: { fetcher.menuBarMode },
                            set: { fetcher.setMenuBarMode($0) }
                        )) {
                            ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 180)
                    }
                    
                    Divider()
                    
                    Toggle("Show channel handle in menu bar", isOn: Binding(
                        get: { fetcher.showHandleInMenuBar },
                        set: { fetcher.setShowHandleInMenuBar($0) }
                    ))
                    .font(.system(size: 11))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                
                // Section 4: Refresh Interval
                VStack(alignment: .leading, spacing: 10) {
                    Label("Auto-Refresh Frequency", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Update Interval:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: Binding(
                            get: { fetcher.refreshIntervalMinutes },
                            set: { fetcher.setRefreshInterval($0) }
                        )) {
                            Text("2 Minutes").tag(2)
                            Text("5 Minutes").tag(5)
                            Text("15 Minutes").tag(15)
                            Text("30 Minutes").tag(30)
                            Text("1 Hour").tag(60)
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 160)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                
                // Section 5: Desktop Widget Preference
                VStack(alignment: .leading, spacing: 10) {
                    Label("Desktop Floating Widget", systemImage: "macwindow")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Widget Data Source:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: Binding(
                            get: { fetcher.desktopWidgetMode },
                            set: { fetcher.setDesktopWidgetMode($0) }
                        )) {
                            Text("Active Channel").tag(DesktopWidgetMode.activeChannel)
                            Text("Combined (All Accounts)").tag(DesktopWidgetMode.combinedTotal)
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 180)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(16)
        }
        .frame(width: 360, height: 400)
    }
}

// MARK: - Reusable Stat Card

public struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Desktop Floating Widget

public struct DesktopWidgetView: View {
    @ObservedObject var fetcher: ChannelFetcher
    var onClose: () -> Void
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header with drag handle and close
            HStack(spacing: 10) {
                if fetcher.desktopWidgetMode == .combinedTotal {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Combined Network")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(fetcher.channels.count) Accounts")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                } else if let active = fetcher.activeChannel {
                    if let avatar = active.avatarURL, let url = URL(string: avatar) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "play.rectangle.fill").foregroundColor(.red)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(active.title.isEmpty ? active.handle : active.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(active.handle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            // Numbers row
            if fetcher.desktopWidgetMode == .combinedTotal {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fetcher.combinedStats.formattedSubscribers)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.red)
                        Text("Total Subs")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(fetcher.combinedStats.formattedVideos)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                        Text("Total Videos")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Mini milestone bar
                ProgressView(value: fetcher.combinedStats.milestoneProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 3)
            } else if let active = fetcher.activeChannel {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(active.subscribersText.replacingOccurrences(of: " subscriber", with: "").replacingOccurrences(of: "s", with: ""))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.red)
                        Text("Subscribers")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(active.videosText.replacingOccurrences(of: " videos", with: "").replacingOccurrences(of: " video", with: ""))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                        Text("Videos")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Mini milestone bar
                ProgressView(value: active.milestoneProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 3)
            }
        }
        .padding(14)
        .frame(width: 230)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Number Formatting Helper

public func formatNumber(_ num: Int) -> String {
    let d = Double(num)
    if num >= 1_000_000_000 {
        return String(format: "%.1fB", d / 1_000_000_000.0).replacingOccurrences(of: ".0B", with: "B")
    } else if num >= 1_000_000 {
        return String(format: "%.1fM", d / 1_000_000.0).replacingOccurrences(of: ".0M", with: "M")
    } else if num >= 1_000 {
        return String(format: "%.1fK", d / 1_000.0).replacingOccurrences(of: ".0K", with: "K")
    } else {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}
