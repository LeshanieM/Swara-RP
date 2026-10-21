"""Response contract of POST /analyze-speech (mirrored by the Node API's validator)."""
from typing import Literal

from pydantic import BaseModel, Field

TaskType = Literal["reading", "picture_description"]
Language = Literal["si", "en"]
EventType = Literal["block", "prolongation", "sound_repetition", "word_repetition", "interjection"]
SeverityLabel = Literal["none_very_mild", "mild", "moderate", "severe"]


class AudioInfo(BaseModel):
    durationSec: float
    sampleRate: int
    originalSampleRate: int
    channels: int
    format: str


class DetectorInfo(BaseModel):
    name: str
    version: str
    requested: str
    fallback: bool
    fallbackReason: str | None = None


class WindowInfo(BaseModel):
    sizeSec: float
    hopSec: float
    threshold: float
    count: int


class EventOut(BaseModel):
    type: EventType
    start: float
    end: float
    duration: float
    confidence: float


class MomentOut(BaseModel):
    start: float
    end: float
    duration: float
    types: list[EventType]


class Counts(BaseModel):
    block: int = 0
    prolongation: int = 0
    soundRepetition: int = 0
    wordRepetition: int = 0
    interjection: int = 0


class Syllables(BaseModel):
    total: int
    source: Literal["passage", "transcript", "estimated"]
    estimatedFromAudio: int
    fromText: int | None = None


class DurationTerm(BaseModel):
    meanLongest3Sec: float
    longestSec: float
    eventsUsed: int


class SeverityComponents(BaseModel):
    frequencyPoints: int
    durationPoints: int
    physicalPoints: int


class Severity(BaseModel):
    label: SeverityLabel
    displayLabel: str
    score: int
    maxScore: int
    components: SeverityComponents
    belowFrequencyFloor: bool
    physicalTermUsed: bool
    taskType: TaskType
    method: str
    version: str
    provisional: bool


class MimiBaseline(BaseModel):
    stutteredChunks: int
    totalChunks: int
    ratioPercent: float
    label: SeverityLabel


class Baselines(BaseModel):
    mimiChunkRatio: MimiBaseline


class Features(BaseModel):
    duration: float
    speechDuration: float
    pauseCount: int
    averagePauseDuration: float
    longestPause: float
    speechRate: float
    articulationRate: float
    estimatedSyllables: int


class LegacySummary(BaseModel):
    """Same shape as the app's earlier mock, so the current result card can bind to it."""

    stutterDetected: bool
    stutterType: Literal["Repetition", "Prolongation", "Block", "Mixed", "None"]
    severity: Literal["None", "Mild", "Moderate", "Severe"]
    confidence: float


class Warning(BaseModel):
    code: str
    message: str


class WindowScore(BaseModel):
    start: float
    end: float
    scores: dict[str, float]


class AnalysisResponse(BaseModel):
    taskType: TaskType
    language: Language
    audio: AudioInfo
    detector: DetectorInfo
    windows: WindowInfo
    events: list[EventOut]
    stutterMoments: list[MomentOut]
    counts: Counts
    primaryType: EventType | None
    syllables: Syllables
    stutteredSyllables: int
    percentSS: float
    durationTerm: DurationTerm
    severity: Severity
    baselines: Baselines
    features: Features
    summary: LegacySummary
    warnings: list[Warning] = Field(default_factory=list)
    windowScores: list[WindowScore] | None = None
    processingMs: int
    serviceVersion: str
