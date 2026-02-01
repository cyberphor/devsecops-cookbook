## Recipe 20: Policy-as-Code

## Setup
**Step 1.** Install `syft`.
```bash
curl -sSfL https://get.anchore.io/syft | sudo sh -s -- -b /usr/local/bin
```

**Step 2.** Install `grype`.
```bash
curl -sSfL https://get.anchore.io/grype | sudo sh -s -- -b /usr/local/bin
```

**Step 3.** Install `vexctl`.
```bash
go install github.com/openvex/vexctl@latest
```

**Step 4.** Install `kubectl`.
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Step 5.** Install `kind`.
```bash
go install sigs.k8s.io/kind@v0.31.0
```

**Step 6.** Install the Kyverno CLI.
```bash
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.12.0/kyverno-cli_v1.12.0_linux_x86_64.tar.gz
tar -xvf kyverno-cli_v1.12.0_linux_x86_64.tar.gz
sudo cp kyverno /usr/local/bin/
```

## Provision a Kubernetes Cluster
**Step 1.** Create a Kubernetes cluster called `demo`.
```bash
kind create cluster --name demo --image kindest/node:v1.34.0 --config cluster-config.yml
```

**Step 2.** Confirm the version of your Kubernetes cluster.
```bash
kubectl version
```

You should get output similar to below.
```
Client Version: v1.35.0
Kustomize Version: v5.7.1
Server Version: v1.34.0
```

**Step 3.** Print cluster information.
```bash
kubectl cluster-info
```

You should get output similar to below.
```
Kubernetes control plane is running at https://127.0.0.1:38167
CoreDNS is running at https://127.0.0.1:38167/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

**Step 4.** List resources on your cluster.
```bash
kubectl get all --all-namespaces
```

## Create an SBOM and VEX File
**Step 1.** Create an SBOM.
```bash
syft vulnerables/web-dvwa -o cyclonedx-json=sbom.json
```

**Step 2.** Scan an SBOM.
```bash
grype sbom:sbom.json -o cyclonedx-json=scan.json
```

**Step 3.** Create a VEX document. `vexctl` supports the following justifications:  `component_not_present`, `vulnerable_code_not_present`, `vulnerable_code_not_in_execute_path`, `vulnerable_code_cannot_be_controlled_by_adversary`, and `inline_mitigations_already_exist`.

## Kyverno
**Step 1.** Install Kyverno on the Kubernetes cluster.
```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.1/install.yaml
```

**Step 2.** Create a cluster policy.

**Step 3.** Apply the cluster policy.
```bash
kyverno apply policy.yml --cluster
```

You should get output similar to below.
```
Applying 3 policy rule(s) to 37 resource(s)...

pass: 37, fail: 0, warn: 0, error: 0, skip: 0 
```

**Step 4.** Test the cluster policy.

## References
**kind: Using WSL2**  
https://kind.sigs.k8s.io/docs/user/using-wsl2/#accessing-a-kubernetes-service-running-in-wsl2
