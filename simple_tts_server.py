#!/usr/bin/env python3
"""
Simple TTS server for XTune app using Edge TTS (free)
"""

import asyncio
import os
import json
import uuid
import threading
import random
import subprocess
from datetime import datetime
from pathlib import Path
from flask import Flask, request, jsonify, send_file
from pydub import AudioSegment
# API integrations removed for security

app = Flask(__name__)

# --- Configuration ---
OUTPUT_DIR = Path("./audio_output")

# API client removed for security

HOST_VOICES = {
    "Ant": "en-US-GuyNeural",
    "Dawn": "en-US-AriaNeural"
}

# --- Initialization ---
OUTPUT_DIR.mkdir(exist_ok=True)
audio_generation_lock = threading.Lock()

def cleanup_temp_files():
    """Clean up leftover temporary files"""
    for file in OUTPUT_DIR.glob("temp_*"):
        try:
            file.unlink()
        except OSError as e:
            print(f"Error cleaning up {file.name}: {e}")

cleanup_temp_files()

# --- Script Generation ---
def generate_podcast_script(tweets_text: str) -> str:
    """Generate a conversational podcast script using Groq API"""
    print("🧠 Generating script with Groq...")
    prompt = f"""
You are writing a podcast script for two warm, charismatic hosts:
Dawn (curious, empathetic, thoughtful)
Ant (witty, energetic, insightful)

They are reacting to a list of today’s top tweets in an engaging, back-and-forth conversation.

Goals:
- Make the podcast feel natural, like a real conversation—not robotic or overly formal.
- Use humor, genuine reactions, short tangents, and relatable metaphors.
- Each host should have a distinct personality and voice, reflected in what they say and how they say it.
- Break down tweets with curiosity and reflection, not just reading them. Ask questions like “Why do you think this resonated with so many people?” or “How does this connect to a bigger trend?”
- Hosts should dive deep, and sometimes even technical, into the tweets. It shouldn't be vague abstract thoughts, but insightful details that educate, inform, and are thought provoking

Structure:
- Intro Segment (10–15 seconds) — A shared greeting and brief mention of what’s coming up.
- Tweet Reactions (the core) — For each tweet (30 sec - 1.5 minutes each tweet):
  - One host introduces the tweet (don’t just read it, contextualize it).
  - They go back and forth reacting to it, sometimes joking, sometimes unpacking insights.
  - Add short side comments, pop culture references, or analogies.
- Outro — Thank listeners and CTA to come back next time.

Input:
{tweets_text}

Output:
Write a conversational script where Ant and Dawn alternate naturally, overlapping ideas, interrupting playfully, or building on each other’s points.
Ensure the output format is clean, with each line starting with "Ant:" or "Dawn:", followed by their dialogue.
    """
    
    # API call removed for security - using fallback script
    print("⚠️  API integration disabled for security")
    return generate_fallback_script()

def generate_fallback_script() -> str:
    return """
Dawn: Welcome to your daily briefing.
Ant: We seem to be having some technical difficulties getting the latest updates.
Dawn: We'll be back shortly with your personalized news summary. Thanks for your patience!
    """

# --- Audio Generation ---
async def text_to_speech(text: str, voice: str, output_path: Path) -> bool:
    """Converts a single line of text to speech using edge-tts"""
    print(f"🎤 Generating audio for: {text[:30]}... (Voice: {voice})")
    try:
        import edge_tts
        communicate = edge_tts.Communicate(text, voice)
        await communicate.save(str(output_path))
        return output_path.exists() and output_path.stat().st_size > 0
    except Exception as e:
        print(f"Error in text_to_speech: {e}")
        return False

async def generate_and_stitch_audio(script: str, final_output_path: Path) -> float:
    """Generate audio for each line and stitch them together"""
    print("🎧 Starting audio generation and stitching...")
    lines = [line.strip() for line in script.split('\n') if line.strip()]
    temp_files = []
    
    tasks = []
    for i, line in enumerate(lines):
        parts = line.split(":", 1)
        if len(parts) != 2:
            continue
            
        host, dialogue = parts
        voice = HOST_VOICES.get(host.strip())
        if not voice:
            continue
            
        temp_path = OUTPUT_DIR / f"temp_{uuid.uuid4()}.mp3"
        temp_files.append(temp_path)
        tasks.append(text_to_speech(dialogue.strip(), voice, temp_path))

    results = await asyncio.gather(*tasks)
    
    if not all(results):
        print("❌ One or more audio segments failed to generate.")
        cleanup_temp_files()
        return 0.0

    print("🧩 Stitching audio files together...")
    # Stitch audio files together
    combined_audio = AudioSegment.empty()
    for temp_file in temp_files:
        if temp_file.exists():
            segment = AudioSegment.from_mp3(temp_file)
            combined_audio += segment

    combined_audio.export(final_output_path, format="mp3")
    print(f"✅ Final audio saved to: {final_output_path}")
    
    # Clean up temporary files
    print("🗑️ Cleaning up temporary files...")
    for temp_file in temp_files:
        if temp_file.exists():
            temp_file.unlink()
            
    return len(combined_audio) / 1000.0  # Duration in seconds

# --- Flask Routes ---
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'XTune TTS Server'
    })

@app.route('/generate-podcast', methods=['POST'])
def generate_podcast():
    """Generate podcast from tweet content"""
    with audio_generation_lock:
        try:
            data = request.get_json()
            if not data:
                return jsonify({'error': 'Invalid JSON'}), 400
            
            tweets_text = data.get('text', '')
            if not tweets_text:
                return jsonify({'error': 'No text provided'}), 400

            print("🎙️  Received request to generate podcast")
            
            # Generate script
            script = generate_podcast_script(tweets_text)
            
            # Generate audio
            episode_id = uuid.uuid4()
            output_filename = f"episode_{episode_id}.mp3"
            output_path = OUTPUT_DIR / output_filename
            
            duration = asyncio.run(generate_and_stitch_audio(script, output_path))
            
            if duration > 0:
                audio_url = f"http://localhost:5001/audio/{output_filename}"
                return jsonify({
                    'success': True,
                    'audioURL': audio_url,
                    'duration': duration,
                    'script': script
                })
            else:
                return jsonify({'success': False, 'error': 'Audio generation failed'}), 500

        except Exception as e:
            print(f"Error in generate_podcast: {e}")
            return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/audio/<filename>')
def serve_audio(filename):
    """Serve audio files"""
    path = OUTPUT_DIR / filename
    if path.exists():
        return send_file(path, mimetype='audio/mpeg')
    return jsonify({'error': 'Audio file not found'}), 404

@app.route('/list-audio')
def list_audio():
    """List all available audio files"""
    audio_files = [
        {'filename': f.name, 'size': f.stat().st_size}
        for f in OUTPUT_DIR.glob("episode_*.mp3")
    ]
    return jsonify({'files': audio_files})

if __name__ == '__main__':
    print("🚀 Starting XTune TTS Server...")
    app.run(host='0.0.0.0', port=5001, debug=True) 