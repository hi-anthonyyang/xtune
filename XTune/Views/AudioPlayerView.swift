import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var viewModel: EpisodeViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: viewModel.playbackProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                    .scaleEffect(y: 2)
                    .onTapGesture { location in
                        handleProgressTap(location: location)
                    }
                
                HStack {
                    Text(viewModel.formattedCurrentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Playback Controls
            HStack(spacing: 24) {
                // Back Button
                Button(action: {
                    viewModel.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.canPlayPrevious ? .primary : .secondary)
                }
                .disabled(!viewModel.canPlayPrevious)
                
                // Skip Backward 15s
                Button(action: {
                    viewModel.seek(to: max(0, viewModel.currentTime - 15))
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(viewModel.currentlyPlayingEpisode != nil ? .primary : .secondary)
                }
                .disabled(viewModel.currentlyPlayingEpisode == nil)
                
                // Play/Pause Button
                Button(action: {
                    if let episode = viewModel.currentlyPlayingEpisode {
                        viewModel.playOrPause(episode: episode)
                    } else {
                        viewModel.playMostRecent()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.currentlyPlayingEpisode != nil ? Color.primary : Color.secondary)
                            .frame(width: 56, height: 56)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.isLoading)
                
                // Skip Forward 15s
                Button(action: {
                    viewModel.seek(to: min(viewModel.duration, viewModel.currentTime + 15))
                }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundColor(viewModel.currentlyPlayingEpisode != nil ? .primary : .secondary)
                }
                .disabled(viewModel.currentlyPlayingEpisode == nil)
                
                // Forward Button
                Button(action: {
                    viewModel.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.canPlayNext ? .primary : .secondary)
                }
                .disabled(!viewModel.canPlayNext)
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func handleProgressTap(location: CGPoint) {
        guard viewModel.currentlyPlayingEpisode != nil else { return }
        
        // Calculate the tap position relative to the progress bar
        let progressBarWidth = UIScreen.main.bounds.width - 48 // Account for padding
        let tapPosition = location.x / progressBarWidth
        let newTime = Double(tapPosition) * viewModel.duration
        
        viewModel.seek(to: max(0, min(viewModel.duration, newTime)))
    }
}

// MARK: - Preview
struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AudioPlayerView(viewModel: EpisodeViewModel())
                .padding()
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
} 