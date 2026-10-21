"""Contract of POST /analyze-video (mirrored by the Node API's validator)."""
from typing import Literal

from pydantic import BaseModel, Field

Category = Literal["FG", "HM"]
Signal = Literal["eye", "lip", "jaw", "cheek", "head"]


class StutterMomentIn(BaseModel):
    start: float = Field(ge=0)
    end: float = Field(gt=0)
    types: list[str] = []


class VideoInfo(BaseModel):
    durationSec: float
    fps: float
    width: int
    height: int
    container: str
    codec: str
    hasAudio: bool
    analysedFps: float
    framesRead: int
    framesAnalysed: int
    faceDetectedRatio: float


class DetectorInfo(BaseModel):
    name: str
    version: str
    requested: str
    fallback: bool
    fallbackReason: str | None = None
    thresholds: dict


class BaselineInfo(BaseModel):
    source: Literal["fluent_spans", "whole_recording"]
    frames: int
    durationSec: float
    guardSec: float
    holdFrames: int  # a deviation must hold this many consecutive frames


class CategoryOut(BaseModel):
    present: bool
    score: float
    scoreType: Literal["deviation_sd", "rule", "probability"]


class SignalOut(BaseModel):
    deviation: float
    direction: Literal["above", "below"]
    topFeature: str
    threshold: float
    pValue: float | None
    nullSpans: int
    exceeds: bool


class MomentOut(BaseModel):
    index: int
    start: float
    end: float
    duration: float
    types: list[str]
    faceRatio: float
    assessed: bool
    behaviourPresent: bool | None
    categories: dict[Category, CategoryOut] | None
    signals: dict[Signal, SignalOut] | None
    explanation: list[str]


class BehaviourEvent(BaseModel):
    category: Category
    signal: Signal
    feature: str
    start: float
    end: float
    duration: float
    peakDeviation: float
    direction: Literal["above", "below"]
    momentIndex: int


class Counts(BaseModel):
    momentsTotal: int
    momentsAssessed: int
    momentsWithBehaviour: int
    FG: int
    HM: int
    behaviourEvents: int


class PerStutter(BaseModel):
    FG: float | None
    HM: float | None
    any: float | None


class RulesBaseline(BaseModel):
    version: str
    momentsWithBehaviour: int
    FG: int
    HM: int
    perMoment: list[dict[Category, bool] | None]


class Baselines(BaseModel):
    rules: RulesBaseline


class Summary(BaseModel):
    assessed: bool
    hasSecondaryBehaviors: bool | None
    behaviourTypes: list[Category]
    momentsWithBehaviour: int
    momentsAssessed: int


class Warning(BaseModel):
    code: str
    message: str


class AnalysisResponse(BaseModel):
    video: VideoInfo
    detector: DetectorInfo
    baseline: BaselineInfo
    stutterMoments: list[MomentOut]
    behaviourEvents: list[BehaviourEvent]
    counts: Counts
    behavioursPerStutter: PerStutter
    hasSecondaryBehaviors: bool | None
    concomitantScore: float | None
    baselines: Baselines
    summary: Summary
    frames: dict | None = None
    warnings: list[Warning]
    processingMs: int
    serviceVersion: str
