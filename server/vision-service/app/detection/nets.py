"""The two learned SRCD classifiers. Both read a moment's baseline-normalised
sequence (seq_len × n_input) and output two logits: FG and HM (multi-label,
as CASA labels them independently).

``audio_dim`` reserves the audio-visual branch: C1's pooled speech-encoder
features for the same span are concatenated before the output layer. It is 0
until C1's encoder features exist.

Imported only when a learned detector or the training script is used (needs torch).
"""
import torch
from torch import nn


class SRCDGru(nn.Module):
    """Small GRU (about 12k parameters at the defaults)."""

    def __init__(self, n_input: int, hidden: int = 48, audio_dim: int = 0, dropout: float = 0.1):
        super().__init__()
        self.gru = nn.GRU(n_input, hidden, batch_first=True)
        self.drop = nn.Dropout(dropout)
        self.head = nn.Linear(2 * hidden + audio_dim, 2)

    def forward(self, x, audio=None):
        seq, last = self.gru(x)
        pooled = torch.cat([last[-1], seq.max(dim=1).values], dim=1)
        if audio is not None:
            pooled = torch.cat([pooled, audio], dim=1)
        return self.head(self.drop(pooled))


class SRCDTransformer(nn.Module):
    """Small temporal transformer (about 18k parameters at the defaults)."""

    def __init__(self, n_input: int, seq_len: int, d_model: int = 32, heads: int = 4, layers: int = 2,
                 audio_dim: int = 0, dropout: float = 0.1):
        super().__init__()
        self.proj = nn.Linear(n_input, d_model)
        self.pos = nn.Parameter(torch.zeros(1, seq_len, d_model))
        layer = nn.TransformerEncoderLayer(d_model, heads, dim_feedforward=2 * d_model, dropout=dropout, batch_first=True)
        self.encoder = nn.TransformerEncoder(layer, layers)
        self.head = nn.Linear(2 * d_model + audio_dim, 2)

    def forward(self, x, audio=None):
        h = self.encoder(self.proj(x) + self.pos[:, : x.shape[1]])
        pooled = torch.cat([h.mean(dim=1), h.max(dim=1).values], dim=1)
        if audio is not None:
            pooled = torch.cat([pooled, audio], dim=1)
        return self.head(pooled)


def build(arch: str, n_input: int, seq_len: int, **kw) -> nn.Module:
    if arch == "gru":
        return SRCDGru(n_input, **kw)
    if arch == "transformer":
        return SRCDTransformer(n_input, seq_len, **kw)
    raise ValueError(f"unknown architecture {arch!r}")


def n_params(model: nn.Module) -> int:
    return sum(p.numel() for p in model.parameters())
