## Recipe 20: Policy-as-Code
* [Setup](#setup)
* [Initialize Your Environment Variables](#initialize-your-environment-variables)
* [Deploy a Container Registry](#deploy-a-container-registry)
* [Deploy a Kubernetes Cluster](#deploy-a-kubernetes-cluster)
* [Connect the Kubernetes Cluster to the Container Registry](#connect-the-kubernetes-cluster-to-the-container-registry)
* [Create an SBOM and VEX Document](#create-an-sbom-and-vex-document)
* [Tag and Pug the Container Image to the Container Registry](#tag-and-pug-the-container-image-to-the-container-registry)
* [Create Attestations that Link the SBOM and VEX Documents to the Container Image](#create-attestations-that-link-the-sbom-and-vex-documents-to-the-container-image)
* [Deploy a Container on the Kubernetes Cluster](#deploy-a-container-on-the-kubernetes-cluster)
* [Create and Apply Kyverno Policy](#create-and-apply-kyverno-policy)
* [References](#references)

## Setup
**Step 1.** Install `syft`.
```bash
curl -sSfL https://get.anchore.io/syft | sudo sh -s -- -b /usr/local/bin
```

**Step 2.** Install `grype`.
```bash
curl -sSfL https://get.anchore.io/grype | sudo sh -s -- -b /usr/local/bin
```

**Step 3.** Install `go`.
```bash
wget https://go.dev/dl/go1.26.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.26.0.linux-amd64.tar.gz
rm go1.26.0.linux-amd64.tar.gz
```

**Step 4.** Install `vexctl`.
```bash
go install github.com/openvex/vexctl@latest
```

**Step 5.** Install `cosign`.
```bash
go install github.com/sigstore/cosign/v2/cmd/cosign@latest
```

**Step 6.** Install `docker` using [instructions online](https://docs.docker.com/engine/install).

**Step 7.** Install `kubectl`.
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Step 8.** Install `helm`.
```bash
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

**Step 9.** Install `kind`.
```bash
go install sigs.k8s.io/kind@v0.31.0
```

**Step 10.** Install the Kyverno CLI.
```bash
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.12.0/kyverno-cli_v1.12.0_linux_x86_64.tar.gz
tar -xvf kyverno-cli_v1.12.0_linux_x86_64.tar.gz
sudo mv kyverno /usr/local/bin/
rm kyverno-cli_v1.12.0_linux_x86_64.tar.gz
```

## Initialize Your Environment Variables
**Step 1.** Initialize all the environment variables that will be used. The `REGISTRY_PORT` environment variable must be set to an port number that doesn't conflict the port Docker is listening on (i.e., you cannot use `5000`). 
```bash
export REGISTRY_NAME="demo-registry"
export REGISTRY_PORT="5001"
export REGISTRY_INTERNAL_PORT="5000"
export REGISTRY_DIR="/etc/containerd/certs.d/${REGISTRY_NAME}:${REGISTRY_INTERNAL_PORT}"
export CLUSTER_NAME="demo-cluster"
export COSIGN_INSECURE="true"
```

## Deploy a Container Registry
**Step 1.** Deploy a container registry locally called using `docker`.
```bash
docker run -d -p ${REGISTRY_PORT}:5000 --restart=always --name $REGISTRY_NAME registry:3
```

**Step 2.** Verify the container registry is running by querying it.
```bash
curl http://localhost:${REGISTRY_PORT}/v2/_catalog
```

You should get output similar to below.
```
{"repositories":[]}
```

## Deploy a Kubernetes Cluster
**Step 1.** Deploy a Kubernetes cluster called `demo` using `kind`.
```bash
cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --image kindest/node:v1.34.0 --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${REGISTRY_NAME}:${REGISTRY_INTERNAL_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:${REGISTRY_INTERNAL_PORT}"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."${REGISTRY_NAME}:${REGISTRY_INTERNAL_PORT}".tls]
    insecure_skip_verify = true
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
- role: worker
- role: worker
EOF
```

**Step 2.** Confirm the version of your Kubernetes cluster is `v1.34.0` using `kubectl`.
```bash
kubectl version
```

You should get output similar to below.
```
Client Version: v1.35.0
Kustomize Version: v5.7.1
Server Version: v1.34.0
```

## Connect the Kubernetes Cluster to the Container Registry
**Step 1.** Identify the configuration your container registry's network is using. 
```bash
docker network inspect kind | jq ".[0].IPAM"
```

You should get output similar to below. Pay special attention to the IPv4 `Subnet` field.
```json
{
  "Driver": "default",
  "Options": {},
  "Config": [
    {
      "Subnet": "fc00:f853:ccd:e793::/64"
    },
    {
      "Subnet": "172.18.0.0/16",
      "Gateway": "172.18.0.1"
    }
  ]
}
```

**Step 2.** Connect your container registry network (e.g., `kind`) to your Kubernetes cluster's network. Do not skip this step or your Kubernetes cluster will not be able to resolve the hostname of your container registry.
```bash
docker network connect kind ${REGISTRY_NAME}
```

**Step 3.** Inspect your container registry's network configuration for what is has with regards to your Kubernetes cluster.  
```bash
docker inspect ${REGISTRY_NAME} -f='{{json .NetworkSettings.Networks}}' | jq ".kind"
```

You should get output similar to below. Specifically, you should see your container registry how has an IP address (e.g., `172.18.0.5`) in same network as your Kubernetes cluster (e.g., `172.18.0.0/16`).
```json
{
  "IPAMConfig": {},
  "Links": null,
  "Aliases": [],
  "MacAddress": "6e:55:cb:b8:61:11",
  "DriverOpts": {},
  "GwPriority": 0,
  "NetworkID": "ad1ee06b8928b980a422a2bc75f2f255deef535b85a0fc3ca6ae6d781985abdb",
  "EndpointID": "6a83558f05d5134ce6c7f11e747588908656056a4a845139f671b71b14f31025",
  "Gateway": "172.18.0.1",
  "IPAddress": "172.18.0.5",
  "IPPrefixLen": 16,
  "IPv6Gateway": "fc00:f853:ccd:e793::1",
  "GlobalIPv6Address": "fc00:f853:ccd:e793::5",
  "GlobalIPv6PrefixLen": 64,
  "DNSNames": [
    "demo",
    "48178d3470ac"
  ]
}
```

## Create an SBOM and VEX Document
**Step 1.** Create an SBOM for a container image using `syft`.
```bash
syft vulnerables/web-dvwa -o cyclonedx-json=sbom.json
```

You should get output similar to below. 
```
 ✔ Loaded image                                                                                                                   vulnerables/web-dvwa:latest 
 ✔ Parsed image                                                                       sha256:ab0d83586b6e8799bb549ab91914402e47e3bcc7eea0c5cdf43755d56150cc6a 
 ✔ Cataloged contents                                                                        738614d5cf55eef7c055a83881c558b6fc9188c6da94956da63132c04afff180 
   ├── ✔ Packages                        [221 packages]  
   ├── ✔ Executables                     [1,132 executables]  
   ├── ✔ File metadata                   [9,458 locations]  
   └── ✔ File digests                    [9,458 files]
```

**Step 2.** Scan the SBOM for Common Vulnerabilities and Exposures (CVEs) using `grype`.
```bash
grype sbom:sbom.json -o cyclonedx-json=scan.json
```

You should get output similar to below. Note the number of vulnerability matches (2097 in total). 
```
 ✔ Scanned for vulnerabilities     [2097 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
```

**Step 3.** Review the CVEs reported by `grype`. 
```bash
cat scan.json | jq '.vulnerabilities'
```

**Step 4.** Pick a component and a CVE (e.g., `CVE-2019-11043`) Grype associated with it that you want to suppress. Then, run again Grype to get the Package URL its using for the component. 
```bash
grype sbom:sbom.json -o json | jq -r '.matches[] | select(.vulnerability.id=="CVE-2019-11043") | .artifact.purl'
```

You should get output similar to below.
```
 ✔ Scanned for vulnerabilities     [2097 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
pkg:deb/debian/libapache2-mod-php7.0@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0@7.0.30-0%2Bdeb9u1?arch=all&distro=debian-9
pkg:deb/debian/php7.0-cli@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-common@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-gd@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-json@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-mysql@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-opcache@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-pgsql@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-readline@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
pkg:deb/debian/php7.0-xml@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0
```

**Step 5.** Create a VEX document using your product PURL, component PURL, and CVE. For containers, the PURL format is `pkg:oci/<image-name>@sha256%<image-id>?tag=<tag>`. For example, the product URL for the latest version of the container image `web-dvwa` is `pkg:oci/web-dvwa@sha256%ab0d83586b6e?tag=latest`. To get the image ID of a container in your local container registry, run `docker image ls` (or whatever is the equivalent for the container runtime you have installed).
```bash
vexctl create \
  --product="pkg:oci/web-dvwa@sha256%ab0d83586b6e?tag=latest" \
  --vuln="CVE-2019-11043" \
  --subcomponents="pkg:deb/debian/libapache2-mod-php7.0@7.0.30-0%2Bdeb9u1?arch=amd64&distro=debian-9&upstream=php7.0" \
  --status="not_affected" \
  --justification="vulnerable_code_not_in_execute_path" \
  --file="vex.json" \
  --author="victor@deathlabs.io"
```

You should get output similar to below. 
```
> VEX document written to vex.json
```

**Step 6.** Using the VEX document as additional input, scan the SBOM again to verify the CVE gets suppressed. 
```bash
grype sbom:sbom.json --vex=vex.json -o cyclonedx-json=scan-2.json
```

You should get output similar to below. As you will see, the number of vulnerability matches went down from 2097 to 2096.
```
 ✔ Scanned for vulnerabilities     [2096 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
```

## Tag and Pug the Container Image to the Container Registry
**Step 1.** Tag the container image. 
```bash
docker tag vulnerables/web-dvwa:latest localhost:${REGISTRY_PORT}/web-dvwa:latest
```

**Step 2.** Push the container image to your container registry. 
```bash
docker push localhost:${REGISTRY_PORT}/web-dvwa:latest
```

You should get output similar to below.
```
The push refers to repository [localhost:5001/web-dvwa]
deeea3c4d56f: Pushed 
585e40f29c46: Pushed 
73e92d5f2a6c: Pushed 
9713610e6ec4: Pushed 
acf8abb873ce: Pushed 
97a1040801c3: Pushed 
80f9a8427b18: Pushed 
a75caa09eb1f: Pushed 
latest: digest: sha256:dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7 size: 1997
```

**Step 3.** Query your container registry to confirm your container image has been uploaded. 
```bash
curl http://localhost:${REGISTRY_PORT}/v2/_catalog
```

You should get output similar to below.
```json
{"repositories":["web-dvwa"]}
```

**Step 4.** Query your container registry to confirm which container image version was been uploaded. 
```bash
curl http://localhost:5001/v2/web-dvwa/tags/list
```

You should get output similar to below.
```json
{"name":"web-dvwa","tags":["latest"]}
```

## Create Attestations that Link the SBOM and VEX Documents to the Container Image
**Step 1.** Save the digest of the container image to an environment variable called `DIGEST`.
```bash
export DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' localhost:${REGISTRY_PORT}/web-dvwa:latest | cut -d":" -f2)
```

**Step 2.** Text goes here.
```bash
cosign generate-key-pair
```

**Step 3.** Create an attestation in the container registry, using `cosign`, that links the SBOM (e.g., `sbom.json`) to the container.image. 
```bash
cosign attest \
  --key cosign.key \
  --type spdxjson \
  --predicate sbom.json \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

**Step 4.** Create an attestation in the container registry, using `cosign`, that links the VEX document (e.g., `vex.json`) to the container.
```bash
cosign attest \
  --key cosign.key \
  --type openvex \
  --predicate vex.json \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

**Step 5.** Confirm the attestations exist for the container image in the container registry.
```bash
cosign tree localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

You should get output similar to below.
```
📦 Supply Chain Security Related artifacts for an image: localhost:5001/web-dvwa@sha256:dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7
└── 💾 Attestations for an image tag: localhost:5001/web-dvwa:sha256-dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7.att
   ├── 🍒 sha256:317158b7ac4bee58a60e378a1362e76d7bf3f2386ed75cc3a47a8e630e56b695
   └── 🍒 sha256:a51a162652a5e72e85e84dbb5539e973588bb5069f0dff0d9ff83c8857a80329
```

**Step 6.** Text goes here.
```bash
cosign verify-attestation \
  --key cosign.pub \
  --type spdxjson \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

**Step 7.** Text goes here.
```bash
cosign verify-attestation \
  --key cosign.pub \
  --type openvex \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

## Deploy a Container on the Kubernetes Cluster
**Step 1.** Deploy a workload on your Kubernetes cluster that uses your container image. 
```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
  labels:
    app: dvwa
spec:
  containers:
  - name: dvwa
    image: ${REGISTRY_NAME}:${REGISTRY_INTERNAL_PORT}/web-dvwa:latest
EOF
```

**Step 2.** Check on the health of the workload using the command below. 
```bash
kubectl describe pod demo-pod
```

You should get output similar to below.
```yaml
Namespace:        default
Priority:         0
Service Account:  default
Node:             demo-worker2/172.18.0.2
Start Time:       Sun, 08 Feb 2026 21:06:49 -0500
Labels:           app=dvwa
Annotations:      <none>
Status:           Running
IP:               10.244.1.3
IPs:
  IP:  10.244.1.3
Containers:
  dvwa:
    Container ID:   containerd://b25c3517ab33e026bb9cfbdfd0fc82863c55b1730f46cef3871de9e014cd6d7c
    Image:          demo:5000/web-dvwa:latest
    Image ID:       demo:5000/web-dvwa@sha256:dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sun, 08 Feb 2026 21:06:49 -0500
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-r7jc9 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-r7jc9:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  15s   default-scheduler  Successfully assigned default/demo-pod to demo-worker2
  Normal  Pulling    15s   kubelet            spec.containers{dvwa}: Pulling image "demo:5000/web-dvwa:latest"
  Normal  Pulled     15s   kubelet            spec.containers{dvwa}: Successfully pulled image "demo:5000/web-dvwa:latest" in 126ms (126ms including waiting). Image size: 178370991 bytes.
  Normal  Created    15s   kubelet            spec.containers{dvwa}: Created container: dvwa
  Normal  Started    15s   kubelet            spec.containers{dvwa}: Started container dvwa
```

**Step 3.** Add a service resource to your workload so you can access your container image from your host OS. 
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  type: NodePort
  selector:
    app: dvwa
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30000
EOF
```

**Step 4.** Open a browser to [http://localhost:30000](http://localhost:30000) and confirm you're able to interact with the workload.

## Create and Apply Kyverno Policy
**Step 1.** Install Kyverno on the Kubernetes cluster.
```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.17.0/install.yaml
```

**Step 2.** Wait for the Kyverno pods to start. 
```bash
kubectl -n kyverno get pods
```

You should eventually see output similar to below.
```
NAME                                            READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-5f9fb8dcb8-2cv4n   1/1     Running   0          3m59s
kyverno-background-controller-79b78db6b-gfmst   1/1     Running   0          3m59s
kyverno-cleanup-controller-6bcc48b5-c29rm       1/1     Running   0          3m59s
kyverno-reports-controller-5dbc78665-b7brp      1/1     Running   0          3m59s
```

**Step 3.** Apply a Kyverno policy to the Kubernetes cluster.
```bash
kubectl apply -f policy.yml
```

You should get output similar to below.
```
clusterpolicy.kyverno.io/block-affected-vex created
```

**Step 4.** Test the cluster policy.

## References
**Cosign**  
Cosign stores attestations as OCI artifacts associated with an image digest. Attestations are not part of the image layers.
https://docs.sigstore.dev/cosign/verifying/attestation/

**Docker Scout: Create an exception using the VEX**  
https://docs.docker.com/scout/how-tos/create-exceptions-vex/

**kind: Local Registry**  
https://kind.sigs.k8s.io/docs/user/local-registry/

**kind: Using WSL2**  
https://kind.sigs.k8s.io/docs/user/using-wsl2/#accessing-a-kubernetes-service-running-in-wsl2

**OCI Artifacts**  
Artifacts are stored as OCI manifests and reference a subject manifest via its digest. 
https://github.com/opencontainers/artifacts?tab=readme-ov-file

**OpenVEX Specification v0.2.0**  
https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md#status-justifications

**Package-URL (PURL) Specification: OCI Definition**  
https://github.com/package-url/purl-spec/blob/main/types/oci-definition.json

