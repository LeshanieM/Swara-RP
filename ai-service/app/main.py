from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import time

app = FastAPI(title="Swara AI Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Swara AI Service is running"}

@app.post("/analyze-speech")
async def analyze_speech(audio: UploadFile = File(...)):
    """
    Prototype speech analysis endpoint.
    In a real implementation, this would load the audio file,
    extract features (e.g. using librosa), and run inference using
    a trained ML model (e.g. scikit-learn, PyTorch, Wav2Vec2) to
    detect stuttering and extract features.
    """
    try:
        # Simulate processing time
        time.sleep(1.5)
        
        # Return mock prototype response
        return {
            "stutterDetected": True,
            "stutterType": "Repetition",
            "severity": "Moderate",
            "confidence": 0.82,
            "features": {
                "duration": 32,
                "pauseCount": 14,
                "averagePauseDuration": 0.82,
                "speechRate": 2.1
            },
            "isPrototype": True
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
