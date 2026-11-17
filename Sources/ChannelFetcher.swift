import Foundation
import Combine

public enum MenuBarDisplayMode: String, Codable, CaseIterable {
    case activeChannel = "Active Channel"
    case combinedTotal = "Combined (All Accounts)"
    case compact = "Compact Count"
    case iconOnly = "Icon Only"
}

public enum DesktopWidgetMode: String, Codable, CaseIterable {
    case activeChannel = "Active Channel"
    case combinedTotal = "Combined (All Accounts)"
}

public struct ChannelStats: Identifiable, Codable, Equatable {
    public var id: UUID
    public var handle: String
    public var title: String
    public var channelId: String
    public var subscribersText: String
    public var subscriberCount: Int
    public var videosText: String
    public var videoCount: Int
    public var avatarURL: String?
    public var lastUpdated: Date
    public var isLoading: Bool
    public var errorMessage: String?
    
    public init(
        id: UUID = UUID(),
        handle: String = "@BrandItQuiz",
        title: String = "BrandIt",
        channelId: String = "UCGxLUVCSm111wtkU97R7hrw",
        subscribersText: String = "1 subscriber",
        subscriberCount: Int = 1,
        videosText: String = "46 videos",
        videoCount: Int = 46,
        avatarURL: String? = "https://yt3.googleusercontent.com/DcLhn9Zmm9S6qGMKf3_FU_7rUWSxiH8-KwivFtmiEZiw6V9aUntxqEJaIOvZ3SlEa0Fg3xYhiQ=s176-c-k-c0x00ffffff-no-rj",
        lastUpdated: Date = Date(),
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.handle = handle
        self.title = title
        self.channelId = channelId
        self.subscribersText = subscribersText
        self.subscriberCount = subscriberCount
        self.videosText = videosText
        self.videoCount = videoCount
        self.avatarURL = avatarURL
        self.lastUpdated = lastUpdated
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    
    public var shortName: String {
        if !title.isEmpty {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.components(separatedBy: " ")
            if let first = parts.first, !first.isEmpty && first.count <= 10 {
                return first
            }
            return String(trimmed.prefix(8))
        }
        let h = handle.replacingOccurrences(of: "@", with: "")
        if h.lowercased().hasSuffix("quiz") && h.count > 4 {
            return String(h.dropLast(4))
        }
        return h
    }
    
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
        if count < 500000 { return 500000 }
        if count < 1000000 { return 1000000 }
        let step = 1000000
        return ((count / step) + 1) * step
    }
    
    public var milestoneProgress: Double {
        guard nextMilestone > 0 else { return 0 }
        return min(1.0, max(0.0, Double(subscriberCount) / Double(nextMilestone)))
    }
    
    public var remainingToMilestone: Int {
        max(0, nextMilestone - subscriberCount)
    }
}

public struct CombinedStats: Equatable {
    public var totalSubscribers: Int = 0
    public var totalVideos: Int = 0
    public var channelCount: Int = 0
    public var lastUpdated: Date = Date()
    
    public var formattedSubscribers: String {
        formatCount(totalSubscribers)
    }
    
    public var formattedVideos: String {
        formatCount(totalVideos)
    }
    
    public var nextMilestone: Int {
        let count = totalSubscribers
        if count < 10 { return 10 }
        if count < 50 { return 50 }
        if count < 100 { return 100 }
        if count < 500 { return 500 }
        if count < 1000 { return 1000 }
        if count < 5000 { return 5000 }
        if count < 10000 { return 10000 }
        if count < 50000 { return 50000 }
        if count < 100000 { return 100000 }
        if count < 500000 { return 500000 }
        if count < 1000000 { return 1000000 }
        let step = 1000000
        return ((count / step) + 1) * step
    }
    
    public var milestoneProgress: Double {
        guard nextMilestone > 0 else { return 0 }
        return min(1.0, max(0.0, Double(totalSubscribers) / Double(nextMilestone)))
    }
    
    public var remainingToMilestone: Int {
        max(0, nextMilestone - totalSubscribers)
    }
    
