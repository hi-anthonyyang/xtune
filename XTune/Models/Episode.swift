import Foundation

struct Episode: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let audioURL: URL?
    let duration: TimeInterval
    let timestamp: Date
    let isGenerated: Bool
    let tweets: [Tweet]
}

// MARK: - Mock Data
extension Episode {
    static var mockEpisodes: [Episode] {
        return [] // Mock data is now generated dynamically
    }
}

// MARK: - Helper Extensions
extension Episode {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var isAvailable: Bool {
        return isGenerated && audioURL != nil
    }
    
    var statusText: String {
        if isAvailable {
            return "Ready to play"
        } else if isGenerated {
            return "Processing..."
        } else {
            return "Generation failed"
        }
    }
    
    // MARK: - Chronological Navigation Support
    
    /// Returns true if this episode is more recent than the other
    func isMoreRecentThan(_ other: Episode) -> Bool {
        return timestamp > other.timestamp
    }
    
    /// Returns true if this episode is older than the other
    func isOlderThan(_ other: Episode) -> Bool {
        return timestamp < other.timestamp
    }
    
    /// Returns true if episodes are from the same time
    func isSameTimeAs(_ other: Episode) -> Bool {
        return timestamp == other.timestamp
    }
} 