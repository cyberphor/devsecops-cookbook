"""Defines an Application Programming Interface (API) for a FastAPI app"""

# import third-party modules
from fastapi import FastAPI
from typing import Dict
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# define the FastAPI app
api = FastAPI()

# define OTEL settings
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)
otlp_exporter = OTLPSpanExporter()
span_processor = BatchSpanProcessor(otlp_exporter)
otlp_tracer = trace.get_tracer_provider().add_span_processor(span_processor)
FastAPIInstrumentor.instrument_app(api,tracer_provider=otlp_tracer)

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