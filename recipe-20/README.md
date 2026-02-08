## Recipe 20: Policy-as-Code
* [Setup](#setup)
* [Provision a Container Registry](#provision-a-container-registry)
* [Provision a Kubernetes Cluster](#provision-a-kubernetes-cluster)
* [Connect the Kubernetes Cluster to the Container Registry](#connect-the-kubernetes-cluster-to-the-container-registry)
* [Create an SBOM and VEX Document](#create-an-sbom-and-vex-document)
* [Link the SBOM and VEX Document to the Container Image](#link-the-sbom-and-vex-document-to-the-container-image)
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

**Step 3.** Install `vexctl`.
```bash
go install github.com/openvex/vexctl@latest
```

**Step 4.** Text goes here.
```bash
go install github.com/sigstore/cosign/v2/cmd/cosign@latest
```

**Step 5.** Install `kubectl`.
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Step 6.** Install `kind`.
```bash
go install sigs.k8s.io/kind@v0.31.0
```

**Step 7.** Install the Kyverno CLI.
```bash
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.12.0/kyverno-cli_v1.12.0_linux_x86_64.tar.gz
tar -xvf kyverno-cli_v1.12.0_linux_x86_64.tar.gz
sudo mv kyverno /usr/local/bin/
rm kyverno-cli_v1.12.0_linux_x86_64.tar.gz
```

## Provision a Container Registry
**Step 1.** Start a container registry.
```bash
docker run -d -p 5000:5000 --restart=always --name demo registry:2
```

**Step 2.** Verify it works.
```bash
curl http://localhost:5000/v2/_catalog
```

You should get output similar to below.
```
{"repositories":[]}
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

## Connect the Kubernetes Cluster to the Container Registry
**Step 1.** Text goes here.
```bash
REGISTRY_NAME="demo"
REGISTRY_PORT="5001"
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${REGISTRY_PORT}"
CLUSTER_NAME="demo"
```

**Step 2.** Copy the container registry configuration to each of the Kubernetes cluster nodes.
```bash
for NODE in $(kind get nodes --name $CLUSTER_NAME); do
  docker exec "${NODE}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${NODE}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${REGISTRY_NAME}:5000"]
EOF
done
```

**Step 3.** Connect the network the container registry is using to the Kubernetes cluster's network. 
```bash
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
  docker network connect "kind" "${REGISTRY_NAME}"
fi
```

**Step 4.** Text goes here.
```bash
docker inspect -f='{{json .NetworkSettings.Networks.kind}}' demo
```

You should get output similar to below.
```json
{"IPAMConfig":{},"Links":null,"Aliases":[],"MacAddress":"1a:e8:8c:69:af:f7","DriverOpts":{},"GwPriority":0,"NetworkID":"5b40da3894beeda16d4d7a753b5bb8d7b737ac3850a25b2c905d61bd208d9acd","EndpointID":"d667d12564be7cc07fff62e7112f78504bedac39bc3369b94258131d27ea6a37","Gateway":"172.18.0.1","IPAddress":"172.18.0.5","IPPrefixLen":16,"IPv6Gateway":"fc00:f853:ccd:e793::1","GlobalIPv6Address":"fc00:f853:ccd:e793::5","GlobalIPv6PrefixLen":64,"DNSNames":["demo","6d551390f684"]}
```

**Step 5.** 
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
```

You should get output similar to below.
```bash
configmap/local-registry-hosting created
```

## Create an SBOM and VEX Document
**Step 1.** Create an SBOM.
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

**Step 2.** Scan an SBOM.
```bash
grype sbom:sbom.json -o cyclonedx-json=scan.json
```

You should get output similar to below. Note the number of vulnerability matches (2097 in total). 
```
 ✔ Scanned for vulnerabilities     [2097 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
```

**Step 3.** Review the CVEs identified. 
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

**Step 6.** Using the VEX document as additional input, scan the SBOM again to verify the CVE is suppressed. 
```bash
grype sbom:sbom.json --vex=vex.json -o cyclonedx-json=scan-2.json
```

You should get output similar to below. As you will see, the number of vulnerability matches went down from 2097 to 2096.
```
 ✔ Scanned for vulnerabilities     [2096 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
```

## Create an OCI Artifact that Links the SBOM and VEX Documents to the Container Image
**Step 1.** Text goes here. 
```bash
docker tag vulnerables/web-dvwa:latest localhost:5000/web-dvwa:latest
```

**Step 2.** Text goes here.
```bash
docker push localhost:5000/web-dvwa:latest
```

You should get output similar to below.
```
The push refers to repository [localhost:5000/web-dvwa]
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

**Step 3.** Text goes here.
```bash
docker inspect --format='{{index .RepoDigests 0}}' localhost:5000/web-dvwa:latest
```

**Step 4.** Text goes here.
```bash
cosign attach sbom --sbom sbom.json localhost:5000/web-dvwa@sha256:abc...xyz
```

**Step 5.** Text goes here.
```bash
cosign attach attestation --type openvex --predicate vex.json localhost:5000/web-dvwa@sha256:abc...xyz
```

**Step 6.** Text goes here.
```bash
cosign tree localhost:5000/web-dvwa@sha256:<digest>
```

## Deploy the Container Image
**Step 1.** Text goes here.
```bash
kubectl apply -f pod.yaml
```

## Create and Apply Kyverno Policy
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

