"""
Computer-vision analysis API (sections 13-14).

    POST /analyze-video                       -> {analysis_id}
    GET  /analyze-video/{analysis_id}/status   -> progress
    GET  /analyze-video/{analysis_id}/results  -> full standardized results

The same uploaded video file is processed independently by every requested
technology (section 5) - the upload happens exactly once per call, and the
saved file path is handed unmodified to each analyzer in turn. One
technology failing or being unavailable does not stop the others
(section 12/30): failures are caught around each analyzer call and recorded
as that technology's `error` status rather than aborting the job.
"""

import json
import os
import shutil
import threading
import uuid
from typing import List, Optional

from pathlib import Path

from fastapi import APIRouter, File, Form, Header, HTTPException, UploadFile
from fastapi.responses import Response, StreamingResponse

from app.analyzers.registry import get_analyzers_for
from app.config.settings import (
    DELETE_UPLOAD_AFTER_PROCESSING,
    GENERATE_OVERLAY_DEFAULT,
    RESULTS_DIR,
    TECHNOLOGIES,
    UPLOAD_DIR,
)
from app.jobs.store import append_result, create_job, get_job, update_job, write_reproducibility_log
from app.processing.comparison import build_comparison
from app.processing.evaluation import evaluate_results
from app.visualization.timeline import build_timeline_data

router = APIRouter()


def _parse_technologies(technologies: Optional[str]) -> List[str]:
    if not technologies or technologies.strip().lower() == "all":
        return list(TECHNOLOGIES)
    requested = [t.strip().lower() for t in technologies.split(",") if t.strip()]
    unknown = [t for t in requested if t not in TECHNOLOGIES]
    if unknown:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown technologies: {unknown}. Valid values: {TECHNOLOGIES} or 'all'.",
        )
    return requested


@router.post("/analyze-video")
async def analyze_video(
    video: UploadFile = File(...),
    technologies: Optional[str] = Form(default="all"),
    generate_overlay: bool = Form(default=GENERATE_OVERLAY_DEFAULT),
    generate_timeline: bool = Form(default=True),
    ground_truth: Optional[str] = Form(default=None),
):
    """
    Starts an analysis job. `technologies` is "all" or a comma-separated
    subset of: mediapipe, openface, openseeface, 3ddfa_v2, mmpose.
    `ground_truth`, if provided, is a JSON string matching section 23's
    schema and is evaluated once all technologies complete.
    """
    selected = _parse_technologies(technologies)

    if not video.filename or "." not in video.filename:
        raise HTTPException(status_code=400, detail="Uploaded file must have a valid filename/extension.")
    ext = video.filename.rsplit(".", 1)[-1].lower()
    if ext not in {"mp4", "mov", "webm", "avi", "mkv"}:
        raise HTTPException(status_code=400, detail=f"Unsupported video format: .{ext}")

    ground_truth_obj = None
    if ground_truth:
        try:
            ground_truth_obj = json.loads(ground_truth)
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="ground_truth must be valid JSON.")

    job = create_job(technologies_requested=selected, video_filename=video.filename)

    saved_name = f"{job.analysis_id}.{ext}"
    saved_path = UPLOAD_DIR / saved_name
    with open(saved_path, "wb") as f:
        shutil.copyfileobj(video.file, f)

    thread = threading.Thread(
        target=_run_job,
        args=(job.analysis_id, str(saved_path), selected, generate_overlay, generate_timeline, ground_truth_obj),
        daemon=True,
    )
    thread.start()

    return {"analysis_id": job.analysis_id, "status": "queued", "technologies": selected}


