import Foundation

struct Tweet: Codable, Identifiable {
    let id: String
    let text: String
    let author: String
    let authorHandle: String
    let createdAt: Date
    let likeCount: Int
    let retweetCount: Int
    let replyCount: Int
    let quoteCount: Int
    let category: TweetCategory
    let url: String?
    
    enum TweetCategory: String, Codable, CaseIterable {
        case news = "News"
        case tech = "Tech"
    }
}

// MARK: - Mock Data
extension Tweet {
    static let mockTweets: [Tweet] = [
        Tweet(
            id: UUID().uuidString,
            text: "Breaking: Major tech company announces revolutionary AI breakthrough that could change everything we know about machine learning.",
            author: "Tech Reporter",
            authorHandle: "@techreporter",
            createdAt: Date().addingTimeInterval(-3600),
            likeCount: 1250,
            retweetCount: 430,
            replyCount: 120,
            quoteCount: 50,
            category: .tech,
            url: "https://twitter.com/techreporter/status/1"
        ),
        Tweet(
            id: UUID().uuidString,
            text: "New study reveals breakthrough in quantum computing that could revolutionize data encryption and processing speeds.",
            author: "Science Journal",
            authorHandle: "@sciencejournal",
            createdAt: Date().addingTimeInterval(-7200),
            likeCount: 890,
            retweetCount: 234,
            replyCount: 80,
            quoteCount: 30,
            category: .tech,
            url: "https://twitter.com/sciencejournal/status/2"
        ),
        Tweet(
            id: UUID().uuidString,
            text: "World leaders gather for climate summit with unprecedented commitment to renewable energy transition.",
            author: "News Network",
            authorHandle: "@newsnetwork",
            createdAt: Date().addingTimeInterval(-1800),
            likeCount: 2100,
            retweetCount: 890,
            replyCount: 300,
            quoteCount: 120,
            category: .news,
            url: "https://twitter.com/newsnetwork/status/3"
        )
    ]
} 