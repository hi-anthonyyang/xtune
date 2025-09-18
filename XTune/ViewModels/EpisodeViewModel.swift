import Foundation
import AVFoundation
import Combine

class EpisodeViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var currentlyPlayingEpisode: Episode?
    
    private let episodeScheduler = EpisodeScheduler()
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    var episodes: [Episode] {
        episodeScheduler.episodes
    }
    
    // MARK: - Navigation Properties
    
    var mostRecentEpisode: Episode? {
        episodeScheduler.getMostRecentEpisode()
    }
    
    var canPlayPrevious: Bool {
        guard let currentEpisode = currentlyPlayingEpisode else { return false }
        return episodeScheduler.getPreviousEpisode(relativeTo: currentEpisode) != nil
    }
    
    var canPlayNext: Bool {
        guard let currentEpisode = currentlyPlayingEpisode else { return false }
        return episodeScheduler.getNextEpisode(relativeTo: currentEpisode) != nil
    }
    
    init() {
        setupAudioSession()
        setupBindings()
    }
    
    deinit {
        cleanupPlayer()
    }
    
    // MARK: - Public Methods
    
    func selectEpisode(_ episode: Episode) {
        // Stop playback if another episode is tapped
        if currentlyPlayingEpisode?.id != episode.id {
            stopPlayback()
        }
    }
    
    func playOrPause(episode: Episode) {
        if currentlyPlayingEpisode?.id == episode.id && isPlaying {
            pausePlayback()
        } else {
            startPlayback(episode: episode)
        }
    }
    
    /// Plays the most recent available episode
    func playMostRecent() {
        guard let episode = mostRecentEpisode else {
            generateNewEpisode()
            return
        }
        
        startPlayback(episode: episode)
    }
    
    /// Plays the previous episode in chronological order
    func playPrevious() {
        guard let currentEpisode = currentlyPlayingEpisode,
              let previousEpisode = episodeScheduler.getPreviousEpisode(relativeTo: currentEpisode) else {
            return
        }
        
        startPlayback(episode: previousEpisode)
    }
    
    /// Plays the next episode in chronological order, or generates a new one if needed
    func playNext() {
        guard let currentEpisode = currentlyPlayingEpisode else {
            playMostRecent()
            return
        }
        
        if let nextEpisode = episodeScheduler.getNextEpisode(relativeTo: currentEpisode) {
            startPlayback(episode: nextEpisode)
        } else {
            generateNewEpisode()
        }
    }
    
    func playPause() {
        if isPlaying {
            pausePlayback()
        } else {
            playMostRecent()
        }
    }
    
    func generateNewEpisode() {
        isGenerating = true
        Task {
            if let newEpisode = await episodeScheduler.generateNewEpisode() {
                await MainActor.run {
                    self.currentlyPlayingEpisode = newEpisode
                    self.isGenerating = false
                    startPlayback(episode: newEpisode)
                }
            } else {
                await MainActor.run {
                    self.isGenerating = false
                    self.errorMessage = "Failed to generate new episode."
                }
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        currentTime = time
    }
    
    func refreshEpisodes() {
        // This is now handled by the playNext/playPrevious logic
    }
    
    func clearCacheAndRefresh() {
        episodeScheduler.clearCache()
        refreshEpisodes()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupBindings() {
        episodeScheduler.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                self?.objectWillChange.send()
                if self?.currentlyPlayingEpisode == nil {
                    self?.currentlyPlayingEpisode = self?.mostRecentEpisode
                }
            }
            .store(in: &cancellables)
    }
    
    private func startPlayback(episode: Episode) {
        guard let audioURL = episode.audioURL else {
            errorMessage = "Audio not available"
            return
        }
        
        print("🎵 Starting playback for URL: \(audioURL)")
        
        // Handle mock URLs
        if audioURL.scheme == "mock" {
            errorMessage = "Demo mode: Start the TTS server for real audio"
            print("💡 This is a mock URL. To get real audio:")
            print("   1. Open Terminal")
            print("   2. cd /path/to/xtune")
            print("   3. source tts_env/bin/activate")
            print("   4. python simple_tts_server.py")
            print("   5. Generate a new episode in the app")
            return
        }
        
        // Handle https URLs that might be unreachable
        if audioURL.scheme == "https" && audioURL.host == "example.com" {
            errorMessage = "Demo mode: Start the TTS server for real audio"
            print("💡 This is a demo URL. To get real audio, start the TTS server.")
            return
        }
        
        cleanupPlayer()
        
        // Set the currently playing episode
        currentlyPlayingEpisode = episode
        
        let playerItem = AVPlayerItem(url: audioURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player status
        player?.currentItem?.publisher(for: \.status)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        print("✅ AVPlayer ready to play")
                        self?.player?.play()
                        self?.isPlaying = true
                        self?.setupTimeObserver()
                        self?.errorMessage = nil
                    case .failed:
                        print("❌ AVPlayer failed to load audio")
                        if let error = self?.player?.currentItem?.error {
                            print("❌ Player error: \(error)")
                        }
                        self?.errorMessage = "Failed to load audio. Check if TTS server is running."
                        self?.isPlaying = false
                    default:
                        print("⏳ AVPlayer status: \(status)")
                        break
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe playback completion
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    print("🏁 Playback completed")
                    self?.stopPlayback()
                }
            }
            .store(in: &cancellables)
    }
    

    
    private func pausePlayback() {
        player?.pause()
        isPlaying = false
    }
    
    private func stopPlayback() {
        player?.pause()
        isPlaying = false
        currentTime = 0
        duration = 0
        currentlyPlayingEpisode = nil
        cleanupPlayer()
    }
    
    private func setupTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.1, preferredTimescale: timeScale)
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            let currentSeconds = time.seconds
            if currentSeconds.isFinite && currentSeconds >= 0 {
                self?.currentTime = currentSeconds
            }
            
            if let duration = self?.player?.currentItem?.duration {
                let durationSeconds = duration.seconds
                if durationSeconds.isFinite && durationSeconds > 0 {
                    self?.duration = durationSeconds
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player = nil
        currentTime = 0
        duration = 0
    }
}

// MARK: - Helper Extensions
extension EpisodeViewModel {
    var playbackProgress: Double {
        guard duration > 0, currentTime >= 0, duration.isFinite, currentTime.isFinite else { return 0 }
        let progress = currentTime / duration
        return min(1.0, max(0.0, progress))
    }
    
    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 