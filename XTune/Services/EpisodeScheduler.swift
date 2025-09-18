import Foundation

class EpisodeScheduler: ObservableObject {
    @Published var episodes: [Episode] = []
    
    private let twitterService = TwitterService()
    private let podcastfyService = PodcastfyService()
    
    private var timer: Timer?
    
    init() {
        loadEpisodes()
        setupTimer()
        removeStaleEpisodes()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "SavedEpisodes")
        episodes = []
        print("🗑️ Cleared episode cache")
    }
    
    // MARK: - Navigation Methods
    
    /// Returns the most recent available episode
    func getMostRecentEpisode() -> Episode? {
        return episodes.sorted { $0.isMoreRecentThan($1) }.first
    }
    
    /// Returns all episodes sorted chronologically (newest first)
    func getAllEpisodesSorted() -> [Episode] {
        return episodes.sorted { $0.isMoreRecentThan($1) }
    }
    
    /// Returns the previous episode relative to the given episode
    func getPreviousEpisode(relativeTo episode: Episode) -> Episode? {
        let sortedEpisodes = getAllEpisodesSorted()
        guard let currentIndex = sortedEpisodes.firstIndex(where: { $0.id == episode.id }) else {
            return nil
        }
        
        let previousIndex = currentIndex + 1
        return previousIndex < sortedEpisodes.count ? sortedEpisodes[previousIndex] : nil
    }
    
    /// Returns the next episode relative to the given episode, or nil if none exists
    func getNextEpisode(relativeTo episode: Episode) -> Episode? {
        let sortedEpisodes = getAllEpisodesSorted()
        guard let currentIndex = sortedEpisodes.firstIndex(where: { $0.id == episode.id }) else {
            return nil
        }
        
        let nextIndex = currentIndex - 1
        return nextIndex >= 0 ? sortedEpisodes[nextIndex] : nil
    }
    
    func generateNewEpisode() async -> Episode? {
        do {
            // Fetch tweets from the last 6 hours
            let tweets = try await twitterService.fetchTweetsForTimeWindow(hours: 6)
            
            // Avoid generating duplicate episodes
            guard !isDuplicateContent(newTweets: tweets) else {
                print("🚫 Duplicate content detected, skipping generation.")
                return nil
            }
            
            // Generate podcast audio and script
            let (audioURL, duration, script) = try await podcastfyService.generatePodcast(from: tweets)
            
            // Create new episode
            let newEpisode = Episode(
                id: UUID().uuidString,
                title: getTitleForCurrentTime(),
                description: script,
                audioURL: audioURL,
                duration: duration,
                timestamp: Date(),
                isGenerated: true,
                tweets: tweets
            )
            
            // Update episodes array
            await MainActor.run {
                episodes.insert(newEpisode, at: 0)
                saveEpisodes()
            }
            return newEpisode
        } catch {
            print("Failed to generate new episode: \(error)")
            return nil
        }
    }
    
    func refreshAllEpisodes() async {
        // This method is no longer needed with the single timeline
    }
    
    // MARK: - Private Methods
    
    private func setupTimer() {
        // Check for new content every 30 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { _ in
            Task {
                await self.generateNewEpisode()
            }
        }
    }
    
    private func removeStaleEpisodes() {
        let sixHoursAgo = Date().addingTimeInterval(-6 * 60 * 60)
        episodes.removeAll { $0.timestamp < sixHoursAgo }
        saveEpisodes()
    }
    
    private func isDuplicateContent(newTweets: [Tweet]) -> Bool {
        guard let mostRecentEpisode = getMostRecentEpisode() else {
            return false
        }
        
        let recentTweetIDs = Set(mostRecentEpisode.tweets.map { $0.id })
        let newTweetIDs = Set(newTweets.map { $0.id })
        
        // If more than 50% of tweets are the same, consider it duplicate
        let intersection = recentTweetIDs.intersection(newTweetIDs)
        return Double(intersection.count) / Double(newTweetIDs.count) > 0.5
    }
    
    private func loadEpisodes() {
        // Load from UserDefaults or local storage
        if let data = UserDefaults.standard.data(forKey: "SavedEpisodes"),
           let savedEpisodes = try? JSONDecoder().decode([Episode].self, from: data) {
            let validEpisodes = savedEpisodes.filter { episode in
                // Keep episodes from the last 6 hours
                episode.timestamp > Date().addingTimeInterval(-6 * 60 * 60)
            }
            
            episodes = validEpisodes
            print("✅ Loaded \(validEpisodes.count) valid episodes from cache")
        }
    }
    
    private func saveEpisodes() {
        if let data = try? JSONEncoder().encode(episodes) {
            UserDefaults.standard.set(data, forKey: "SavedEpisodes")
        }
    }
    
    private func getTitleForCurrentTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if (1...6).contains(hour) { return "Early Morning Update" }
        if (7...12).contains(hour) { return "Morning Briefing" }
        if (13...18).contains(hour) { return "Afternoon Headlines" }
        return "Evening & Nightly News"
    }
    
    private func getDescriptionForCurrentTime() -> String {
        return "Your latest AI-powered news briefing, covering top stories from the last 6 hours."
    }
}

// MARK: - Helper Extensions
extension Calendar {
    func dateBySettingTimeZone(_ timeZone: TimeZone, of date: Date) -> Date? {
        let components = dateComponents(in: timeZone, from: date)
        return self.date(from: components)
    }
} 