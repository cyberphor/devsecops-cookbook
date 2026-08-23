# ---------------------------------------------------------
# Set the default target.
# ---------------------------------------------------------

.DEFAULT_GOAL := create-and-deploy

# ---------------------------------------------------------
# Create and deploy the Zarf package.
# ---------------------------------------------------------

.PHONY: create-and-deploy
.SILENT: create-and-deploy

create-and-deploy: remove
	uds zarf package create --confirm &&\
	uds zarf package deploy zarf-package-sonic-amd64-v0.1.0.tar.zst --confirm

# ---------------------------------------------------------
# Remove the Zarf package.
# ---------------------------------------------------------

.PHONY: remove
.SILENT: remove
remove: 
	uds zarf package remove sonic --confirm || true
	uds zarf tools kubectl delete namespace sonic || true
