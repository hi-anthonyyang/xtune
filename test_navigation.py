#!/usr/bin/env python3
"""
Test script to generate multiple episodes for testing navigation functionality
"""

import requests
import json
import time
from datetime import datetime, timedelta

def generate_test_episodes():
    """Generate episodes for different time periods to test navigation"""
    
    print("🧪 Generating test episodes for navigation...")
    print("=" * 50)
    
    # Test episodes for different periods
    episodes = [
        {
            "period": "morning",
            "text": "Good morning! Today's tech headlines: Apple unveils new AI features for iOS 18. Google announces breakthrough in quantum computing. Tesla releases Full Self-Driving beta 12.0 with improved neural networks."
        },
        {
            "period": "midday", 
            "text": "Good afternoon! Midday tech update: Microsoft integrates GPT-4 into Office 365. Meta launches new VR headset with advanced eye tracking. Amazon expands AWS AI services with new machine learning tools."
        },
        {
            "period": "evening",
            "text": "Good evening! Today's tech wrap-up: Netflix announces new streaming technology. Spotify introduces AI-powered playlist generation. Adobe releases Creative Cloud updates with enhanced AI features."
        }
    ]
    
    generated_episodes = []
    
    for i, episode in enumerate(episodes, 1):
        print(f"\n{i}. Generating {episode['period']} episode...")
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
                    print(f"✅ Generated {episode['period']}: {audio_url}")
                    generated_episodes.append({
                        "period": episode["period"],
                        "url": audio_url,
                        "filename": audio_url.split('/')[-1]
                    })
                else:
                    print(f"❌ Generation failed: {result.get('error')}")
            else:
                print(f"❌ Request failed: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    # Test accessibility
    print(f"\n4. Testing episode accessibility...")
    accessible_count = 0
    for episode in generated_episodes:
        try:
            response = requests.get(episode["url"], timeout=10)
            if response.status_code == 200:
                accessible_count += 1
                print(f"✅ {episode['period']}: {episode['filename']} ({len(response.content)} bytes)")
            else:
                print(f"❌ {episode['period']}: Not accessible")
        except Exception as e:
            print(f"❌ {episode['period']}: Error - {e}")
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Navigation Test Setup Summary:")
    print(f"   Episodes generated: {len(generated_episodes)}")
    print(f"   Episodes accessible: {accessible_count}")
    
    if len(generated_episodes) >= 2:
        print("\n🎉 Navigation test setup COMPLETE!")
        print("\n✅ You can now test the navigation features:")
        print("   1. Open your XTune app")
        print("   2. Clear cache using the trash button")
        print("   3. Generate episodes for different periods")
        print("   4. Test back/forward navigation between episodes")
        print("   5. Verify play button always plays most recent")
        print("   6. Check that forward button generates new episodes when needed")
        return True
    else:
        print("\n❌ Not enough episodes generated for navigation testing")
        return False

if __name__ == "__main__":
    success = generate_test_episodes()
    
    if success:
        print("\n🚀 Ready to test navigation in your iOS app!")
        print("💡 The app now supports:")
        print("   • Play button: Always plays most recent episode")
        print("   • Back button: Plays previous episode (grayed out if none)")
        print("   • Forward button: Plays next episode or generates new one")
        print("   • Visual indicators for currently playing episode")
    else:
        print("\n🔧 Please ensure the TTS server is running and try again.") 