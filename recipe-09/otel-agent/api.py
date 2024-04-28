"""Defines an Application Programming Interface (API) for a FastAPI app"""

# import third-party modules
from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from typing import Dict

# declare and initialize the FastAPI app
app = FastAPI()

# instrument the FastAPI app
FastAPIInstrumentor.instrument_app(app)

# define a handler for the "root" endpoint
@app.get("/")
def root() -> Dict[str, str]:
    """Returns some data."""
    response = "hi non sunt droids quam quaeritis"
    current_span = trace.get_current_span()
    current_span.set_attribute("api.response", response)
    return {"data": response}

# define a handler for the "healthcheck" endpoint
@app.get("/healthcheck")
def healthcheck() -> Dict[str, str]:
    """Confirms the FastAPI server works."""
    response = "OK"
    current_span = trace.get_current_span()
    current_span.set_attribute("api.response", response)
    return {"status": "OK"}