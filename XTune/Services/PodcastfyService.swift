import Foundation

private func getConfigValue(for key: String) -> String? {
    Bundle.main.infoDictionary?[key] as? String
}

class PodcastfyService: ObservableObject {
    // Option 1: Use local Python server (recommended for development)
    private let localServerURL = "http://127.0.0.1:5001"
    
    // Option 2: Use cloud Podcastfy API (for production)
    private let baseURL = "https://api.podcastfy.ai" // Replace with actual Podcastfy API endpoint
    // API key removed for security
    
    // Toggle between local server and cloud API
    private let useLocalServer = true // Set to false for production
    
    enum PodcastfyError: Error {
        case invalidURL
        case noData
        case decodingError
        case networkError(String)
        case authenticationError
        case generationFailed
        case serverNotRunning
    }
    
    struct PodcastfyRequest: Codable {
        let text: String
        let voice: String?
        let language: String?
        let duration: Int? // in seconds
        let style: String?
    }
    
    struct PodcastfyResponse: Codable {
        let success: Bool
        let message: String?
        let output: String?
        let error: String?
        let audioURL: String?
        let audioFile: String?
        let script: String?
        let duration: Double?
        let status: String?
        let jobId: String?
        let timestamp: String?
    }
    
    // MARK: - Public Methods
    
    func generatePodcast(from tweets: [Tweet]) async throws -> (URL, TimeInterval, String) {
        let summary = createSummary(from: tweets)
        
        if useLocalServer {
            return try await generatePodcastViaLocalServer(summary: summary)
        } else {
            return try await generatePodcastViaCloudAPI(summary: summary)
        }
    }
    
    // MARK: - Local Server Integration
    
    private func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(localServerURL)/health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Quick health check
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Check if server timestamp indicates a restart
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let timestamp = json["timestamp"] as? String {
                        checkServerRestart(timestamp: timestamp)
                    }
                    return true
                }
            }
        } catch {
            print("🔍 Server health check failed: \(error)")
        }
        
        return false
    }
    
    private func checkServerRestart(timestamp: String) {
        let key = "LastServerTimestamp"
        let lastTimestamp = UserDefaults.standard.string(forKey: key)
        
        if let lastTimestamp = lastTimestamp, lastTimestamp != timestamp {
            // Server restarted, clear episode cache
            print("🔄 Server restart detected, clearing episode cache")
            UserDefaults.standard.removeObject(forKey: "SavedEpisodes")
        }
        
        UserDefaults.standard.set(timestamp, forKey: key)
    }
    
    private func generatePodcastViaLocalServer(summary: String) async throws -> (URL, TimeInterval, String) {
        // First check if server is running
        let isServerHealthy = await checkServerHealth()
        if !isServerHealthy {
            print("⚠️  Local server is not running or not responding")
            print("💡 To start the server, run:")
            print("   cd /path/to/podcastfy")
            print("   source podcastfy_env/bin/activate")
            print("   python simple_tts_server.py")
            print("🔄 Using mock data instead")
            return try await generateMockPodcast(summary: summary)
        }
        
        guard let url = URL(string: "\(localServerURL)/generate-podcast") else {
            throw PodcastfyError.invalidURL
        }
        
        let request = PodcastfyRequest(
            text: summary,
            voice: nil,
            language: "en",
            duration: nil,
            style: "conversational"
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60.0 // Increase timeout for audio generation
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            print("📡 Sending request to local server: \(localServerURL)/generate-podcast")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PodcastfyError.networkError("Invalid response")
            }
            
            print("📡 Server response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let podcastfyResponse = try JSONDecoder().decode(PodcastfyResponse.self, from: data)
                
                if podcastfyResponse.success, let audioURLString = podcastfyResponse.audioURL {
                    print("✅ Audio generated successfully: \(audioURLString)")
                    guard let audioURL = URL(string: audioURLString) else {
                        throw PodcastfyError.invalidURL
                    }
                    let duration = podcastfyResponse.duration ?? 0.0
                    let script = podcastfyResponse.script ?? ""
                    return (audioURL, duration, script)
                } else {
                    print("❌ Server reported failure: \(podcastfyResponse.error ?? "Unknown error")")
                    throw PodcastfyError.generationFailed
                }
            } else {
                print("❌ Server returned status code: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ Server error response: \(errorData)")
                }
                throw PodcastfyError.serverNotRunning
            }
        } catch let error as PodcastfyError {
            throw error
        } catch {
            print("❌ Local server error: \(error)")
            print("🔄 Falling back to mock data")
            // Fallback to mock data if local server is not running
            return try await generateMockPodcast(summary: summary)
        }
    }
    
    // MARK: - Cloud API Integration
    
    private func generatePodcastViaCloudAPI(summary: String) async throws -> (URL, TimeInterval, String) {
        // This would be the production implementation
        // For now, fallback to mock data
        return try await generateMockPodcast(summary: summary)
    }
    
    func checkGenerationStatus(jobId: String) async throws -> PodcastfyResponse {
        let targetURL = useLocalServer ? localServerURL : baseURL
        guard let url = URL(string: "\(targetURL)/status/\(jobId)") else {
            throw PodcastfyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if !useLocalServer {
            // Authorization removed for security
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw PodcastfyError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            return try JSONDecoder().decode(PodcastfyResponse.self, from: data)
        } catch {
            throw PodcastfyError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    private func createSummary(from tweets: [Tweet]) -> String {
        let tweetSummaries = tweets.map { tweet in
            "From \(tweet.author): \(tweet.text)"
        }.joined(separator: "\n\n")
        
        return tweetSummaries
    }
    
    private func getGreetingForCurrentTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if (1...6).contains(hour) { return "Good morning! Here is your early update." }
        if (7...12).contains(hour) { return "Good morning! Welcome to your daily briefing." }
        if (13...18).contains(hour) { return "Good afternoon! Here's your midday update." }
        return "Good evening! Here is your nightly news wrap-up."
    }
    
    private func generateMockPodcast(summary: String) async throws -> (URL, TimeInterval, String) {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        print("🎭 Generating mock podcast for demo purposes")
        print("💡 To get real audio, start the TTS server:")
            print("   cd /path/to/xtune")
        print("   source tts_env/bin/activate")
        print("   python simple_tts_server.py")
        
        // Instead of creating corrupted WAV files, return a mock URL that the UI can handle gracefully
        let mockURLString = "mock://podcast/\(UUID().uuidString).mp3"
        guard let url = URL(string: mockURLString) else {
            throw PodcastfyError.invalidURL
        }
        
        let mockScript = "This is a mock script for testing purposes."
        print("✅ Created mock URL: \(mockURLString)")
        return (url, 300.0, mockScript) // Mock duration of 5 minutes
    }
} 