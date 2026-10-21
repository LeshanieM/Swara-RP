"""Severity tables. ORIGINAL and PROVISIONAL: not copied from SSI-4.

They must be calibrated against hand-counted %SS and SLP ratings before any
clinical reading. Bump SEVERITY_VERSION whenever a number changes, so stored
results stay traceable to the table that produced them.
"""
import math

SEVERITY_VERSION = "c1-severity-0.1-provisional"
SEVERITY_METHOD = "event-based %SS + duration term, scored per task (SSI-4-inspired audio-based estimate)"

# (upper bound of %SS, exclusive) -> frequency points. Reading is scored more
# strictly than picture description, the way readers and non-readers are
# scored separately in SSI-4-style instruments; age enters only through the task.
FREQUENCY_BANDS = {
    "reading": [(1.0, 0), (2.0, 2), (3.0, 4), (5.0, 6), (8.0, 8), (12.0, 10), (20.0, 12), (math.inf, 14)],
    "picture_description": [(1.5, 0), (3.0, 2), (5.0, 4), (8.0, 6), (12.0, 8), (18.0, 10), (25.0, 12), (math.inf, 14)],
}

# (upper bound of mean duration of the 3 longest moments, seconds, exclusive) -> points.
DURATION_BANDS = [(0.5, 1), (1.0, 2), (2.0, 3), (3.0, 4), (5.0, 5), (math.inf, 6)]

# Optional physical term from C2's concomitant score (0-1).
PHYSICAL_MAX_POINTS = 4

# Total points (inclusive upper bound) -> label.
LABEL_BANDS = [(3, "none_very_mild"), (9, "mild"), (15, "moderate"), (math.inf, "severe")]

DISPLAY = {
    "none_very_mild": "No / very mild stuttering detected",
    "mild": "Mild",
    "moderate": "Moderate",
    "severe": "Severe",
}

# MiMi (ICACRS 2022) chunk-ratio baseline: % of stuttered chunks.
# <=10 none, (10,40] beginner, (40,75] intermediate, >75 advanced.
MIMI_BANDS = [(10.0, "none_very_mild"), (40.0, "mild"), (75.0, "moderate"), (math.inf, "severe")]
