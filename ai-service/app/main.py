from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.vision_routes import router as vision_router
from app.api.speech_routes import router as speech_router
from app.api.transcription_routes import router as transcription_router
from app.api.language_routes import router as language_router

app = FastAPI(title="Swara AI Service", version="1.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Component 1: Sinhala child stuttering detection & severity estimation API
app.include_router(speech_router)
app.include_router(transcription_router)

# Component 2: video-based secondary/concomitant-behavior CV analysis
app.include_router(vision_router)
# Component 4: local Sinhala language analysis
app.include_router(language_router)


@app.get("/")
def read_root():
    return {
        "message": "Swara AI Service is running",
        "components": {
            "component1": "Sinhala Child Stuttering Detection & Severity Estimation (/analyze-speech, /speech/status)",
            "component2": "Concomitant Behavior CV Analysis (/analyze-video)",
            "transcription": "Local Sinhala transcription (/speech/transcribe)",
        },
        "version": "1.2.0"
    }
