#!/usr/bin/env python3
"""
Test script to verify XTune + Edge TTS integration
"""

import requests
import json
import time

def test_server():
    """Test the TTS server"""
    
    # Test data (same format as XTune app sends)
    test_data = {
        "text": """Good morning! Welcome to your daily briefings.

Here are today's top stories:

From Tech Reporter: Breaking: Major tech company announces revolutionary AI breakthrough that could change everything we know about machine learning.

From Science Journal: New study reveals breakthrough in quantum computing that could revolutionize data encryption and processing speeds.

That's your morning update. Stay informed, stay ahead."""
    }
    
    print("🚀 Testing XTune TTS Server Integration...")
    print("=" * 50)
    
    # Test health endpoint
    print("1. Testing health endpoint...")
    try:
        response = requests.get("http://localhost:5001/health", timeout=5)
        if response.status_code == 200:
            print("✅ Server is healthy")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to server: {e}")
        print("💡 Make sure the server is running:")
        print("   cd /path/to/podcastfy")
        print("   source podcastfy_env/bin/activate")
        print("   python simple_tts_server.py")
        return False
    
    # Test podcast generation
    print("\n2. Testing podcast generation...")
    try:
        response = requests.post(
            "http://localhost:5001/generate-podcast",
            json=test_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Podcast generated successfully!")
                print(f"   Audio URL: {result.get('audioURL')}")
                print(f"   Audio File: {result.get('audioFile')}")
                print(f"   Script Preview: {result.get('script', '')[:100]}...")
                
                # Test audio file access
                print("\n3. Testing audio file access...")
                audio_url = result.get('audioURL')
                if audio_url:
                    audio_response = requests.get(audio_url, timeout=10)
                    if audio_response.status_code == 200:
                        print("✅ Audio file is accessible")
                        print(f"   Content-Type: {audio_response.headers.get('Content-Type')}")
                        print(f"   File Size: {len(audio_response.content)} bytes")
                        return True
                    else:
                        print(f"❌ Audio file not accessible: {audio_response.status_code}")
                        return False
                else:
                    print("❌ No audio URL returned")
                    return False
            else:
                print(f"❌ Generation failed: {result.get('error')}")
                return False
        else:
            print(f"❌ Request failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error during generation: {e}")
        return False

if __name__ == "__main__":
    success = test_server()
    
    print("\n" + "=" * 50)
    if success:
        print("🎉 Integration test PASSED!")
        print("✅ Your XTune app can now generate real audio!")
        print("\n📋 Next steps:")
        print("1. Keep the server running")
        print("2. Build and run your XTune app in Xcode")
        print("3. Try generating episodes - they'll use real TTS!")
    else:
        print("❌ Integration test FAILED!")
        print("🔧 Troubleshooting:")
        print("1. Make sure the server is running on port 5001")
        print("2. Check that edge-tts is installed")
        print("3. Verify network connectivity")
        print("4. Your app will fallback to mock data if server is down") 