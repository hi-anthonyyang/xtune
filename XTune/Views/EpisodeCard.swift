import SwiftUI

struct EpisodeCard: View {
    let episode: Episode
    @ObservedObject var viewModel: EpisodeViewModel
    
    var isCurrentlyPlaying: Bool {
        viewModel.currentlyPlayingEpisode?.id == episode.id
    }
    
    var isRecent: Bool {
        // Episode is recent if generated within the last 2 hours
        return episode.timestamp > Date().addingTimeInterval(-2 * 60 * 60)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            descriptionSection
            
            // Conditionally show the full audio player or the simple play button
            if isCurrentlyPlaying {
                Divider()
                AudioPlayerView(viewModel: viewModel)
            } else {
                footerSection
            }
            
            if !episode.tweets.isEmpty {
                TweetSourcesView(tweets: episode.tweets)
            }
        }
        .padding(20)
        .background(cardBackground)
        .shadow(
            color: isCurrentlyPlaying ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
            radius: isCurrentlyPlaying ? 8 : 4,
            x: 0,
            y: 2
        )
        .onTapGesture {
            viewModel.selectEpisode(episode)
        }
    }
    
    private var headerSection: some View {
        HStack {
            iconSection
            titleSection
            Spacer()
            StatusBadge(episode: episode, isCurrentlyPlaying: isCurrentlyPlaying)
        }
    }
    
    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 32, height: 32)
            
            Image(systemName: "mic.fill")
                .font(.title2)
                .foregroundColor(.primary)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(episode.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                if isRecent {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                Text(episode.timestamp, style: .relative)
                Text("ago")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var descriptionSection: some View {
        Text(episode.description)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    private var footerSection: some View {
        HStack {
            Text(formatDuration(episode.duration))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            playButton
        }
    }
    
    private var playButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.playOrPause(episode: episode)
            }
        }) {
            playButtonContent
        }
        .disabled(playButtonDisabled)
    }
    
    private var playButtonContent: some View {
        HStack(spacing: 4) {
            playButtonIcon
            playButtonText
        }
        .foregroundColor(playButtonTextColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(playButtonBackground)
    }
    
    private var playButtonIcon: some View {
        Group {
            if viewModel.isLoading && viewModel.currentlyPlayingEpisode?.id == episode.id {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: episode.isAvailable ? .white : .primary))
            } else {
                let iconName = isCurrentlyPlaying && viewModel.isPlaying ? "pause.fill" : "play.fill"
                Image(systemName: iconName)
                    .font(.caption)
            }
        }
    }
    
    private var playButtonText: some View {
        Text(buttonTextString)
            .font(.caption)
            .fontWeight(.medium)
    }
    
    private var buttonTextString: String {
        if isCurrentlyPlaying && viewModel.isPlaying {
            return "Pause"
        } else {
            return "Play"
        }
    }
    
    private var playButtonTextColor: Color {
        return episode.isAvailable ? .white : .primary
    }
    
    private var playButtonDisabled: Bool {
        return viewModel.isLoading && viewModel.currentlyPlayingEpisode?.id == episode.id
    }
    
    private var playButtonBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(episode.isAvailable ? Color.primary : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary, lineWidth: episode.isAvailable ? 0 : 1)
            )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isCurrentlyPlaying ? Color.blue : Color.clear,
                        lineWidth: isCurrentlyPlaying ? 2 : 0
                    )
            )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct StatusBadge: View {
    let episode: Episode
    let isCurrentlyPlaying: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.1))
        )
    }
    
    private var statusText: String {
        if isCurrentlyPlaying {
            return "Now Playing"
        }
        return episode.statusText
    }
    
    private var statusColor: Color {
        if isCurrentlyPlaying {
            return .blue
        }
        if episode.isAvailable {
            return .blue
        } else if episode.isGenerated {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Preview
struct EpisodeCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Episode.mockEpisodes) { episode in
                    EpisodeCard(episode: episode, viewModel: EpisodeViewModel())
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
} 