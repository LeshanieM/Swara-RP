"""
Shared helper for writing an annotated overlay video (section 24).

Design choice: rather than re-decoding the video a second time purely for
visualization, each analyzer draws its overlay frame-by-frame *during* its
own single analysis pass (it already has the frame and the landmarks/pose
in hand at that point) and uses `OverlayWriter` to stream those frames to an
.mp4 file. This keeps "what's drawn" honest - it is only ever features that
technology actually produced (section 24: "Only display features actually
produced by the corresponding technology"), and avoids a second full video
decode per technology.

If OpenCV is unavailable, `OverlayWriter` becomes a no-op so analyzers don't
need special-case error handling - overlay generation is a best-effort
extra, never a reason to fail the whole analysis (section 30).
"""

from typing import Optional, Sequence, Tuple

Point = Tuple[float, float]


class OverlayWriter:
    def __init__(self, output_path: str, width: int, height: int, fps: float):
        self.output_path = output_path
        self.enabled = False
        self._writer = None
        try:
            import cv2  # noqa: F401

            self._cv2 = cv2
            fourcc = cv2.VideoWriter_fourcc(*"mp4v")
            self._writer = cv2.VideoWriter(output_path, fourcc, max(fps, 1.0), (width, height))
            self.enabled = self._writer.isOpened()
        except Exception:
            self.enabled = False

    def draw_points(self, frame, points_px: Sequence[Point], color=(0, 255, 0), radius=1):
        if not self.enabled:
            return frame
        for (x, y) in points_px:
            self._cv2.circle(frame, (int(x), int(y)), radius, color, -1)
        return frame

    def draw_lines(self, frame, lines_px, color=(255, 200, 0), thickness=1):
        if not self.enabled:
            return frame
        for (p1, p2) in lines_px:
            self._cv2.line(frame, (int(p1[0]), int(p1[1])), (int(p2[0]), int(p2[1])), color, thickness)
        return frame

    def put_text(self, frame, text: str, org=(10, 25), color=(255, 255, 255)):
        if not self.enabled:
            return frame
        self._cv2.putText(
            frame, text, org, self._cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 1, self._cv2.LINE_AA
        )
        return frame

    def write(self, frame):
        if self.enabled and self._writer is not None:
            self._writer.write(frame)

    def close(self) -> Optional[str]:
        if self.enabled and self._writer is not None:
            self._writer.release()
            return self.output_path
        return None
