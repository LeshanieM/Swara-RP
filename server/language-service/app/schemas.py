"""Request and response contract of the language service.

The Node API mirrors the response shapes in zod (modules/c4/validation/schemas.js)
and checks every response before saving it. Extra fields are allowed, so the
service can grow without breaking the API.
"""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

Source = Literal["asr", "corrected", "manual"]
EngineName = Literal["ctc", "whisper"]


class Open(BaseModel):
    model_config = ConfigDict(extra="allow")


class TimedWord(BaseModel):
    word: str = Field(min_length=1, max_length=200)
    start: float | None = Field(default=None, ge=0)
    end: float | None = Field(default=None, ge=0)
    confidence: float | None = Field(default=None, ge=0, le=1)


class C1Event(BaseModel):
    type: str
    start: float = Field(ge=0)
    end: float = Field(ge=0)


class C1Moment(BaseModel):
    start: float = Field(ge=0)
    end: float = Field(ge=0)


class MeasuresRequest(BaseModel):
    words: list[TimedWord] | None = Field(default=None, max_length=20000)
    text: str | None = Field(default=None, max_length=50000)
    source: Source = "asr"
    c1Events: list[C1Event] | None = None
    c1Moments: list[C1Moment] | None = None
    durationSec: float | None = Field(default=None, ge=0)
    pauseSec: float | None = Field(default=None, ge=0.2, le=5.0)

    @model_validator(mode="after")
    def _check(self):
        if self.words is None and self.text is None:
            raise ValueError("send words (timed ASR words) or text (a typed transcript)")
        if self.source == "asr" and self.text is not None:
            raise ValueError("source 'asr' takes words only; a typed text is 'corrected' or 'manual'")
        return self


class EvaluateRequest(BaseModel):
    reference: str = Field(min_length=1, max_length=50000)
    hypothesis: str = Field(max_length=50000)


class EngineOut(Open):
    name: str
    model: str
    repetitionPreserving: bool


class TranscriptionOut(Open):
    engine: EngineOut
    text: str
    words: list[TimedWord]
    wordTimings: Literal["ctc", "word", "segment"]
    audio: dict
    processingSec: float


class MeasuresOut(Open):
    mluWords: float | None
    ndw50: int | None
    ndwAll: int
    mattr25: float | None
    ttr: float | None
    totalWords: int
    totalTokens: int
    mazeTokens: int
    utteranceCount: int
    mluLabel: Literal["words"]


class UtteranceOut(Open):
    index: int
    start: float | None
    end: float | None
    text: str
    wordCount: int
    complexity: int
    mazeOnly: bool
    stutter: bool | None


class AnalysisOut(Open):
    methodVersion: str
    source: Source
    normalisedText: str
    cleanText: str
    tokens: list[dict]
    utterances: list[UtteranceOut]
    measures: MeasuresOut
    syllables: dict
    lexicon: list[dict]
    flags: list[str]


class AnalyzeLanguageOut(Open):
    transcription: TranscriptionOut | None
    analysis: AnalysisOut


class WordCheckOut(Open):
    decision: Literal["match", "mismatch", "unclear"]
    expected: str
    heard: str | None
    heardRaw: str
    similarity: float
    scores: dict
    confidence: float | None
    reasons: list[str]
    engine: dict
    methodVersion: str
