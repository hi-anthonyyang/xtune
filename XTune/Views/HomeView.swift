import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = EpisodeViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView(viewModel: viewModel)
                
                if let episode = viewModel.currentlyPlayingEpisode {
                    PlayerView(episode: episode, viewModel: viewModel)
                } else {
                    EmptyPlayerView(viewModel: viewModel)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

struct PlayerView: View {
    let episode: Episode
    @ObservedObject var viewModel: EpisodeViewModel
    
    var body: some View {
        VStack {
            EpisodeCard(episode: episode, viewModel: viewModel)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct EmptyPlayerView: View {
    @ObservedObject var viewModel: EpisodeViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Generating your briefing...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: {
                    viewModel.generateNewEpisode()
                }) {
                    Text("Brief Me")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            
            Spacer()
        }
    }
}

struct HeaderView: View {
    @ObservedObject var viewModel: EpisodeViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("XTune")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your daily briefings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Currently Playing Indicator (moved up to replace buttons)
            }
            
            // Currently Playing Indicator
            if let currentEpisode = viewModel.currentlyPlayingEpisode {
                HStack {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                    
                    Text("Now Playing: \(currentEpisode.title)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if viewModel.isPlaying {
                        Text("Playing")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

struct TimelineView: View {
    @ObservedObject var viewModel: EpisodeViewModel
    
    var sortedEpisodes: [Episode] {
        return viewModel.episodes.sorted { $0.isMoreRecentThan($1) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if sortedEpisodes.isEmpty {
                    EmptyTimelineView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                } else {
                    ForEach(sortedEpisodes) { episode in
                        EpisodeCard(episode: episode, viewModel: viewModel)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 100) // Extra padding for audio player
        }
        .refreshable {
            viewModel.refreshEpisodes()
        }
    }
}

struct EmptyTimelineView: View {
    @ObservedObject var viewModel: EpisodeViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Episodes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Tap 'Brief Me' to generate your first AI-powered news briefing")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.generateNewEpisode()
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.headline)
                    }
                    
                    Text("Brief Me")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .disabled(viewModel.isLoading)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

struct TweetSourcesView: View {
    let tweets: [Tweet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tweet Sources")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(tweets) { tweet in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tweet.author)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(tweet.authorHandle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(tweet.text)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.light)
        
        HomeView()
            .preferredColorScheme(.dark)
    }
} 