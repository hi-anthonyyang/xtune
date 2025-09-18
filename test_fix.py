#!/usr/bin/env python3
"""
Test script to verify the XTune fixes work correctly
"""

import requests
import json
import time

def test_server_and_generate_audio():
    """Test server and generate a few audio files"""
    
    print("🧪 Testing XTune fixes...")
    print("=" * 50)
    
    # Test 1: Health check
    print("1. Testing server health...")
    try:
        response = requests.get("http://localhost:5001/health", timeout=5)
        if response.status_code == 200:
            health_data = response.json()
            print(f"✅ Server healthy: {health_data['service']}")
            print(f"   Timestamp: {health_data['timestamp']}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to server: {e}")
        return False
    
    # Test 2: Generate multiple episodes
    test_episodes = [
        {
            "name": "Morning Episode",
            "text": "Good morning! Here's your tech briefing. Apple announced new AI features. Tesla released autopilot updates. Microsoft improved Azure AI."
        },
        {
            "name": "Midday Episode", 
            "text": "Good afternoon! Midday update: OpenAI released GPT-4.5. Google announced new search features. Meta launched VR updates."
        },
        {
            "name": "Evening Episode",
            "text": "Good evening! Today's wrap-up: Amazon expanded AWS services. Netflix improved streaming quality. Spotify added new features."
        }
    ]
    
    generated_urls = []
    
    for i, episode in enumerate(test_episodes, 1):
        print(f"\n{i+1}. Generating {episode['name']}...")
        try:
            response = requests.post(
                "http://localhost:5001/generate-podcast",
                json={"text": episode["text"]},
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success'):
                    audio_url = result.get('audioURL')
                    print(f"✅ Generated: {audio_url}")
                    generated_urls.append(audio_url)
                else:
                    print(f"❌ Generation failed: {result.get('error')}")
            else:
                print(f"❌ Request failed: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    # Test 3: Verify audio files are accessible
    print(f"\n{len(test_episodes)+2}. Testing audio file access...")
    accessible_count = 0
    for url in generated_urls:
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                accessible_count += 1
                print(f"✅ Accessible: {url.split('/')[-1]} ({len(response.content)} bytes)")
            else:
                print(f"❌ Not accessible: {url}")
        except Exception as e:
            print(f"❌ Error accessing {url}: {e}")
    
    # Test 4: List all audio files
    print(f"\n{len(test_episodes)+3}. Listing all audio files...")
    try:
        response = requests.get("http://localhost:5001/list-audio", timeout=5)
        if response.status_code == 200:
            files = response.json()
            print(f"✅ Found {files['count']} audio files:")
            for file in files['files']:
                print(f"   - {file['filename']} ({file['size']} bytes)")
        else:
            print(f"❌ Failed to list files: {response.status_code}")
    except Exception as e:
        print(f"❌ Error listing files: {e}")
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Summary:")
    print(f"   Generated episodes: {len(generated_urls)}")
    print(f"   Accessible episodes: {accessible_count}")
    
    if len(generated_urls) > 0 and accessible_count == len(generated_urls):
        print("🎉 All tests PASSED!")
        print("\n✅ Your iOS app should now work correctly:")
        print("   1. Clear cache using the trash button in the app")
        print("   2. Generate new episodes - they'll get real audio from the server")
        print("   3. No more 404 errors or corrupted audio files")
        return True
    else:
        print("❌ Some tests FAILED!")
        return False

if __name__ == "__main__":
    success = test_server_and_generate_audio()
    
    if success:
        print("\n🚀 Ready to test with your iOS app!")
    else:
        print("\n🔧 Please check the server logs for issues.") 