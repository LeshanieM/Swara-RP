"""Rules baseline: the earlier C2 prototype's fixed thresholds, applied to the
same stutter moments so the two methods can be compared on identical input.

Ported from the prototype (same thresholds, same hysteresis idea):
  eye  : EAR < 0.21 for 0.06–0.6 s (release at 0.21 × 1.15)
  lip  : lip opening moves > 0.06 (inter-ocular units) from the recording median for ≥ 0.1 s
  jaw  : chin drop moves > 0.05 from the recording median for ≥ 0.1 s
  head : angular speed > 25 deg/s for ≥ 0.15 s
The prototype compared lip and jaw *levels* with these thresholds, which fires
whenever the mouth is open; its own comments describe displacement from a
baseline, which is what is used here. The thresholds are not speaker-relative,
which is exactly the difference SRCD tests.
"""
import numpy as np

from app.detection.base import CategoryDecision, Context, Detector
from app.features import catalog

RULES = {
    "eye": {"feature": "ear", "mode": "below", "threshold": 0.21, "release": 0.21 * 1.15, "min_sec": 0.06, "max_sec": 0.6},
    "lip": {"feature": "lipOpening", "mode": "displacement", "threshold": 0.06, "release": 0.06 * 0.7, "min_sec": 0.1},
    "jaw": {"feature": "jawOpening", "mode": "displacement", "threshold": 0.05, "release": 0.05 * 0.7, "min_sec": 0.1},
    "head": {"feature": "headSpeed", "mode": "above", "threshold": 25.0, "release": 25.0 * 0.7, "min_sec": 0.15},
}


def _intervals(signal: np.ndarray, times: np.ndarray, rule: dict) -> list[tuple[float, float]]:
    below = rule["mode"] == "below"
    active, start, out = False, 0, []
    for i, v in enumerate(signal):
        if np.isnan(v):
            on, off = False, active  # a missing face ends any event
        else:
            on = v < rule["threshold"] if below else v > rule["threshold"]
            off = v > rule["release"] if below else v < rule["release"]
        if not active and on:
            active, start = True, i
        elif active and off:
            active = False
            dur = times[i] - times[start]
            if dur >= rule["min_sec"] and dur <= rule.get("max_sec", np.inf):
                out.append((times[start], times[i]))
    if active:
        dur = times[-1] - times[start]
        if dur >= rule["min_sec"] and dur <= rule.get("max_sec", np.inf):
            out.append((times[start], times[-1]))
    return out


class RulesDetector(Detector):
    name = "rules"
    version = "rules-prototype-0.1"

    def thresholds(self) -> dict:
        return {sig: {k: v for k, v in r.items() if k != "feature"} | {"feature": r["feature"]} for sig, r in RULES.items()}

    def events(self, ctx: Context) -> dict[str, list[tuple[float, float]]]:
        idx = {n: i for i, n in enumerate(catalog.SCORED_NAMES)}
        found = {}
        for sig, rule in RULES.items():
            series = ctx.raw[:, idx[rule["feature"]]].copy()
            if rule["mode"] == "displacement":
                series = np.abs(series - np.nanmedian(series))
            found[sig] = _intervals(series, ctx.times, rule)
        return found

    def predict(self, ctx: Context):
        found = self.events(ctx)
        out = []
        for m in ctx.moments:
            if not m.assessed:
                out.append(None)
                continue
            lo, hi = ctx.times[m.span[0]], ctx.times[m.span[-1]]
            hit = {sig: any(s < hi and e > lo for s, e in spans) for sig, spans in found.items()}
            fg = hit["eye"] or hit["lip"] or hit["jaw"]
            out.append({"FG": CategoryDecision(fg, float(fg), "rule"), "HM": CategoryDecision(hit["head"], float(hit["head"]), "rule")})
        return out