    private func formatCount(_ num: Int) -> String {
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
}

private struct AppPersistedData: Codable {
    var channels: [ChannelStats]
    var selectedChannelId: UUID?
    var isCombinedView: Bool
    var menuBarMode: MenuBarDisplayMode
    var showHandleInMenuBar: Bool
    var refreshIntervalMinutes: Int
    var desktopWidgetMode: DesktopWidgetMode
}

@MainActor
public class ChannelFetcher: ObservableObject {
    @Published public var channels: [ChannelStats] = []
    @Published public var selectedChannelId: UUID? = nil
    @Published public var isCombinedView: Bool = false
    @Published public var menuBarMode: MenuBarDisplayMode = .activeChannel
    @Published public var showHandleInMenuBar: Bool = true
    @Published public var refreshIntervalMinutes: Int = 15
    @Published public var desktopWidgetMode: DesktopWidgetMode = .activeChannel
    @Published public var showFloatingDesktopWidget: Bool = false
    @Published public var isGlobalRefreshing: Bool = false
    
    // UI state published here (avoids Swift macro compiler issues)
    @Published public var isShowingSettings: Bool = false
    @Published public var newHandleInput: String = ""
    @Published public var isAddingAccount: Bool = false
    @Published public var addAccountMessage: String? = nil
    @Published public var addAccountError: Bool = false
    
    private var timer: Timer?
    private let storageKey = "BrandItStats_Preferences_v2"
    
    public init() {
        loadSettings()
        startTimer()
        Task {
            await refreshAll()
        }
    }
    
    public var activeChannel: ChannelStats? {
        if let id = selectedChannelId, let found = channels.first(where: { $0.id == id }) {
            return found
        }
        return channels.first
    }
    
    public var combinedStats: CombinedStats {
        var totalSubs = 0
        var totalVids = 0
        var latestDate = Date.distantPast
        
        for ch in channels {
            totalSubs += ch.subscriberCount
            totalVids += ch.videoCount
            if ch.lastUpdated > latestDate {
                latestDate = ch.lastUpdated
            }
        }
        
        return CombinedStats(
            totalSubscribers: totalSubs,
            totalVideos: totalVids,
            channelCount: channels.count,
            lastUpdated: latestDate == Date.distantPast ? Date() : latestDate
        )
    }
    
    public func startTimer() {
        timer?.invalidate()
        let interval = TimeInterval(max(2, refreshIntervalMinutes) * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshAll()
            }
        }
    }
    
    public func setRefreshInterval(_ minutes: Int) {
        refreshIntervalMinutes = minutes
        saveSettings()
        startTimer()
    }
    
    public func setMenuBarMode(_ mode: MenuBarDisplayMode) {
        menuBarMode = mode
        saveSettings()
    }
    
    public func setDesktopWidgetMode(_ mode: DesktopWidgetMode) {
        desktopWidgetMode = mode
        saveSettings()
    }
    
    public func setShowHandleInMenuBar(_ show: Bool) {
        showHandleInMenuBar = show
        saveSettings()
    }
    
    public func selectChannel(id: UUID?) {
        selectedChannelId = id
        isCombinedView = (id == nil)
        saveSettings()
    }
    
    public func setCombinedView(_ enabled: Bool) {
        isCombinedView = enabled
        if enabled {
            selectedChannelId = nil
        } else if selectedChannelId == nil {
            selectedChannelId = channels.first?.id
        }
        saveSettings()
    }
    
    public func addCurrentInput() async {
        let text = newHandleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isAddingAccount = true
        addAccountMessage = nil
        addAccountError = false
        
        let result = await addChannel(rawInput: text)
        isAddingAccount = false
        addAccountMessage = result.message
        addAccountError = !result.success
        if result.success {
            newHandleInput = ""
        }
    }
    
