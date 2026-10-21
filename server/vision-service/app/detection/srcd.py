"""Label-free SRCD (default): a category is present when one of its signals beats
the child's own fluent stretches (see ``srcd/deviation.py``). No training data."""
from app.detection.base import CategoryDecision, Context, Detector
from app.features import catalog


class LabelFreeSRCD(Detector):
    name = "srcd"
    version = "srcd-labelfree-0.2"

    def __init__(self, alpha: float, min_sd: float, min_deviation_sec: float):
        self.alpha, self.min_sd, self.min_deviation_sec = alpha, min_sd, min_deviation_sec

    def thresholds(self) -> dict:
        return {"nullAlphaPerCategory": self.alpha, "minDeviationSd": self.min_sd, "minDeviationSec": self.min_deviation_sec,
                "null": "same-length stretches of the child's fluent speech; exponential tail above p80; Bonferroni over the category's features"}

    def predict(self, ctx: Context):
        out = []
        for m in ctx.moments:
            if not m.assessed:
                out.append(None)
                continue
            decisions = {}
            for cat in catalog.CATEGORIES:
                sigs = [s for name, s in m.signals.items() if catalog.CATEGORY_OF_SIGNAL[name] == cat]
                score = max(s.deviation for s in sigs)
                decisions[cat] = CategoryDecision(any(s.present for s in sigs), round(score, 2), "deviation_sd")
            out.append(decisions)
        return out
