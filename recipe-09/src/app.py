"""Defines an Application Programming Interface (API) for a FastAPI app"""

# import third-party modules
from fastapi import FastAPI
from typing import Dict

# define the FastAPI app
api = FastAPI()

# define a handler for the "root" endpoint
@api.get("/")
def root() -> Dict[str, str]:
    """Returns some data."""
    return {"data": "hi non sunt droids quam quaeritis"}

# define a handler for the "healthcheck" endpoint
@api.get("/healthcheck")
def healthcheck() -> Dict[str, str]:
    """Confirms the FastAPI server works."""
    return {"status": "OK"}
