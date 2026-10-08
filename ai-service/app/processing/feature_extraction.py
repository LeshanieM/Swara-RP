"""
Shared geometry helpers for turning 2D facial/body landmarks into the
per-frame scalar "visual features" described in section 10 of the spec.

These functions are deliberately technology-agnostic: they operate on plain
(x, y) point tuples, not on a particular library's landmark object, so that
any analyzer producing landmarks in a compatible layout (MediaPipe,
OpenFace, OpenSeeFace, ...) can reuse the same, consistently-implemented
math instead of each analyzer re-deriving its own slightly different
formula. Differences in the resulting numbers should reflect differences in
the underlying tracking, not differences in how we compute EAR.

All functions expect points already normalized to the frame (i.e. in [0, 1]
x/y, or at least in a consistent unit) unless noted otherwise, so outputs
are comparable across videos of different resolutions.
"""

import math
from typing import List, Optional, Sequence, Tuple

Point = Tuple[float, float]


def euclidean(p1: Point, p2: Point) -> float:
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])


def eye_aspect_ratio(eye_points: Sequence[Point]) -> float:
    """
    Standard 6-point Eye Aspect Ratio (Soukupova & Cech, 2016):

        EAR = (||p2-p6|| + ||p3-p5||) / (2 * ||p1-p4||)

    `eye_points` must be ordered:
        [left_corner, top_1, top_2, right_corner, bottom_2, bottom_1]
    i.e. p1..p6 going around the eye starting at the outer corner.
    Returns a value that drops sharply during a blink (open ~0.25-0.35,
    closed ~< 0.1-0.15 typically, hence the default threshold of ~0.21).
    """
    if len(eye_points) != 6:
        raise ValueError("eye_aspect_ratio expects exactly 6 points")
    p1, p2, p3, p4, p5, p6 = eye_points
    vertical = euclidean(p2, p6) + euclidean(p3, p5)
    horizontal = 2.0 * euclidean(p1, p4)
    if horizontal == 0:
        return 0.0
    return vertical / horizontal


def mouth_opening_width(
    top_lip: Point, bottom_lip: Point, left_corner: Point, right_corner: Point, face_scale: float
) -> Tuple[float, float]:
    """
    Returns (normalized_opening, normalized_width): vertical mouth opening
    and horizontal mouth width, each divided by `face_scale` (a stable
    face-size reference, e.g. inter-ocular distance or face bounding-box
    diagonal) so the values are comparable across frames/videos regardless
    of how close the child is to the camera.
    """
    if face_scale <= 0:
        return 0.0, 0.0
    opening = euclidean(top_lip, bottom_lip) / face_scale
    width = euclidean(left_corner, right_corner) / face_scale
    return opening, width


def jaw_opening(chin: Point, upper_lip_or_nose: Point, face_scale: float) -> float:
    """Normalized vertical distance used as a proxy for jaw opening."""
    if face_scale <= 0:
        return 0.0
    return euclidean(chin, upper_lip_or_nose) / face_scale


def mean_landmark_displacement(
    prev_points: Sequence[Point], curr_points: Sequence[Point], face_scale: float
) -> float:
    """
    Mean per-landmark displacement between two consecutive frames,
    normalized by `face_scale`. Used as a generic "facial movement"
    magnitude signal when no more specific feature (blink/lip/jaw) applies.
    """
    if not prev_points or not curr_points or len(prev_points) != len(curr_points) or face_scale <= 0:
        return 0.0
    total = sum(euclidean(a, b) for a, b in zip(prev_points, curr_points))
    return (total / len(prev_points)) / face_scale


def estimate_head_pose(
    image_points: Sequence[Point], image_width: int, image_height: int
) -> Optional[Tuple[float, float, float]]:
    """
    Estimate (yaw, pitch, roll) in degrees from 6 canonical 2D landmark
    points using OpenCV's solvePnP against a generic 3D face model. This is
    the standard head-pose-from-landmarks approach used across dlib/
    MediaPipe head-pose tutorials; it does not require a technology-specific
    calibrated camera and is accurate enough for detecting *sudden head
    movement events*, which is what section 10/section 6 ask for (this is
    not a metrically precise pose estimate).

    `image_points` must be pixel coordinates (not normalized) ordered:
        [nose_tip, chin, left_eye_outer_corner, right_eye_outer_corner,
         left_mouth_corner, right_mouth_corner]

    Returns None if OpenCV is unavailable or solvePnP fails to converge.
    """
    try:
        import cv2
        import numpy as np
    except ImportError:
        return None

    if len(image_points) != 6:
        raise ValueError("estimate_head_pose expects exactly 6 points")

    model_points = np.array(
        [
            (0.0, 0.0, 0.0),  # nose tip
            (0.0, -330.0, -65.0),  # chin
            (-225.0, 170.0, -135.0),  # left eye outer corner
            (225.0, 170.0, -135.0),  # right eye outer corner
            (-150.0, -150.0, -125.0),  # left mouth corner
            (150.0, -150.0, -125.0),  # right mouth corner
        ],
        dtype="double",
    )

    focal_length = image_width
    center = (image_width / 2, image_height / 2)
    camera_matrix = np.array(
        [[focal_length, 0, center[0]], [0, focal_length, center[1]], [0, 0, 1]], dtype="double"
    )
    dist_coeffs = np.zeros((4, 1))

    img_pts = np.array(image_points, dtype="double")

    success, rotation_vector, _translation_vector = cv2.solvePnP(
        model_points, img_pts, camera_matrix, dist_coeffs, flags=cv2.SOLVEPNP_ITERATIVE
    )
    if not success:
        return None

    rmat, _ = cv2.Rodrigues(rotation_vector)
    return rotation_matrix_to_euler_deg(rmat)


def rotation_matrix_to_euler_deg(rmat) -> Tuple[float, float, float]:
    """
    Decompose a 3x3 rotation matrix into (yaw, pitch, roll) in degrees.
    Shared by `estimate_head_pose` (solvePnP-based, used by analyzers that
    only have 2D landmarks) and any analyzer that already has a rotation
    matrix directly available (e.g. MediaPipe's Tasks API
    `facial_transformation_matrixes`, whose top-left 3x3 block is exactly
    this rotation matrix) - so both paths report head angles the same way.
    """
    sy = math.sqrt(rmat[0][0] ** 2 + rmat[1][0] ** 2)
    singular = sy < 1e-6
    if not singular:
        pitch = math.degrees(math.atan2(rmat[2][1], rmat[2][2]))
        yaw = math.degrees(math.atan2(-rmat[2][0], sy))
        roll = math.degrees(math.atan2(rmat[1][0], rmat[0][0]))
    else:
        pitch = math.degrees(math.atan2(-rmat[1][2], rmat[1][1]))
        yaw = math.degrees(math.atan2(-rmat[2][0], sy))
        roll = 0.0
    return yaw, pitch, roll


def wrist_or_joint_velocity(positions: Sequence[Point], timestamps: Sequence[float], scale: float) -> List[float]:
    """Normalized per-frame speed of a single tracked joint (wrist, elbow,
    etc), in scale-normalized units/second."""
    if scale <= 0 or len(positions) < 2:
        return [0.0] * len(positions)
    out = [0.0]
    for i in range(1, len(positions)):
        dt = timestamps[i] - timestamps[i - 1]
        if dt <= 0:
            out.append(0.0)
            continue
        d = euclidean(positions[i], positions[i - 1]) / scale
        out.append(d / dt)
    return out
