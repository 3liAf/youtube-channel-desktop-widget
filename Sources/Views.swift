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
        VStack(spacing: 16) {
            // Header: Channel Identity
            HStack(spacing: 12) {
                if let avatar = fetcher.stats.avatarURL, let url = URL(string: avatar) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            Image(systemName: "play.rectangle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.red)
                                .padding(8)
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
                        Text(fetcher.stats.title)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    Text(fetcher.stats.handle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await fetcher.refresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(fetcher.stats.isLoading ? 360 : 0))
                        .animation(fetcher.stats.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: fetcher.stats.isLoading)
                }
                .buttonStyle(.plain)
                .help("Refresh Stats")
            }
            .padding(.horizontal, 4)
            
            // Stat Cards Grid
            HStack(spacing: 10) {
                StatCard(
                    title: "Subscribers",
                    value: fetcher.stats.subscribersText.replacingOccurrences(of: " subscriber", with: "").replacingOccurrences(of: "s", with: ""),
                    icon: "person.2.fill",
                    color: Color.red
                )
                
                StatCard(
                    title: "Total Videos",
                    value: fetcher.stats.videosText.replacingOccurrences(of: " videos", with: "").replacingOccurrences(of: " video", with: ""),
                    icon: "film.stack.fill",
                    color: Color.orange
                )
            }
            
            // Milestone Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Goal: \(fetcher.stats.nextMilestone) Subscribers")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(fetcher.stats.milestoneProgress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
                
                ProgressView(value: fetcher.stats.milestoneProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 5)
                
                Text(fetcher.stats.remainingToMilestone > 0 ? "\(fetcher.stats.remainingToMilestone) more to reach your next milestone!" : "Milestone reached! 🎉")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 8) {
                Link(destination: URL(string: "https://www.youtube.com/\(fetcher.stats.handle)")!) {
                    Label("Channel", systemImage: "arrow.up.right.square")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Link(destination: URL(string: "https://studio.youtube.com/channel/\(fetcher.stats.channelId)")!) {
                    Label("Studio", systemImage: "chart.bar.xaxis")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    onToggleDesktopWidget()
                }) {
                    Label(fetcher.showFloatingDesktopWidget ? "Hide Widget" : "Desktop Widget", systemImage: "macwindow")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Footer
            HStack {
                Text("Updated \(timeFormatted(fetcher.stats.lastUpdated))")
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
            .padding(.top, 2)
        }
        .padding(16)
        .frame(width: 320)
    }
    
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

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
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }
}

public struct DesktopWidgetView: View {
    @ObservedObject var fetcher: ChannelFetcher
    var onClose: () -> Void
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header with drag handle and close
            HStack(spacing: 10) {
                if let avatar = fetcher.stats.avatarURL, let url = URL(string: avatar) {
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
                    Text(fetcher.stats.title)
                        .font(.system(size: 13, weight: .bold))
                    Text(fetcher.stats.handle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fetcher.stats.subscribersText.replacingOccurrences(of: " subscriber", with: "").replacingOccurrences(of: "s", with: ""))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.red)
                    Text("Subscribers")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(fetcher.stats.videosText.replacingOccurrences(of: " videos", with: "").replacingOccurrences(of: " video", with: ""))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.orange)
                    Text("Videos")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Mini milestone bar
            ProgressView(value: fetcher.stats.milestoneProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                .frame(height: 3)
        }
        .padding(14)
        .frame(width: 220)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