    public func addChannel(rawInput: String) async -> (success: Bool, message: String) {
        let path = cleanPathInput(rawInput)
        guard !path.isEmpty else {
            return (false, "Please enter a valid channel handle, URL, or Channel ID.")
        }
        
        if channels.contains(where: { $0.handle.lowercased() == path.lowercased() || $0.channelId == path }) {
            return (false, "Channel is already in your list.")
        }
        
        var newStats = ChannelStats(
            id: UUID(),
            handle: path,
            title: path,
            channelId: "",
            subscribersText: "Loading...",
            subscriberCount: 0,
            videosText: "Loading...",
            videoCount: 0,
            avatarURL: nil,
            isLoading: true
        )
        
        do {
            let fetched = try await fetchChannelData(handleOrPath: path)
            newStats.title = fetched.title
            newStats.channelId = fetched.channelId
            newStats.handle = fetched.handle
            newStats.subscribersText = fetched.subscribersText
            newStats.subscriberCount = fetched.subscriberCount
            newStats.videosText = fetched.videosText
            newStats.videoCount = fetched.videoCount
            newStats.avatarURL = fetched.avatarURL
            newStats.lastUpdated = Date()
            newStats.isLoading = false
            newStats.errorMessage = nil
            
            // Check again in case canonical handle matched existing
            if channels.contains(where: { $0.handle.lowercased() == newStats.handle.lowercased() }) {
                return (false, "Account \(newStats.handle) is already in your list.")
            }
            
            channels.append(newStats)
            selectedChannelId = newStats.id
            isCombinedView = false
            saveSettings()
            return (true, "Added \(newStats.title) (\(newStats.handle)) successfully!")
        } catch {
            return (false, "Could not find YouTube channel: \(error.localizedDescription)")
        }
    }
    
    public func removeChannel(id: UUID) {
        guard channels.count > 1 else { return } // Keep at least one channel
        channels.removeAll(where: { $0.id == id })
        if selectedChannelId == id {
            selectedChannelId = channels.first?.id
        }
        saveSettings()
    }
    
    public func refreshAll() async {
        guard !isGlobalRefreshing else { return }
        isGlobalRefreshing = true
        
        for i in 0..<channels.count {
            let ch = channels[i]
            channels[i].isLoading = true
            do {
                let fetched = try await fetchChannelData(handleOrPath: ch.handle.isEmpty ? ch.channelId : ch.handle)
                channels[i].title = fetched.title
                channels[i].channelId = fetched.channelId.isEmpty ? channels[i].channelId : fetched.channelId
                if !fetched.handle.isEmpty {
                    channels[i].handle = fetched.handle
                }
                channels[i].subscribersText = fetched.subscribersText
                channels[i].subscriberCount = fetched.subscriberCount
                channels[i].videosText = fetched.videosText
                channels[i].videoCount = fetched.videoCount
                channels[i].avatarURL = fetched.avatarURL ?? channels[i].avatarURL
                channels[i].lastUpdated = Date()
                channels[i].isLoading = false
                channels[i].errorMessage = nil
            } catch {
                channels[i].isLoading = false
                channels[i].errorMessage = error.localizedDescription
            }
        }
        
        isGlobalRefreshing = false
        saveSettings()
    }
    
    public func refreshSingle(id: UUID) async {
        guard let idx = channels.firstIndex(where: { $0.id == id }) else { return }
        channels[idx].isLoading = true
        do {
            let ch = channels[idx]
            let fetched = try await fetchChannelData(handleOrPath: ch.handle.isEmpty ? ch.channelId : ch.handle)
            channels[idx].title = fetched.title
            channels[idx].channelId = fetched.channelId.isEmpty ? channels[idx].channelId : fetched.channelId
            if !fetched.handle.isEmpty {
                channels[idx].handle = fetched.handle
            }
            channels[idx].subscribersText = fetched.subscribersText
            channels[idx].subscriberCount = fetched.subscriberCount
            channels[idx].videosText = fetched.videosText
            channels[idx].videoCount = fetched.videoCount
            channels[idx].avatarURL = fetched.avatarURL ?? channels[idx].avatarURL
            channels[idx].lastUpdated = Date()
            channels[idx].isLoading = false
            channels[idx].errorMessage = nil
        } catch {
            channels[idx].isLoading = false
            channels[idx].errorMessage = error.localizedDescription
        }
        saveSettings()
    }
    
    // MARK: - Scraping Engine
    
