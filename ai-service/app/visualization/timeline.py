"""
Timeline visualization (section 25).

Two outputs, both generated purely from the detected-event timestamps that
are already in each technology's standardized result - never a generic
static placeholder image:

  1. `build_timeline_data()` - a compact JSON structure meant to be rendered
     client-side (the Flutter app draws the actual timeline UI natively,
     which looks better and is themeable, rather than embedding a server
     rendered bitmap in a mobile UI).
  2. `render_timeline_svg()` - a small dependency-free SVG (hand-built, no
     matplotlib/plotting library required) as a portable fallback that can
     be opened directly or embedded in a research report.
"""

from typing import Any, Dict, List

from app.config.settings import BEHAVIORS

_ROW_COLORS = {
    "eye_blink": "#2563EB",
    "lip_movement": "#7C3AED",
    "jaw_movement": "#DB2777",
    "facial_movement": "#059669",
    "head_movement": "#D97706",
    "hand_movement": "#DC2626",
    "arm_movement": "#0891B2",
}


def build_timeline_data(technology_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Returns { technology: { behavior: [ {start_time,end_time,duration}, ... ] } }
    plus the overall video duration used to scale any client-side chart."""
    max_duration = 0.0
    per_tech: Dict[str, Any] = {}
    for result in technology_results:
        tech = result.get("technology")
        duration = (result.get("video") or {}).get("duration") or 0.0
        max_duration = max(max_duration, duration)
        behaviors = result.get("behaviors", {})
        per_tech[tech] = {
            b: behaviors.get(b, {}).get("events", []) for b in BEHAVIORS if behaviors.get(b, {}).get("events")
        }
    return {"video_duration": max_duration, "technologies": per_tech}


def render_timeline_svg(technology: str, behaviors: Dict[str, Any], video_duration: float, width: int = 900) -> str:
    """Builds a simple SVG Gantt-style timeline for one technology's
    detected events. `behaviors` is that technology's `behaviors` dict from
    the standardized result."""
    row_height = 34
    left_margin = 130
    top_margin = 30
    active_rows = [b for b in BEHAVIORS if behaviors.get(b, {}).get("events")]
    height = top_margin + row_height * max(len(active_rows), 1) + 30
    duration = max(video_duration, 0.01)
    plot_width = width - left_margin - 20

    def x_for(t):
        return left_margin + (t / duration) * plot_width

    svg_parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" font-family="sans-serif">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#FAF7F1"/>',
        f'<text x="{left_margin}" y="18" font-size="14" font-weight="bold" fill="#1B2433">'
        f"{technology} — event timeline</text>",
    ]

    # time axis ticks (every ~1s, capped at 10 ticks)
    n_ticks = min(10, max(2, int(duration)))
    for i in range(n_ticks + 1):
        t = duration * i / n_ticks
        x = x_for(t)
        svg_parts.append(
            f'<line x1="{x:.1f}" y1="{top_margin - 4}" x2="{x:.1f}" y2="{height - 20}" '
            f'stroke="#DDD6C8" stroke-width="1"/>'
        )
        svg_parts.append(
            f'<text x="{x:.1f}" y="{height - 6}" font-size="10" fill="#5A6472" text-anchor="middle">'
            f"{t:.1f}s</text>"
        )

    for row_idx, behavior in enumerate(active_rows):
        y = top_margin + row_idx * row_height
        color = _ROW_COLORS.get(behavior, "#2563EB")
        svg_parts.append(
            f'<text x="4" y="{y + row_height / 2 + 4:.1f}" font-size="12" fill="#1B2433">'
            f'{behavior.replace("_", " ")}</text>'
        )
        for event in behaviors[behavior]["events"]:
            x1 = x_for(event["start_time"])
            x2 = x_for(event["end_time"])
            bar_width = max(x2 - x1, 2)
            svg_parts.append(
                f'<rect x="{x1:.1f}" y="{y + 6}" width="{bar_width:.1f}" height="{row_height - 14}" '
                f'rx="3" fill="{color}" opacity="0.85"/>'
            )

    svg_parts.append("</svg>")
    return "\n".join(svg_parts)
