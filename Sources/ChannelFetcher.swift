import Foundation
import Combine

public struct ChannelStats {
    public var title: String = "BrandIt"
    public var handle: String = "@BrandItQuiz"
    public var channelId: String = "UCGxLUVCSm111wtkU97R7hrw"
    public var subscribersText: String = "1 subscriber"
    public var subscriberCount: Int = 1
    public var videosText: String = "34 videos"
    public var videoCount: Int = 34
    public var avatarURL: String? = "https://yt3.googleusercontent.com/DcLhn9Zmm9S6qGMKf3_FU_7rUWSxiH8-KwivFtmiEZiw6V9aUntxqEJaIOvZ3SlEa0Fg3xYhiQ=s176-c-k-c0x00ffffff-no-rj"
    public var lastUpdated: Date = Date()
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    public var nextMilestone: Int {
        let count = subscriberCount
        if count < 10 { return 10 }
        if count < 50 { return 50 }
        if count < 100 { return 100 }
        if count < 500 { return 500 }
        if count < 1000 { return 1000 }
        if count < 5000 { return 5000 }
        if count < 10000 { return 10000 }
        if count < 50000 { return 50000 }
        if count < 100000 { return 100000 }
        let nextHundredK = ((count / 100000) + 1) * 100000
        return nextHundredK
    }
    
    public var milestoneProgress: Double {
        guard nextMilestone > 0 else { return 0 }
        return min(1.0, max(0.0, Double(subscriberCount) / Double(nextMilestone)))
    }
    
    public var remainingToMilestone: Int {
        max(0, nextMilestone - subscriberCount)
    }
}

@MainActor
public class ChannelFetcher: ObservableObject {
    @Published public var stats: ChannelStats = ChannelStats()
    @Published public var refreshIntervalMinutes: Int = 15
    @Published public var isCompactMenuBar: Bool = false
    @Published public var showFloatingDesktopWidget: Bool = false
    
    private var timer: Timer?
    
    public init() {
        startTimer()
        Task {
            await refresh()
        }
    }
    
    public func startTimer() {
        timer?.invalidate()
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
    
    public func setRefreshInterval(_ minutes: Int) {
        refreshIntervalMinutes = minutes
        startTimer()
    }
    
    public func refresh() async {
        guard !stats.isLoading else { return }
        stats.isLoading = true
        stats.errorMessage = nil
        
        let targetHandle = stats.handle.hasPrefix("@") ? stats.handle : "@\(stats.handle)"
        guard let url = URL(string: "https://www.youtube.com/\(targetHandle)?cbrd=1&ucbcb=1") else {
            stats.isLoading = false
            stats.errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("SOCS=CAESEwgDEgk2OTU0MjI0MTMaAmVuIAEaBgiA_LyaBg;", forHTTPHeaderField: "Cookie")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else {
                stats.isLoading = false
                stats.errorMessage = "Failed to decode response"
                return
            }
            
            // Extract subscriber count text
            let subRegex = try NSRegularExpression(pattern: "\"content\":\\s*\"([0-9.,]+[KkMmBb]?\\s+subscribers?)\"")
            if let match = subRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let text = String(html[range])
                stats.subscribersText = text
                stats.subscriberCount = parseCount(text)
            }
            
            // Extract video count text
            let vidRegex = try NSRegularExpression(pattern: "\"content\":\\s*\"([0-9.,]+\\s+videos?)\"")
            if let match = vidRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let text = String(html[range])
                stats.videosText = text
                stats.videoCount = parseCount(text)
            }
            
            // Channel ID
            let idRegex = try NSRegularExpression(pattern: "\"externalId\":\\s*\"([^\"]+)\"")
            if let match = idRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                stats.channelId = String(html[range])
            }
            
            // Channel Title
            let titleRegex = try NSRegularExpression(pattern: "\"channelMetadataRenderer\":\\s*\\{[^}]*\"title\":\\s*\"([^\"]+)\"")
            if let match = titleRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                stats.title = String(html[range])
            }
            
            // Avatar URL
            let avRegex = try NSRegularExpression(pattern: "\"avatar\":\\s*\\{[^}]*\"url\":\\s*\"(https://yt3\\.googleusercontent\\.com/[^\"]+)\"")
            if let match = avRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                stats.avatarURL = String(html[range])
            }
            
            stats.lastUpdated = Date()
            stats.isLoading = false
        } catch {
            stats.isLoading = false
            stats.errorMessage = error.localizedDescription
        }
    }
    
    private func parseCount(_ text: String) -> Int {
        let lower = text.lowercased()
        let cleaned = lower.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        guard let num = Double(cleaned) else { return 0 }
        if lower.contains("m") {
            return Int(num * 1_000_000)
        } else if lower.contains("k") {
            return Int(num * 1_000)
        } else if lower.contains("b") {
            return Int(num * 1_000_000_000)
        }
        return Int(num)
    }
}
