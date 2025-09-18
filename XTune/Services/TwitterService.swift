import Foundation

private func getConfigValue(_ key: String) -> String {
    Bundle.main.infoDictionary?[key] as? String ?? ""
}

class TwitterService: ObservableObject {
    // API keys removed for security
    
    private let baseURL = "https://api.twitter.com/2"
    
    enum TwitterError: Error {
        case invalidURL
        case noData
        case decodingError
        case networkError(String)
        case authenticationError
    }
    
    // MARK: - Public Methods
    
    func fetchTopTweets(for category: Tweet.TweetCategory, count: Int = 10) async throws -> [Tweet] {
        // For now, return mock data. In production, implement actual Twitter API calls
        return filterMockTweets(for: category, count: count)
    }
    
    func fetchTweetsForTimeWindow(hours: Int) async throws -> [Tweet] {
        let categories: [Tweet.TweetCategory] = [.news, .tech]
        var allTweets: [Tweet] = []
        
        for category in categories {
            let tweets = try await fetchTopTweets(for: category, count: 5)
            allTweets.append(contentsOf: tweets)
        }
        
        // Filter tweets from the last N hours
        let timeWindow = Date().addingTimeInterval(-Double(hours) * 60 * 60)
        let recentTweets = allTweets.filter { $0.createdAt > timeWindow }
        
        // Sort by normalized engagement score
        return recentTweets.sorted { $0.normalizedEngagementScore > $1.normalizedEngagementScore }
            .prefix(10)
            .map { $0 }
    }
    
    // MARK: - Private Methods
    
    private func filterMockTweets(for category: Tweet.TweetCategory, count: Int) -> [Tweet] {
        let filteredTweets = Tweet.mockTweets.filter { $0.category == category }
        return Array(filteredTweets.prefix(count))
    }
    
    private func buildSearchQuery(for category: Tweet.TweetCategory) -> String {
        switch category {
        case .news:
            return "breaking news OR headline OR urgent -is:retweet lang:en"
        case .tech:
            return "tech OR technology OR AI OR startup OR innovation -is:retweet lang:en"
        }
    }
    
    private func makeTwitterAPIRequest(endpoint: String, parameters: [String: String]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw TwitterError.invalidURL
        }
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let finalURL = urlComponents?.url else {
            throw TwitterError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        // Authorization removed for security
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw TwitterError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            return data
        } catch {
            throw TwitterError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Production Implementation (Commented Out)
/*
extension TwitterService {
    private func fetchTweetsFromAPI(for category: Tweet.TweetCategory, count: Int) async throws -> [Tweet] {
        let query = buildSearchQuery(for: category)
        let parameters = [
            "query": query,
            "max_results": "\(min(count, 100))",
            "tweet.fields": "created_at,author_id,public_metrics,context_annotations",
            "user.fields": "username,name",
            "expansions": "author_id"
        ]
        
        let data = try await makeTwitterAPIRequest(endpoint: "tweets/search/recent", parameters: parameters)
        
        // Parse the Twitter API response and convert to Tweet objects
        // This would involve parsing the JSON response and mapping it to our Tweet model
        return []
    }
}
*/

// Add helper extension for engagement score
extension Tweet {
    var engagementScore: Int {
        (likeCount * 1) + (retweetCount * 2) + (replyCount * 2) + (quoteCount * 2)
    }
    var normalizedEngagementScore: Double {
        let hoursSincePosted = max(1, Date().timeIntervalSince(createdAt) / 3600)
        return Double(engagementScore) / hoursSincePosted
    }
} 