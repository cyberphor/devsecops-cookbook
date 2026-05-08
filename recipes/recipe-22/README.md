# Deploy UDS Core


**Step 1.** Install k3d. k3d allows you to provision a multi-node k3s cluster on a single machine using docker. k3s is a lightweight Kubernetes distribution by Rancher. 
```bash
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

**Step 2.** Download the UDS CLI. 
```bash
wget -O uds https://github.com/defenseunicorns/uds-cli/releases/download/v0.30.0/uds-cli_v0.30.0_Linux_amd64 &&\
chmod +x uds &&\
sudo mv uds /usr/local/bin/
```

**Step 3.** Deploy UDS Core.
```bash
uds deploy k3d-core-slim-dev:latest
```
