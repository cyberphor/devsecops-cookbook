# ---------------------------------------------------------
# Misc.
# ---------------------------------------------------------

# Set the default goal.
.DEFAULT_GOAL := build

# Tell Docker to build images in parallel.
COMPOSE_BAKE := true

# Set the Docker Compose profile to "all" if an argument is not provided.
DOCKER_COMPOSE_PROFILE ?= all

# ---------------------------------------------------------
# Build the containers.
# ---------------------------------------------------------

.PHONY: build
.SILENT: build

build: 
	docker compose --profile $(DOCKER_COMPOSE_PROFILE) build --no-cache 

# ---------------------------------------------------------
# Start the containers.
# ---------------------------------------------------------

.PHONY: start
.SILENT: start

start:
	docker compose --profile $(DOCKER_COMPOSE_PROFILE) up -d

# ---------------------------------------------------------
# Stop the containers.
# ---------------------------------------------------------

.PHONY: stop
.SILENT: stop

stop: 
	docker compose --profile $(DOCKER_COMPOSE_PROFILE) down
