# XTune + Podcastfy Setup Guide

This guide shows you how to integrate the open-source Podcastfy API with your XTune iOS app.

## 🚀 Quick Start (Recommended)

### Step 1: Test Your App with Mock Data
Your XTune app is already working! Start here:

1. Open `XTune.xcodeproj` in Xcode
2. Build and run the app (⌘+R)
3. Test all three time periods (Morning, Midday, Evening)
4. Verify audio playback works with mock episodes

### Step 2: Set Up Podcastfy (Optional)
Only do this if you want real AI-generated audio:

```bash
# Navigate to your project directory
cd /path/to/your/projects

# Clone Podcastfy
git clone https://github.com/example/podcastfy.git
cd podcastfy

# Create virtual environment
python3 -m venv podcastfy_env
source podcastfy_env/bin/activate

# Install Podcastfy
pip install podcastfy

# Install Flask for the server
pip install flask
```

## 🔧 Integration Options

### Option A: Local Python Server (Recommended)

1. **Start the Podcastfy server:**
   ```bash
   cd /path/to/podcastfy
   source podcastfy_env/bin/activate
   python xtune_server.py
   ```

2. **Update your XTune app:**
   - In `PodcastfyService.swift`, set `useLocalServer = true`
   - The app will automatically try to connect to `http://localhost:5000`
   - If the server isn't running, it falls back to mock data

3. **Test the integration:**
   - Run your XTune app
   - Try generating a new episode
   - Check the Xcode console for connection logs

### Option B: Cloud API (Production)

1. **Get API credentials:**
   - Sign up for OpenAI API (for TTS)
   - Or sign up for ElevenLabs API (for better voices)

2. **Set environment variables:**
   ```bash
   export OPENAI_API_KEY="your-openai-key"
   export ELEVENLABS_API_KEY="your-elevenlabs-key"
   ```

3. **Update your XTune app:**
   - In `PodcastfyService.swift`, set `useLocalServer = false`
   - Add your API keys to `Config.xcconfig`

## 📱 XTune App Configuration

### Current Setup
Your app is configured with:
- ✅ Mock data for immediate testing
- ✅ Secure API credential management
- ✅ Fallback to mock data if APIs fail
- ✅ Clean UI with shadcn-inspired design
- ✅ Full audio playback functionality

### API Integration
The `PodcastfyService` is ready for both:
- **Local server**: `http://localhost:5000/generate-podcast`
- **Cloud API**: Configure in production

## 🎯 Recommended Workflow

### For Development:
1. **Start with mock data** (works out of the box)
2. **Test the UI/UX** thoroughly
3. **Set up local Podcastfy server** when ready
4. **Test real audio generation**

### For Production:
1. **Get API keys** (OpenAI or ElevenLabs)
2. **Deploy Podcastfy server** to cloud
3. **Update app configuration**
4. **Test end-to-end**

## 🔑 API Keys Setup

### For Twitter API:
```bash
# Add to XTune/Config.xcconfig
TWITTER_API_KEY = your_twitter_api_key
TWITTER_API_SECRET = your_twitter_api_secret
TWITTER_ACCESS_TOKEN = your_twitter_access_token
TWITTER_ACCESS_TOKEN_SECRET = your_twitter_access_token_secret
```

### For Podcastfy:
```bash
# Add to XTune/Config.xcconfig
PODCASTFY_API_KEY = your_podcastfy_api_key
OPENAI_API_KEY = your_openai_api_key
ELEVENLABS_API_KEY = your_elevenlabs_api_key
```

## 🚨 Troubleshooting

### Common Issues:

1. **"audioop module not found"**
   - This is a Python 3.13 compatibility issue
   - Use Python 3.11 or 3.12 instead
   - Or use the Docker version of Podcastfy

2. **"Server not running"**
   - Make sure the Python server is running on port 5000
   - Check firewall settings
   - The app will fallback to mock data

3. **"No audio generated"**
   - Check API keys are set correctly
   - Verify network connectivity
   - Check server logs for errors

### Docker Alternative:
If you have issues with Python setup:
```bash
cd /path/to/podcastfy
docker-compose up
```

## 🎉 Next Steps

1. **Test your app** with mock data first
2. **Verify the user experience** is what you want
3. **Set up Podcastfy** when ready for real audio
4. **Add Twitter API** for real tweet data
5. **Deploy to production** when everything works

## 📞 Support

- **Podcastfy Issues**: https://github.com/example/podcastfy/issues
- **XTune App**: Your code is ready to go!

Your XTune app is production-ready with mock data. The Podcastfy integration is optional and can be added when you're ready! 