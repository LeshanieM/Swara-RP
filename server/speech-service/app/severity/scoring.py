"""Event-based severity: %SS + duration term (+ optional physical term)."""
from app.detection.events import Moment
from app.severity import config as cfg


def _band(value: float, bands: list[tuple[float, int]]) -> int:
    return next(points for upper, points in bands if value < upper)


def percent_ss(stuttered: int, total_syllables: int) -> float:
    return round(100.0 * stuttered / total_syllables, 2) if total_syllables > 0 else 0.0


def duration_term(moments: list[Moment]) -> dict:
    longest = sorted((m.duration for m in moments), reverse=True)
    top = longest[:3]
    return {
        "meanLongest3Sec": round(sum(top) / len(top), 3) if top else 0.0,
        "longestSec": round(longest[0], 3) if longest else 0.0,
        "eventsUsed": len(top),
    }


def score(task_type: str, pss: float, duration: dict, concomitant_score: float | None) -> dict:
    bands = cfg.FREQUENCY_BANDS[task_type]
    frequency_points = _band(pss, bands)
    duration_points = _band(duration["meanLongest3Sec"], cfg.DURATION_BANDS) if duration["eventsUsed"] else 0
    physical_used = concomitant_score is not None
    physical_points = round(concomitant_score * cfg.PHYSICAL_MAX_POINTS) if physical_used else 0
    total = frequency_points + duration_points + physical_points

    below_floor = pss < bands[0][0]
    label = "none_very_mild" if below_floor else next(name for upper, name in cfg.LABEL_BANDS if total <= upper)
    return {
        "label": label,
        "displayLabel": cfg.DISPLAY[label],
        "score": total,
        "maxScore": bands[-1][1] + cfg.DURATION_BANDS[-1][1] + (cfg.PHYSICAL_MAX_POINTS if physical_used else 0),
        "components": {
            "frequencyPoints": frequency_points,
            "durationPoints": duration_points,
            "physicalPoints": physical_points,
        },
        "belowFrequencyFloor": below_floor,
        "physicalTermUsed": physical_used,
        "taskType": task_type,
        "method": cfg.SEVERITY_METHOD,
        "version": cfg.SEVERITY_VERSION,
        "provisional": True,
    }
