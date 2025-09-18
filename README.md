# XTune - AI-Powered Podcast Updates

XTune is a SwiftUI iOS app that delivers AI-generated podcast-style audio updates three times per day using tweets sourced from Twitter/X and converted to natural-sounding audio using the Podcastfy API.

## 🚀 Features

- **Three Daily Episodes**: Morning (8am PST), Midday (12pm PST), and Evening (6pm PST)
- **AI-Generated Audio**: Uses Podcastfy API to convert tweet summaries into podcast-style audio
- **Clean, Modern UI**: Inspired by shadcn design principles with SwiftUI
- **Audio Playback**: Full-featured audio player with progress tracking and controls
- **Tweet Sources**: View the original tweets that were used to generate each episode
- **Automatic Scheduling**: Episodes are automatically generated at scheduled times

## 🏗️ Architecture

### Models
- **Tweet**: Contains tweet content, metadata, and categorization
- **Episode**: Represents a single audio drop with title, description, audio URL, and timing

### ViewModels
- **EpisodeViewModel**: Manages state for episodes, audio playback, and user interactions

### Views
- **HomeView**: Main interface with tabbed navigation for different time periods
- **EpisodeCard**: Displays episode information with status indicators
- **AudioPlayerView**: Full-featured audio player with controls and progress tracking

### Services
- **TwitterService**: Fetches tweets from Twitter/X API (currently using mock data)
- **PodcastfyService**: Converts tweet summaries to podcast audio using Podcastfy API
- **EpisodeScheduler**: Manages episode generation timing and local storage

## 📱 UI Design

The app follows shadcn design principles with:
- Clean typography hierarchy
- Consistent spacing and padding
- Subtle shadows and rounded corners
- Semantic color usage
- Responsive layout design

## 🔧 Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Note: API integrations have been removed for security

### Installation
1. Clone the repository
2. Open `XTune.xcodeproj` in Xcode
3. Build and run the project

### TTS Server Setup
The TTS server is included but API integrations have been removed for security. The app will use mock data and fallback scripts.

### Configuration
The app uses mock data and fallback functionality. API integrations have been removed for security:

1. **Mock Data**: The app uses sample tweets and fallback audio generation
2. **TTS Server**: Runs with fallback scripts (no API calls)
3. **Audio Playback**: Full AVPlayer implementation with mock audio URLs

## 🎯 Core Logic

### Episode Generation
1. **Tweet Fetching**: Retrieves top tweets from News, Tech, and Markets categories
2. **Content Summarization**: Creates a coherent narrative from selected tweets
3. **Audio Generation**: Uses Podcastfy API to convert text to natural-sounding audio
4. **Local Storage**: Saves episode metadata and audio URLs locally

### Scheduling
- Episodes are generated at predetermined times (8am, 12pm, 6pm PST)
- The app automatically detects the current time period
- Users can manually generate episodes for any time period

### Audio Playback
- Full-featured player with play/pause, seek, and progress tracking
- 15-second skip forward/backward functionality
- Visual progress indicator with tap-to-seek
- Automatic session management

## 📂 Project Structure

```
XTune/
├── Models/
│   ├── Tweet.swift
│   └── Episode.swift
├── ViewModels/
│   └── EpisodeViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── EpisodeCard.swift
│   └── AudioPlayerView.swift
├── Services/
│   ├── TwitterService.swift
│   ├── PodcastfyService.swift
│   └── EpisodeScheduler.swift
├── Assets.xcassets/
├── Preview Content/
└── Supporting Files/
```

## 🔮 Future Enhancements

The app is designed to be easily extensible with:
- Push notifications for new episodes
- Offline download functionality
- Shareable episode cards
- Episode transcripts
- User preferences and customization
- Firebase/Supabase backend integration

## 🛠️ Technical Details

- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Audio**: AVFoundation
- **Networking**: URLSession
- **Storage**: UserDefaults (upgradeable to cloud storage)

## 📝 API Integration

### Twitter/X API
- Uses Twitter API v2 for tweet fetching
- Searches by category with engagement-based ranking
- Filters for English content and removes retweets

### Podcastfy API
- Converts text summaries to natural-sounding audio
- Supports multiple voices and languages
- Handles async generation with status polling

## 🎨 Design System

The app uses a consistent design system based on shadcn principles:
- **Colors**: Semantic color usage with light/dark mode support
- **Typography**: Clear hierarchy with appropriate font weights
- **Spacing**: Consistent 8px grid system
- **Components**: Reusable UI components with proper accessibility

## 📱 Platform Support

- **iPhone**: Full support with optimized layouts
- **iPad**: Responsive design that adapts to larger screens
- **Accessibility**: VoiceOver and Dynamic Type support
- **Dark Mode**: Full dark mode compatibility

---

Built with ❤️ using SwiftUI and modern iOS development practices. 