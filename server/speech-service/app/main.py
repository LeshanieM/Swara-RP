"""Swara C1 speech service: stutter-event detection and event-based severity.

Run from the speech-service folder:
    .venv/bin/uvicorn app.main:app --port 8010
"""
import logging

from fastapi import FastAPI

from app import errors
from app.api.routes import router
from app.config import SERVICE_VERSION

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

app = FastAPI(title="Swara C1 speech service", version=SERVICE_VERSION)
errors.install(app)
app.include_router(router)
