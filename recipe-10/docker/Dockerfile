# Dockerfile metadata
FROM python:3.10
LABEL Author="Victor Fernandez III, @cyberphor"

# set the working directory
WORKDIR /src/

# install Python dependencies
COPY requirements.txt requirements.txt
RUN python -m pip install -r requirements.txt

# copy the source code
COPY api.py api.py

# using Uvicorn invoke the FastAPI object defined in app.py that is called API
CMD ["python", "-m", "uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]