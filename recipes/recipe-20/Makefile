# ---------------------------------------------------------
# Set the default target.
# ---------------------------------------------------------

.DEFAULT_GOAL := build

# ---------------------------------------------------------
# Load environment variables.
# ---------------------------------------------------------
ENV_FILE ?= .env
include $(ENV_FILE)

# ---------------------------------------------------------
# Install the binaries required.
# ---------------------------------------------------------

.PHONY: setup
.SILENT: setup

setup:
	@command -v syft >/dev/null 2>&1 || (curl -sSfL https://get.anchore.io/syft | sudo sh -s -- -b /usr/local/bin)
	@command -v grype >/dev/null 2>&1 || (curl -sSfL https://get.anchore.io/grype | sudo sh -s -- -b /usr/local/bin)
	@command -v kubectl >/dev/null 2>&1 || (curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl)
	@command -v kyverno >/dev/null 2>&1 || (curl -LO https://github.com/kyverno/kyverno/releases/download/v1.12.0/kyverno-cli_v1.12.0_linux_x86_64.tar.gz && tar -xvf kyverno-cli_v1.12.0_linux_x86_64.tar.gz && sudo mv kyverno /usr/local/bin/ && rm kyverno-cli_v1.12.0_linux_x86_64.tar.gz)

# ---------------------------------------------------------
# Create a container registry.
# ---------------------------------------------------------

.PHONY: registry
.SILENT: registry

registry:
	@if [ ! -f $(REGISTRY_NAME).crt ]; then \
		openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
		-out "$(REGISTRY_NAME).crt" -keyout "$(REGISTRY_NAME).key" \
		-subj "/CN=$(REGISTRY_NAME)" -addext "subjectAltName=DNS:$(REGISTRY_NAME),DNS:localhost"; \
	fi
	@sudo cp $(REGISTRY_NAME).crt /usr/local/share/ca-certificates/$(REGISTRY_NAME).crt
	@sudo update-ca-certificates
	@docker ps -a --format '{{.Names}}' | grep -q "^$(REGISTRY_NAME)$$" || \
		docker run -d --name $(REGISTRY_NAME) -p $(REGISTRY_PORT):$(REGISTRY_INTERNAL_PORT) \
		-v $$(pwd)/$(REGISTRY_NAME).crt:/certs/domain.crt -v $$(pwd)/$(REGISTRY_NAME).key:/certs/domain.key \
		-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key registry:3

# ---------------------------------------------------------
# Create a Kubernetes Cluster.
# ---------------------------------------------------------

.PHONY: cluster
.SILENT: cluster

cluster:
	@kind get clusters | grep -q "^$(CLUSTER_NAME)$$" || \
		kind create cluster --name $(CLUSTER_NAME) --image kindest/node:v1.34.0 --config cluster.yaml
	@docker cp $(REGISTRY_NAME).crt $(CLUSTER_NAME)-control-plane:/usr/local/share/ca-certificates/
	@docker exec $(CLUSTER_NAME)-control-plane update-ca-certificates

# ---------------------------------------------------------
# Connect the Kubernetes cluster to the container registry.
# ---------------------------------------------------------

.PHONY: connect
.SILENT: connect

connect:
	@docker network inspect kind >/dev/null 2>&1 || (echo "Kind network not found" && exit 1)
	@docker network inspect kind | jq -e '.[0].Containers[] | select(.Name=="$(REGISTRY_NAME)")' >/dev/null 2>&1 || \
		docker network connect kind $(REGISTRY_NAME)

# ---------------------------------------------------------
# Install Kyverno.
# ---------------------------------------------------------

.PHONY: kyverno
.SILENT: kyverno

kyverno:
	@helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update
	@kubectl get namespace kyverno >/dev/null 2>&1 || \
		helm install kyverno kyverno/kyverno --create-namespace -n kyverno -f kyverno-values.yaml

# ---------------------------------------------------------
# Apply a Kyverno policy.
# ---------------------------------------------------------

.PHONY: policy
.SILENT: policy

policy:
	@kubectl apply -f kyverno-policy.yaml

# ---------------------------------------------------------
# Push the container image to the container registry.
# ---------------------------------------------------------

.PHONY: push
.SILENT: push

push:
	@docker pull vulnerables/web-dvwa:latest
	@docker tag vulnerables/web-dvwa:latest localhost:${REGISTRY_PORT}/web-dvwa:latest
	@docker push localhost:${REGISTRY_PORT}/web-dvwa:latest

# ---------------------------------------------------------
# Build.
# ---------------------------------------------------------

.PHONY: build
.SILENT: build

build: setup registry cluster connect kyverno policy push

# ---------------------------------------------------------
# Clean.
# ---------------------------------------------------------

.PHONY: clean
.SILENT: clean

clean:
	kind delete cluster --name $(CLUSTER_NAME)
	docker rm -f $(REGISTRY_NAME)
	rm -f *.json *.crt *.key *.pub
