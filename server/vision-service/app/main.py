"""Swara C2 vision service: stutter-locked, speaker-relative secondary-behaviour analysis (SRCD).

Run from the vision-service folder:
    .venv/bin/uvicorn app.main:app --port 8011
"""
import logging

from fastapi import FastAPI

from app import errors
from app.api.routes import router
from app.config import SERVICE_VERSION

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

app = FastAPI(title="Swara C2 vision service", version=SERVICE_VERSION)
errors.install(app)
app.include_router(router)
