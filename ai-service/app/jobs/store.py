"""
In-memory job store for asynchronous video analysis (section 14).

Prototype-scope limitation (documented, not hidden): jobs live in this
process's memory only. Restarting the AI service loses in-flight/completed
job state (the per-technology result JSON files already written under
RESULTS_DIR survive, but the job index does not). For this research
prototype that's an accepted tradeoff over adding a message broker /
persistent job table; the Node.js layer additionally caches completed
results into MongoDB once fetched (see backend `VideoAnalysis` model), so a
completed analysis is not actually lost from the application's point of
view even if this process restarts.

Each job's lifecycle:
    queued -> processing (per technology) -> completed | failed
"""

import json
import threading
import time
import uuid
from dataclasses import asdict, dataclass, field
from typing import Any, Dict, List, Optional

from app.config.settings import RESULTS_DIR, SOFTWARE_VERSION

_lock = threading.Lock()
_jobs: Dict[str, "Job"] = {}


@dataclass
class Job:
    analysis_id: str
    status: str = "queued"  # queued | processing | completed | failed
    technologies_requested: List[str] = field(default_factory=list)
    current_technology: Optional[str] = None
    completed: int = 0
    total: int = 0
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    video_filename: Optional[str] = None
    results: List[Dict[str, Any]] = field(default_factory=list)
    comparison: Optional[Dict[str, Any]] = None
    timeline: Optional[Dict[str, Any]] = None
    evaluation: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

    def status_payload(self) -> Dict[str, Any]:
        return {
            "analysis_id": self.analysis_id,
            "status": self.status,
            "current_technology": self.current_technology,
            "completed": self.completed,
            "total": self.total,
            "technologies_requested": self.technologies_requested,
            "per_technology_status": {r["technology_key"]: r["status"] for r in self._status_rows()},
        }

    def _status_rows(self) -> List[Dict[str, str]]:
        return [
            {"technology_key": r.get("technology_key", r.get("technology", "")), "status": r.get("status", "")}
            for r in self.results
        ]

    def results_payload(self) -> Dict[str, Any]:
        return {
            "analysis_id": self.analysis_id,
            "status": self.status,
            "video_filename": self.video_filename,
            "results": self.results,
            "comparison": self.comparison,
            "timeline": self.timeline,
            "evaluation": self.evaluation,
            "error": self.error,
        }


def create_job(technologies_requested: List[str], video_filename: str) -> Job:
    job = Job(
        analysis_id=str(uuid.uuid4()),
        technologies_requested=technologies_requested,
        total=len(technologies_requested),
        video_filename=video_filename,
    )
    with _lock:
        _jobs[job.analysis_id] = job
    return job


def get_job(analysis_id: str) -> Optional[Job]:
    with _lock:
        return _jobs.get(analysis_id)


def update_job(analysis_id: str, **fields) -> Optional[Job]:
    with _lock:
        job = _jobs.get(analysis_id)
        if job is None:
            return None
        for k, v in fields.items():
            setattr(job, k, v)
        job.updated_at = time.time()
        return job


def append_result(analysis_id: str, technology_key: str, result: Dict[str, Any]) -> None:
    with _lock:
        job = _jobs.get(analysis_id)
        if job is None:
            return
        result = dict(result)
        result["technology_key"] = technology_key
        job.results.append(result)
        job.completed = len(job.results)
        job.updated_at = time.time()


def write_reproducibility_log(job: Job) -> str:
    """Persists the reproducibility log described in section 27: one JSON
    file per analysis run, independent of the in-memory job store."""
    log = {
        "analysis_id": job.analysis_id,
        "video_filename": job.video_filename,
        "software_version": SOFTWARE_VERSION,
        "technologies_requested": job.technologies_requested,
        "created_at": job.created_at,
        "completed_at": job.updated_at,
        "per_technology": [
            {
                "technology": r.get("technology"),
                "technology_version": r.get("technology_version"),
                "status": r.get("status"),
                "reason": r.get("reason") or r.get("error"),
                "processing_time": r.get("processing_time"),
                "video": r.get("video"),
                "tracking": r.get("tracking"),
                "thresholds_used": r.get("thresholds_used"),
                "preprocessing_notes": r.get("preprocessing_notes"),
            }
            for r in job.results
        ],
    }
    path = RESULTS_DIR / f"{job.analysis_id}_reproducibility_log.json"
    with open(path, "w") as f:
        json.dump(log, f, indent=2, default=str)
    return str(path)
