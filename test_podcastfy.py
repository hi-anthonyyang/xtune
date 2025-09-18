#!/usr/bin/env python3
"""
Test script to demonstrate Podcastfy usage for XTune app
"""

from podcastfy.client import generate_podcast
import os

def test_podcastfy():
    """Test converting text to podcast audio"""
    
    # Sample tweet content for testing
    sample_tweets = """
    Tech News Summary:
    
    1. Apple announced new AI features coming to iOS 18, including improved Siri capabilities and on-device processing for better privacy.
    
    2. OpenAI released GPT-4.5 with enhanced reasoning abilities and better performance on coding tasks.
    
    3. Tesla's latest software update includes improved autopilot features and better energy efficiency for Model S and Model X.
    
    4. Microsoft announced Azure AI improvements with new enterprise-grade security features.
    """
    
    # Configuration for podcast generation
    config = {
        "word_count": 300,  # Target word count for the podcast
        "conversation_style": ["engaging", "informative"],
        "roles_person1": "Tech News Anchor",
        "roles_person2": "Tech Expert",
        "dialogue_structure": [
            "Introduction to today's tech news",
            "Discussion of major announcements",
            "Analysis of industry impact",
            "Conclusion and key takeaways"
        ],
        "podcast_name": "XTune Tech Update",
        "podcast_tagline": "Your daily dose of tech news, simplified"
    }
    
    try:
        print("🎙️ Generating podcast from tweet content...")
        
        # Generate podcast
        result = generate_podcast(
            urls=None,  # We're using text input instead of URLs
            text=sample_tweets,
            tts_model="openai",  # Options: "openai", "elevenlabs", "edge"
            **config
        )
        
        print(f"✅ Podcast generated successfully!")
        print(f"📁 Audio file saved to: {result}")
        
        return result
        
    except Exception as e:
        print(f"❌ Error generating podcast: {str(e)}")
        print("\n💡 This might be because:")
        print("   - You need to set up API keys (OpenAI, ElevenLabs, etc.)")
        print("   - Missing required dependencies")
        print("   - Network connectivity issues")
        
        return None

if __name__ == "__main__":
    print("🚀 Testing Podcastfy for XTune app...")
    print("=" * 50)
    
    result = test_podcastfy()
    
    if result:
        print(f"\n🎉 Success! You can now integrate this into your XTune app.")
        print(f"   The generated audio file is at: {result}")
    else:
        print(f"\n⚠️  Test failed, but this is normal without API keys.")
        print(f"   See setup instructions below.")
    
    print("\n📋 Next Steps:")
    print("1. Set up API keys in environment variables:")
    print("   - OPENAI_API_KEY for OpenAI TTS")
    print("   - ELEVENLABS_API_KEY for ElevenLabs TTS")
    print("2. Update your XTune app's PodcastfyService to call this")
    print("3. Test with real Twitter data") 