@router.get("/analyze-video/{analysis_id}/status")
async def analysis_status(analysis_id: str):
    job = get_job(analysis_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown analysis_id")
    return job.status_payload()


@router.get("/analyze-video/{analysis_id}/results")
async def analysis_results(analysis_id: str):
    job = get_job(analysis_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown analysis_id")
    if job.status not in ("completed", "failed"):
        raise HTTPException(status_code=409, detail=f"Analysis is still '{job.status}'. Poll the status endpoint.")
    return job.results_payload()


@router.get("/analyze-video/{analysis_id}/overlay/{technology_key}")
async def analysis_overlay(
    analysis_id: str,
    technology_key: str,
    range_header: Optional[str] = Header(default=None, alias="range"),
):
    """
    Streams the annotated (overlay) video one technology produced, if any.
    Supports HTTP Range requests: mobile players (ExoPlayer/AVPlayer) need
    them to open MP4 files written by OpenCV, whose index sits at the end.
    """
    job = get_job(analysis_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown analysis_id")
    result = next((r for r in job.results if r.get("technology_key") == technology_key), None)
    overlay_path = (result or {}).get("overlay_video_path")
    if not overlay_path:
        raise HTTPException(status_code=404, detail="No overlay video for this technology")

    # Only ever serve files inside RESULTS_DIR (defence against a tampered path).
    resolved = Path(overlay_path).resolve()
    try:
        resolved.relative_to(RESULTS_DIR.resolve())
    except ValueError:
        raise HTTPException(status_code=404, detail="Overlay video not available")
    if not resolved.is_file():
        raise HTTPException(status_code=404, detail="Overlay video file no longer exists")

    return _ranged_file_response(resolved, range_header)


def _ranged_file_response(path: Path, range_header: Optional[str]):
    size = path.stat().st_size
    start, end, status = 0, size - 1, 200
    if range_header and range_header.startswith("bytes="):
        spec = range_header[6:].split(",")[0].strip()
        first, _, last = spec.partition("-")
        try:
            if first == "":  # suffix range: last N bytes
                start = max(size - int(last), 0)
            else:
                start = int(first)
                end = int(last) if last else size - 1
        except ValueError:
            return Response(status_code=416, headers={"Content-Range": f"bytes */{size}"})
        end = min(end, size - 1)
        if start > end or start >= size:
            return Response(status_code=416, headers={"Content-Range": f"bytes */{size}"})
        status = 206

    length = end - start + 1

    def iter_file():
        with open(path, "rb") as f:
            f.seek(start)
            remaining = length
            while remaining > 0:
                chunk = f.read(min(256 * 1024, remaining))
                if not chunk:
                    break
                remaining -= len(chunk)
                yield chunk

    headers = {"Accept-Ranges": "bytes", "Content-Length": str(length)}
    if status == 206:
        headers["Content-Range"] = f"bytes {start}-{end}/{size}"
    return StreamingResponse(iter_file(), status_code=status, media_type="video/mp4", headers=headers)


def _run_job(
    analysis_id: str,
    video_path: str,
    selected: List[str],
    generate_overlay: bool,
    generate_timeline: bool,
    ground_truth_obj,
):
    update_job(analysis_id, status="processing")
    analyzers = get_analyzers_for(selected)

    try:
        for tech_key in selected:
            analyzer = analyzers.get(tech_key)
            update_job(analysis_id, current_technology=analyzer.name if analyzer else tech_key)
            if analyzer is None:
                append_result(
                    analysis_id,
                    tech_key,
                    {
                        "technology": tech_key,
                        "status": "error",
                        "error": "runtime_error: technology not registered",
                        "behaviors": {},
                        "video": {},
                        "tracking": {},
                    },
                )
                continue
            try:
                result = analyzer.analyze(video_path, generate_overlay=generate_overlay)
            except Exception as exc:  # a single analyzer must never take down the job (section 12/30)
                result = analyzer.error_result({}, f"runtime_error: unhandled exception: {exc}")
            append_result(analysis_id, tech_key, result)
            _persist_technology_result(analysis_id, tech_key, result)

        job = get_job(analysis_id)
        comparison = build_comparison(job.results)
        timeline = build_timeline_data(job.results) if generate_timeline else None
        evaluation = evaluate_results(job.results, ground_truth_obj)

        update_job(
            analysis_id,
            status="completed",
            current_technology=None,
            comparison=comparison,
            timeline=timeline,
            evaluation=evaluation,
        )
        job = get_job(analysis_id)
        write_reproducibility_log(job)
        _persist_comparison_and_evaluation(analysis_id, comparison, evaluation)

    except Exception as exc:  # whole-job safety net; individual analyzer errors are already handled above
        update_job(analysis_id, status="failed", error=f"runtime_error: {exc}")
    finally:
        if DELETE_UPLOAD_AFTER_PROCESSING and os.path.isfile(video_path):
            try:
                os.remove(video_path)
            except OSError:
                pass


def _persist_technology_result(analysis_id: str, tech_key: str, result: dict) -> None:
    tech_dir = RESULTS_DIR / analysis_id / tech_key
    tech_dir.mkdir(parents=True, exist_ok=True)
    with open(tech_dir / "events.json", "w") as f:
        json.dump(result, f, indent=2, default=str)


def _persist_comparison_and_evaluation(analysis_id: str, comparison: dict, evaluation: dict) -> None:
    run_dir = RESULTS_DIR / analysis_id
    run_dir.mkdir(parents=True, exist_ok=True)
    with open(run_dir / "comparison.json", "w") as f:
        json.dump(comparison, f, indent=2, default=str)
    with open(run_dir / "evaluation.json", "w") as f:
        json.dump(evaluation, f, indent=2, default=str)