    private func fetchChannelData(handleOrPath: String) async throws -> (title: String, channelId: String, handle: String, subscribersText: String, subscriberCount: Int, videosText: String, videoCount: Int, avatarURL: String?) {
        let cleanPath = cleanPathInput(handleOrPath)
        guard let url = URL(string: "https://www.youtube.com/\(cleanPath)?cbrd=1&ucbcb=1") else {
            throw NSError(domain: "BrandItStats", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for handle"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("SOCS=CAESEwgDEgk2OTU0MjI0MTMaAmVuIAEaBgiA_LyaBg;", forHTTPHeaderField: "Cookie")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 404 {
            throw NSError(domain: "BrandItStats", code: 404, userInfo: [NSLocalizedDescriptionKey: "YouTube channel not found"])
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "BrandItStats", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not read YouTube page response"])
        }
        
        var parsedTitle: String = cleanPath
        var parsedChannelId: String = ""
        var parsedHandle: String = cleanPath.hasPrefix("@") ? cleanPath : ""
        var parsedSubscribersText: String = "0 subscribers"
        var parsedSubscriberCount: Int = 0
        var parsedVideosText: String = "0 videos"
        var parsedVideoCount: Int = 0
        var parsedAvatarURL: String? = nil
        
        // Strategy 1: JSON parse ytInitialData
        if let jsonRange = html.range(of: "var ytInitialData = ") {
            let afterJson = html[jsonRange.upperBound...]
            if let endRange = afterJson.range(of: "};</script>") {
                let jsonString = String(afterJson[..<endRange.lowerBound]) + "}"
                if let jsonData = jsonString.data(using: .utf8),
                   let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    // Metadata
                    if let meta = root["metadata"] as? [String: Any],
                       let channelMeta = meta["channelMetadataRenderer"] as? [String: Any] {
                        if let t = channelMeta["title"] as? String, !t.isEmpty {
                            parsedTitle = t
                        }
                        if let cid = channelMeta["externalId"] as? String, !cid.isEmpty {
                            parsedChannelId = cid
                        }
                        if let vanity = channelMeta["vanityChannelUrl"] as? String, let atIdx = vanity.range(of: "@") {
                            parsedHandle = String(vanity[atIdx.lowerBound...])
                        }
                    }
                    
                    // Page Header ViewModel (Modern YouTube layout)
                    if let header = root["header"] as? [String: Any],
                       let pageHeaderRenderer = header["pageHeaderRenderer"] as? [String: Any],
                       let content = pageHeaderRenderer["content"] as? [String: Any],
                       let vm = content["pageHeaderViewModel"] as? [String: Any] {
                        
                        // Title
                        if let titleObj = vm["title"] as? [String: Any],
                           let dtvm = titleObj["dynamicTextViewModel"] as? [String: Any],
                           let t = dtvm["text"] as? [String: Any],
                           let c = t["content"] as? String, !c.isEmpty {
                            parsedTitle = c
                        }
                        
                        // Metadata rows (handle, subs, vids)
                        if let metaObj = vm["metadata"] as? [String: Any],
                           let cmvm = metaObj["contentMetadataViewModel"] as? [String: Any],
                           let rows = cmvm["metadataRows"] as? [[String: Any]] {
                            for r in rows {
                                if let parts = r["metadataParts"] as? [[String: Any]] {
                                    for p in parts {
                                        if let textDict = p["text"] as? [String: Any],
                                           let contentStr = textDict["content"] as? String {
                                            let lower = contentStr.lowercased()
                                            if contentStr.hasPrefix("@") {
                                                parsedHandle = contentStr
                                            } else if lower.contains("sub") {
                                                parsedSubscribersText = contentStr
                                                parsedSubscriberCount = parseCount(contentStr)
                                            } else if lower.contains("vid") {
                                                parsedVideosText = contentStr
                                                parsedVideoCount = parseCount(contentStr)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Avatar image
                        if let imgObj = vm["image"] as? [String: Any],
                           let davm = imgObj["decoratedAvatarViewModel"] as? [String: Any],
                           let avm = davm["avatar"] as? [String: Any],
                           let innerAvm = avm["avatarViewModel"] as? [String: Any],
                           let img = innerAvm["image"] as? [String: Any],
                           let sources = img["sources"] as? [[String: Any]],
                           let lastSource = sources.last,
                           let urlStr = lastSource["url"] as? String {
                            parsedAvatarURL = urlStr
                        }
                    }
                }
            }
        }
        
        // Strategy 2: Regex fallbacks if JSON didn't catch everything
        if parsedSubscriberCount == 0 {
            if let subRegex = try? NSRegularExpression(pattern: "\"content\":\\s*\"([0-9.,]+[KkMmBb]?\\s+subscribers?)\""),
               let match = subRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let text = String(html[range])
                parsedSubscribersText = text
                parsedSubscriberCount = parseCount(text)
            }
        }
        
        if parsedVideoCount == 0 {
            if let vidRegex = try? NSRegularExpression(pattern: "\"content\":\\s*\"([0-9.,]+\\s+videos?)\""),
               let match = vidRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let text = String(html[range])
                parsedVideosText = text
                parsedVideoCount = parseCount(text)
            }
        }
        
        if parsedChannelId.isEmpty {
            if let idRegex = try? NSRegularExpression(pattern: "\"externalId\":\\s*\"([^\"]+)\""),
               let match = idRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                parsedChannelId = String(html[range])
            }
        }
        
        if parsedAvatarURL == nil {
            if let avRegex = try? NSRegularExpression(pattern: "\"avatar\":\\s*\\{[^}]*\"url\":\\s*\"(https://yt3\\.googleusercontent\\.com/[^\"]+)\""),
               let match = avRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                parsedAvatarURL = String(html[range])
            }
        }
        
        if parsedHandle.isEmpty {
            parsedHandle = cleanPath.hasPrefix("@") ? cleanPath : "@\(cleanPath)"
        }
        
        return (
            title: parsedTitle,
            channelId: parsedChannelId,
            handle: parsedHandle,
            subscribersText: parsedSubscribersText,
            subscriberCount: parsedSubscriberCount,
            videosText: parsedVideosText,
            videoCount: parsedVideoCount,
            avatarURL: parsedAvatarURL
        )
    }
    
    private func cleanPathInput(_ input: String) -> String {
        var str = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("https://") || str.hasPrefix("http://") || str.contains("youtube.com") {
            if let url = URL(string: str) {
                let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if path.hasPrefix("@") {
                    return path
                } else if path.hasPrefix("channel/") {
                    return path
                } else if !path.isEmpty {
                    str = path
                }
            }
        }
        if str.hasPrefix("UC") && str.count >= 20 {
            return "channel/\(str)"
        }
        if str.hasPrefix("channel/UC") {
            return str
        }
        if !str.hasPrefix("@") {
            str = "@" + str
        }
        return str
    }
    
    private func parseCount(_ text: String) -> Int {
        let lower = text.lowercased()
        let cleaned = lower.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        guard let num = Double(cleaned) else { return 0 }
        if lower.contains("b") {
            return Int(num * 1_000_000_000)
        } else if lower.contains("m") {
            return Int(num * 1_000_000)
        } else if lower.contains("k") {
            return Int(num * 1_000)
        }
        return Int(num)
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        let data = AppPersistedData(
            channels: channels,
            selectedChannelId: selectedChannelId,
            isCombinedView: isCombinedView,
            menuBarMode: menuBarMode,
            showHandleInMenuBar: showHandleInMenuBar,
            refreshIntervalMinutes: refreshIntervalMinutes,
            desktopWidgetMode: desktopWidgetMode
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadSettings() {
        if let saved = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppPersistedData.self, from: saved),
           !decoded.channels.isEmpty {
            self.channels = decoded.channels
            self.selectedChannelId = decoded.selectedChannelId ?? decoded.channels.first?.id
            self.isCombinedView = decoded.isCombinedView
            self.menuBarMode = decoded.menuBarMode
            self.showHandleInMenuBar = decoded.showHandleInMenuBar
            self.refreshIntervalMinutes = decoded.refreshIntervalMinutes
            self.desktopWidgetMode = decoded.desktopWidgetMode
        } else {
            // Seed BrandIt
            let brandIt = ChannelStats(
                id: UUID(),
                handle: "@BrandItQuiz",
                title: "BrandIt",
                channelId: "UCGxLUVCSm111wtkU97R7hrw",
                subscribersText: "1 subscriber",
                subscriberCount: 1,
                videosText: "46 videos",
                videoCount: 46,
                avatarURL: "https://yt3.googleusercontent.com/DcLhn9Zmm9S6qGMKf3_FU_7rUWSxiH8-KwivFtmiEZiw6V9aUntxqEJaIOvZ3SlEa0Fg3xYhiQ=s176-c-k-c0x00ffffff-no-rj"
            )
            self.channels = [brandIt]
            self.selectedChannelId = brandIt.id
            self.isCombinedView = false
            self.menuBarMode = .activeChannel
            self.showHandleInMenuBar = true
            self.refreshIntervalMinutes = 15
            self.desktopWidgetMode = .activeChannel
        }
        
        saveSettings()
    }
}
