# Recipe 09: OpenTelemetry

**References**
* [OpenTelemetry Distro](https://opentelemetry.io/docs/languages/python/distro/)

**Notes**  
* If you wanted to simulate auto-instrumentation, you would remove `FastAPIInstrumentor.instrument_app(app)` from your `api.py` file and invoke the `api.py` file using the following command sentence: `opentelemetry-instrument python -m uvicorn api:app --host 0.0.0.0 --port 8080`

### OTEL Collector
**Step 1.** Create and open a file called `otel-collector-config.yaml`. 

**Step 2.** Add the content below to the `otel-collector-config.yaml` file.
```yaml
---
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
exporters:
  debug:
    verbosity: detailed
processors:
  batch:
service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [debug]
      processors: [batch]
```

**Step 3.** Start the OTEL Collector and leave the terminal window open. The purpose of leaving the terminal window open is so you monitor the telemetry data emitted from your OTEL agent.  
```bash
docker run -p 4317:4317 -v ./otel-collector-config.yaml:/etc/otel-collector-config.yaml otel/opentelemetry-collector --config=/etc/otel-collector-config.yaml
```

### OTEL Agent
**Step 1.** Open another terminal. 

**Step 2.** Create a virtual environment to house the OTEL agent's Python dependencies. 
```bash
python -m venv .venv
```

**Step 3.** Activate the OTEL agent's virtual environment. 
```bash
source .venv/bin/activate
```

**Step 4.** Install the OTEL agent's Python dependencies. 
```bash
python -m pip install -r requirements.txt
```

**Step 5.** Create and open a file called `api.py`.
```bash
vim api.py
```

**Step 6.** Add the content below to the `api.py` file.
```python
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
```

**Step 7.** Start the OTEL agent. 
```bash
python -m uvicorn api:app --host 0.0.0.0 --port 8080
```

**Step 8.** Submit a HTTP request to your OTEL agent. 
```bash
curl localhost:8080
```

You should get output similar to below. 
```
2024-04-28T14:20:46.080Z        info    ResourceSpans #0
Resource SchemaURL: 
Resource attributes:
     -> telemetry.sdk.language: Str(python)
     -> telemetry.sdk.name: Str(opentelemetry)
     -> telemetry.sdk.version: Str(1.24.0)
     -> telemetry.auto.version: Str(0.45b0)
     -> service.name: Str(unknown_service)
ScopeSpans #0
ScopeSpans SchemaURL: 
InstrumentationScope opentelemetry.instrumentation.asgi 0.45b0
Span #0
    Trace ID       : cd0a90314af460a2a2217f61940ee9a6
    Parent ID      : b974a217c4851887
    ID             : 1e03bfb5f97a38f1
    Name           : GET / http send
    Kind           : Internal
    Start time     : 2024-04-28 14:20:42.200992004 +0000 UTC
    End time       : 2024-04-28 14:20:42.201376962 +0000 UTC
    Status code    : Unset
    Status message : 
Attributes:
     -> http.status_code: Int(200)
     -> type: Str(http.response.start)
Span #1
    Trace ID       : cd0a90314af460a2a2217f61940ee9a6
    Parent ID      : b974a217c4851887
    ID             : 413db5c9a090ea04
    Name           : GET / http send
    Kind           : Internal
    Start time     : 2024-04-28 14:20:42.201464185 +0000 UTC
    End time       : 2024-04-28 14:20:42.201639031 +0000 UTC
    Status code    : Unset
    Status message : 
Attributes:
     -> type: Str(http.response.body)
Span #2
    Trace ID       : cd0a90314af460a2a2217f61940ee9a6
    Parent ID      : 
    ID             : b974a217c4851887
    Name           : GET /
    Kind           : Server
    Start time     : 2024-04-28 14:20:42.196769832 +0000 UTC
    End time       : 2024-04-28 14:20:42.201655732 +0000 UTC
    Status code    : Unset
    Status message : 
Attributes:
     -> http.scheme: Str(https)
     -> http.host: Str(127.0.0.1:8080)
     -> net.host.port: Int(8080)
     -> http.flavor: Str(1.1)
     -> http.target: Str(/)
     -> http.url: Str(https://127.0.0.1:8080/)
     -> http.method: Str(GET)
     -> http.server_name: Str(localhost:8080)
     -> http.user_agent: Str(Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36)
     -> net.peer.ip: Str(10.240.3.217)
     -> net.peer.port: Int(0)
     -> http.route: Str(/)
     -> api.response: Str(hi non sunt droids quam quaeritis)
     -> http.status_code: Int(200)
        {"kind": "exporter", "data_type": "traces", "name": "debug"}
```