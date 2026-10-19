import os
import tempfile
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.processing.language_analysis import analyze_transcript

router = APIRouter()
MAX_BYTES = int(os.getenv("C4_MAX_AUDIO_BYTES", str(50 * 1024 * 1024)))
ALLOWED = {"audio/wav", "audio/x-wav", "audio/mpeg", "audio/mp4", "audio/aac", "audio/webm", "audio/ogg"}


def _model_config():
    custom = os.getenv("C4_MMS_ADAPTER_DIR")
    baseline = os.getenv("C4_ASR_MODEL_DIR")
    if custom and Path(custom).is_dir():
        return custom, "custom-mms-sinhala-adapter"
    if baseline and Path(baseline).is_dir():
        return baseline, os.getenv("C4_ASR_MODEL_NAME", "configured-local-sinhala-asr")
    return None, None


def _transcribe_local(audio_path, model_dir, model_name):
    try:
        from transformers import pipeline
    except ImportError as exc:
        raise HTTPException(status_code=503, detail="model_unavailable: install the optional transformers and torch dependencies") from exc
    try:
        # local_files_only prevents startup/request-time downloads; weights must be provisioned explicitly.
        asr = pipeline("automatic-speech-recognition", model=model_dir, device=-1, model_kwargs={"local_files_only": True})
        result = asr(audio_path, chunk_length_s=25, stride_length_s=4)
        transcript = result.get("text", "").strip()
        if not transcript:
            raise HTTPException(status_code=422, detail="transcription_empty: the configured model returned no text")
        return transcript
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"asr_inference_failed: configured model could not process audio ({type(exc).__name__})") from exc


def _convert_audio(source_path):
    try:
        import librosa
        import soundfile as sf
        samples, sample_rate = librosa.load(source_path, sr=16000, mono=True)
        duration = len(samples) / 16000
        if duration <= 0 or duration > 180:
            raise HTTPException(status_code=413, detail="audio_duration_must_be_between_0_and_180_seconds")
        converted = tempfile.NamedTemporaryFile(prefix="swara_c4_16k_", suffix=".wav", delete=False)
        converted.close()
        sf.write(converted.name, samples, 16000, subtype="PCM_16")
        return converted.name, duration
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=415, detail=f"audio_decode_failed: unsupported or corrupt recording ({type(exc).__name__})") from exc


@router.post("/analyze-language")
async def analyze_language(audio: UploadFile = File(None), recordingReference: str = Form(None)):
    model_dir, model_name = _model_config()
    if not model_dir:
        raise HTTPException(status_code=503, detail="model_unavailable: configure C4_MMS_ADAPTER_DIR or C4_ASR_MODEL_DIR with local trained model weights")
    temp_path = None
    wav_path = None
    try:
        if audio is not None:
            if audio.content_type not in ALLOWED:
                raise HTTPException(status_code=415, detail="unsupported_audio_format")
            content = await audio.read(MAX_BYTES + 1)
            if not content or len(content) > MAX_BYTES:
                raise HTTPException(status_code=413, detail="audio_empty_or_too_large")
            suffix = Path(audio.filename or "recording.wav").suffix[:8]
            with tempfile.NamedTemporaryFile(prefix="swara_c4_", suffix=suffix, delete=False) as temp:
                temp.write(content)
                temp_path = temp.name
        elif recordingReference:
            root = Path(os.getenv("C4_RECORDING_ROOT", "")).resolve()
            candidate = (root / recordingReference).resolve() if root and not Path(recordingReference).is_absolute() else None
            if not candidate or root not in candidate.parents or not candidate.is_file():
                raise HTTPException(status_code=400, detail="invalid_recording_reference")
            temp_path = str(candidate)
        else:
            raise HTTPException(status_code=400, detail="audio_or_recordingReference_required")
        wav_path, duration = _convert_audio(temp_path)
        transcript = _transcribe_local(wav_path, model_dir, model_name)
        analysis = analyze_transcript(transcript)
        return {"transcript": analysis["transcript"], "model": {"name": model_name, "version": os.getenv("C4_ASR_MODEL_VERSION", "configured-local")},
                "utterances": analysis["utterances"], "measures": analysis["measures"], "shortSample": analysis["shortSample"],
                "reliabilityFlags": analysis["reliabilityFlags"], "segmentationMethod": "transcript_punctuation_fallback", "durationSeconds": duration}
    finally:
        if temp_path and audio is not None:
            try:
                os.unlink(temp_path)
            except OSError:
                pass
        if wav_path:
            try:
                os.unlink(wav_path)
            except OSError:
                pass
