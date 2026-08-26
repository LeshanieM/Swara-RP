import json
import sys

def process_video_audio(video_path, audio_path, stutter_timestamps):
    # This is a mock AI service representing the Component 2 AI Service
    # In a real implementation:
    # 1. OpenCV + MediaPipe Face Landmarker analyzes frames
    # 2. VAD and ASR pipelines process audio
    # 3. Features are extracted (e.g. eye blink frequency, response latency)
    # 4. Multimodal fusion associates these events temporally with stuttering timestamps
    
    mock_results = {
        "status": "success",
        "physicalConcomitants": {
            "facialTension": { "score": 2, "candidateEvents": 5, "confidence": 0.82 },
            "eyeMovements": { "score": 1, "candidateEvents": 3, "confidence": 0.74 },
            "headMovements": { "score": 0, "candidateEvents": 0, "confidence": 0.95 },
            "extremityMovements": { "score": 1, "candidateEvents": 2, "confidence": 0.68 }
        },
        "vocalAvoidanceIndicators": {
            "responseLatency": {
                "baseline": 0.5,
                "elevated": True,
                "timestamps": [1.2, 18.1]
            },
            "wordSubstitution": [
                { "originalWord": "dog", "detectedAlternative": "puppy", "confidence": 0.75, "timestamp": 14.5 }
            ],
            "circumlocution": [
                { "utterance": "the animal that barks", "confidence": 0.81, "timestamp": 32.1 }
            ],
            "acousticTension": {
                "summary": "Slight elevation in pitch",
                "candidateTimestamps": [14.0, 31.5],
                "confidence": 0.72
            }
        },
        "eventTimeline": [
            { "timestamp": 14.0, "eventType": "Primary Stutter (Component 1)", "source": "Component 1", "details": "Repetition", "confidence": 0.9 },
            { "timestamp": 14.1, "eventType": "Facial Tension", "source": "Component 2", "details": "Mouth region movement", "confidence": 0.82 },
            { "timestamp": 14.5, "eventType": "Possible Word Substitution", "source": "Component 2", "details": "dog -> puppy", "confidence": 0.75 },
            { "timestamp": 31.2, "eventType": "Primary Stutter (Component 1)", "source": "Component 1", "details": "Prolongation", "confidence": 0.88 },
            { "timestamp": 31.5, "eventType": "Eye Blink", "source": "Component 2", "details": "Rapid blinking", "confidence": 0.74 },
            { "timestamp": 32.1, "eventType": "Possible Circumlocution", "source": "Component 2", "details": "the animal that barks", "confidence": 0.81 }
        ],
        "modelConfidence": 0.80
    }
    return json.dumps(mock_results)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Expected args: script.py <video_path> <audio_path> <stutter_timestamps_json>
        print(process_video_audio(sys.argv[1], sys.argv[2], sys.argv[3]))
    else:
        print(process_video_audio("mock.mp4", "mock.wav", "[]"))
