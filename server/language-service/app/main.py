"""Swara C4 language service: Sinhala ASR that keeps repetitions, maze removal and language measures.

Run from the language-service folder:
    .venv/bin/uvicorn app.main:app --port 8012
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app import errors
from app.api.routes import router
from app.asr import registry
from app.config import SERVICE_VERSION, get_settings

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")


@asynccontextmanager
async def lifespan(_: FastAPI):
    if get_settings().preload:
        registry.preload()
    yield


app = FastAPI(title="Swara C4 language service", version=SERVICE_VERSION, lifespan=lifespan)
errors.install(app)
app.include_router(router)
