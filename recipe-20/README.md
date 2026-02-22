## Recipe 20: Policy-as-Code
* [Setup](#setup)
* [Initialize Your Environment Variables](#initialize-your-environment-variables)
* [Deploy a Container Registry](#deploy-a-container-registry)
* [Deploy a Kubernetes Cluster](#deploy-a-kubernetes-cluster)
* [Connect the Kubernetes Cluster to the Container Registry](#connect-the-kubernetes-cluster-to-the-container-registry)
* [Install Kyverno on the Kubernetes Cluster](#install-kyverno-on-the-kubernetes-cluster)
* [Create and Apply a Kyverno Policy](#create-and-apply-a-kyverno-policy)
* [Pull a Container Image](#pull-a-container-image)
* [Create an SBOM](#create-an-sbom)
* [Scan the SBOM](#scan-the-sbom)
* [Identify Package URLs](#identify-package-urls)
* [Create a VEX Document](#create-a-vex-document)
* [Rescan the SBOM Using the VEX Document](#rescan-the-sbom-using-the-vex-document)
* [Tag and Push the Container Image to the Container Registry](#tag-and-push-the-container-image-to-the-container-registry)
* [Create and Push Attestations that Link the SBOM and VEX Documents to the Container Image](#create-and-push-attestations-that-link-the-sbom-and-vex-documents-to-the-container-image)
* [Deploy a Container on the Kubernetes Cluster](#deploy-a-container-on-the-kubernetes-cluster)
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
**Step 1.** Initialize all the environment variables that will be used. The `REGISTRY_PORT` environment variable must be set to an port number that doesn't conflict the port Docker's local container registry is listening on (i.e., you cannot use `5000`). 
```bash
export REGISTRY_NAME="demo-registry"
export REGISTRY_PORT="5001"
export REGISTRY_INTERNAL_PORT="5000"
export CLUSTER_NAME="demo-cluster"
export COSIGN_PASSWORD="demo"
```

## Deploy a Container Registry
**Step 1.** Create a public and private key pair for the container registry you're about deploy.
```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:4096 \
  -out "${REGISTRY_NAME}.crt" \
  -keyout "${REGISTRY_NAME}.key" \
  -subj "/CN=${REGISTRY_NAME}" \
  -addext "subjectAltName=DNS:${REGISTRY_NAME},DNS:localhost"
```

**Step 2.** Deploy a container registry locally called using `docker` and the key pair you just created.
```bash
docker run -d \
  --name ${REGISTRY_NAME} \
  -p ${REGISTRY_PORT}:${REGISTRY_INTERNAL_PORT} \
  -v $(pwd)/${REGISTRY_NAME}.crt:/certs/domain.crt \
  -v $(pwd)/${REGISTRY_NAME}.key:/certs/domain.key \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:3
```

**Step 3.** Copy your container registry's public key to your local CA store. 
```bash
sudo cp ${REGISTRY_NAME}.crt /usr/local/share/ca-certificates/${REGISTRY_NAME}.crt
```

**Step 4.** Update your local CA store. 
```bash
sudo update-ca-certificates
```

**Step 5.** Verify the container registry is running by querying it from your local machine.
```bash
curl https://localhost:${REGISTRY_PORT}/v2/_catalog
```

You should get output similar to below.
```
{"repositories":[]}
```

## Deploy a Kubernetes Cluster
**Step 1.** Deploy a Kubernetes cluster called `demo` using `kind`.
```bash
kind create cluster --name ${CLUSTER_NAME} --image kindest/node:v1.34.0 --config cluster.yaml
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

**Step 3.** Add your container registry's public key to each of the nodes in your Kubernetes cluster. 
```bash
docker cp ${REGISTRY_NAME}.crt ${CLUSTER_NAME}-control-plane:/usr/local/share/ca-certificates/${REGISTRY_NAME}.crt
docker cp ${REGISTRY_NAME}.crt ${CLUSTER_NAME}-worker:/usr/local/share/ca-certificates/${REGISTRY_NAME}.crt
docker cp ${REGISTRY_NAME}.crt ${CLUSTER_NAME}-worker2:/usr/local/share/ca-certificates/${REGISTRY_NAME}.crt
```

**Step 4.** Update the CA store on each of the nodes in your Kubernetes cluster.
```bash
docker exec ${CLUSTER_NAME}-control-plane update-ca-certificates
docker exec ${CLUSTER_NAME}-worker update-ca-certificates
docker exec ${CLUSTER_NAME}-worker2 update-ca-certificates
```

## Connect the Kubernetes Cluster to the Container Registry
**Step 1.** Identify the configuration your Kubernetes cluster's network is using. 
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

**Step 2.** Connect your Kubernetes cluster's network (e.g., `kind`) to your container registry's network. Do not skip this step or your Kubernetes cluster will not be able to resolve the hostname of your container registry.
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
  "DriverOpts": {},
  "GwPriority": 0,
  "NetworkID": "531abfad301d29b4f3954a8e00759b7019ccd268d829d03efdbe8c91cdd77163",
  "EndpointID": "91eba567e21493be9fb151c962bd50678e77eda2d7bdd4bf3b9026c67844353b",
  "Gateway": "172.18.0.1",
  "IPAddress": "172.18.0.5",
  "MacAddress": "3a:32:cc:74:1c:02",
  "IPPrefixLen": 16,
  "IPv6Gateway": "fc00:f853:ccd:e793::1",
  "GlobalIPv6Address": "fc00:f853:ccd:e793::5",
  "GlobalIPv6PrefixLen": 64,
  "DNSNames": [
    "demo-registry",
    "f26a00759bb5"
  ]
}
```

## Install Kyverno on the Kubernetes Cluster
**Step 1.** Add the URL for the Kyverno Helm chart repo to your local Helm configuration.
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
```

**Step 2.** Either use the provided `kyverno-values.yaml` file or recreate it. 
```bash
vim kyverno-values.yaml
```

Make sure the content below is in the file. This will ensure the `ca-certificates.crt` file of the node each Kyverno pod is running on is mounted as a file volume. 
```yaml
---
global:
  caCertificates:
    volume:
      hostPath:
        path: /etc/ssl/certs/ca-certificates.crt
        type: File
```

**Step 3.** Install Kyverno on the Kubernetes cluster.
```bash
helm install kyverno kyverno/kyverno \
  --create-namespace \
  -n kyverno \
  -f kyverno-values.yaml
```

**Step 4.** Wait for the Kyverno pods to start. 
```bash
kubectl -n kyverno get pods
```

You should eventually see output similar to below.
```
NAME                                            READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-5f9fb8dcb8-zg57j   1/1     Running   0          41s
kyverno-background-controller-79b78db6b-w7dq2   1/1     Running   0          41s
kyverno-cleanup-controller-6bcc48b5-k4c2k       1/1     Running   0          41s
kyverno-reports-controller-5dbc78665-t9ksf      1/1     Running   0          41s
```

## Create and Apply a Kyverno Policy
**Step 1.** Apply a Kyverno policy to the Kubernetes cluster.
```bash
kubectl apply -f kyverno-policy.yaml
```

The output should be similar to below.
```
clusterpolicy.kyverno.io/block-affected-vex created
```

## Pull a Container Image
**Step 1.** Pull a container image.
```bash
docker pull vulnerables/web-dvwa:latest
```

The output should be similar to below. 
```
latest: Pulling from vulnerables/web-dvwa
3e17c6eae66c: Pull complete 
0c57df616dbf: Pull complete 
eb05d18be401: Pull complete 
e9968e5981d2: Pull complete 
2cd72dba8257: Pull complete 
6cff5f35147f: Pull complete 
098cffd43466: Pull complete 
b3d64a33242d: Pull complete 
Digest: sha256:dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7
Status: Downloaded newer image for vulnerables/web-dvwa:latest
docker.io/vulnerables/web-dvwa:latest
```

## Create an SBOM
**Step 1.** Create an SBOM for a container image in your container registry using `syft`.
```bash
syft vulnerables/web-dvwa:latest -o cyclonedx-json=sbom.json
```

The output should be similar to below. 
```
 ✔ Loaded image                                                                   vulnerables/web-dvwa:latest 
 ✔ Parsed image                       sha256:ab0d83586b6e8799bb549ab91914402e47e3bcc7eea0c5cdf43755d56150cc6a 
 ✔ Cataloged contents                        738614d5cf55eef7c055a83881c558b6fc9188c6da94956da63132c04afff180 
   ├── ✔ Packages                        [221 packages]  
   ├── ✔ Executables                     [1,132 executables]  
   ├── ✔ File metadata                   [9,458 locations]  
   └── ✔ File digests                    [9,458 files]
```

## Scan the Container Image
**Step 1.** Scan the container image for Common Vulnerabilities and Exposures (CVEs) using `grype`.
```bash
grype vulnerables/web-dvwa:latest -o json=scan.json
```

The output should be similar to below. Note the number of vulnerability matches (2097 in total). 
```
 ✔ Scanned for vulnerabilities     [2097 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
```

## Identify Package URLs
Package URLs (PURLs) are strings that follow a standardized, URL-based syntax that uniquely identifies software packages, independent of their ecosystem or distribution channel. According to [the Package URL (PURL) specification](https://github.com/package-url/purl-spec/blob/main/types-doc/oci-definition.md), the PURL format for OCI images is `pkg:oci/<image_name>@sha256%<image_digest>`. The `image_digest` can be found by running `docker inspect`. 

**Step 1.** Save the digest of the container image to an environment variable. 
```bash
export IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' vulnerables/web-dvwa:latest | cut -d":" -f2)
```

**Step 2.** Print the environment variable to confirm the value returned by Docker.
```bash
echo $IMAGE_DIGEST
```

The output should be similar to below.
```bash
dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7
```

**Step 3.** Review the CVEs reported by `grype`. 
```bash
cat scan.json | jq '.vulnerabilities'
```

**Step 4.** Pick a component and a CVE (e.g., `CVE-2019-11043`) Grype associated with it that you want to suppress. Then, run again Grype to get the Package URL (PURL) its using for the component. 
```bash
grype vulnerables/web-dvwa:latest -o json | jq -r '.matches[] | select(.vulnerability.id=="CVE-2019-11043") | .artifact.purl'
```

The output should be similar to below.
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

## Create a VEX Document
Vulnerability Exploitability Exchange (VEX) documents allow you to communicate the status of vulnerabilities in a machine-readable format. `vexctl` is a tool for creating VEX documents. 

**Step 1.** Create a VEX document using the CVE in question, the PURL of the container image, and the PURL of the component in question.
```bash
vexctl create \
  --product="pkg:oci/web-dvwa@sha256:dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7" \
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

## Rescan the Container Image Using the VEX Document
**Step 1.** Using `grype` and the VEX document as additional input, scan the container image again to suppress the CVE. 
```bash
grype vulnerables/web-dvwa:latest --vex=vex.json -o json=scan.json
```

You should get output similar to below. As you will see, the number of vulnerability matches went down from 2097 to 2096.
```
 ✔ Scanned for vulnerabilities     [2096 vulnerability matches]  
   ├── by severity: 327 critical, 760 high, 700 medium, 99 low, 210 negligible (1 unknown)
```

## Tag and Push the Container Image to the Container Registry
**Step 1.** Tag the container image for your container registry. 
```bash
docker tag vulnerables/web-dvwa:latest localhost:${REGISTRY_PORT}/web-dvwa:latest
```

**Step 2.** Push the container image to your container registry. 
```bash
docker push localhost:${REGISTRY_PORT}/web-dvwa:latest
```

**Step 3.** Query your container registry to verify your container image has been uploaded. 
```bash
curl https://localhost:${REGISTRY_PORT}/v2/_catalog
```

You should get output similar to below.
```json
{"repositories":["web-dvwa"]}
```

**Step 4.** Query your container registry to verify the container image tag uploaded. 
```bash
curl https://localhost:${REGISTRY_PORT}/v2/web-dvwa/tags/list
```

You should get output similar to below.
```json
{"name":"web-dvwa","tags":["latest"]}
```

## Create and Push Attestations that Link the SBOM and VEX Documents to the Container Image
**Step 1.** Save the digest of the container image to an environment variable called `DIGEST`.
```bash
export DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' localhost:${REGISTRY_PORT}/web-dvwa:v1.0.0 | cut -d":" -f3)
```

**Step 2.** Create another public and private key pair albeit for `cosign` to use. 
```bash
cosign generate-key-pair
```

**Step 3.** Create an attestation in the container registry, using `cosign`, that links the SBOM (e.g., `sbom.json`) to the container.image. 
```bash
cosign attest \
  --key cosign.key \
  --type cyclonedx \
  --predicate sbom.json \
  -y \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

You should get output similar to below. 
```
Using payload from: sbom.json

    The sigstore service, hosted by sigstore a Series of LF Projects, LLC, is provided pursuant to the Hosted Project Tools Terms of Use, available at https://lfprojects.org/policies/hosted-project-tools-terms-of-use/.
    Note that if your submission includes personal data associated with this signed artifact, it will be part of an immutable record.
    This may include the email address associated with the account with which you authenticate your contractual Agreement.
    This information will be used for signing this artifact and will be stored in public transparency logs and cannot be removed later, and is subject to the Immutable Record notice at https://lfprojects.org/policies/hosted-project-tools-immutable-records/.

By typing 'y', you attest that (1) you are not submitting the personal data of any other person; and (2) you understand and agree to the statement and the Agreement terms at the URLs listed above.
tlog entry created with index: 953290970
```

**Step 4.** Create an attestation in the container registry, using `cosign`, that links the VEX document (e.g., `vex.json`) to the container.
```bash
cosign attest \
  --key cosign.key \
  --type openvex \
  --predicate vex.json \
  -y \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

You should get output similar to below. 
```
Using payload from: vex.json

    The sigstore service, hosted by sigstore a Series of LF Projects, LLC, is provided pursuant to the Hosted Project Tools Terms of Use, available at https://lfprojects.org/policies/hosted-project-tools-terms-of-use/.
    Note that if your submission includes personal data associated with this signed artifact, it will be part of an immutable record.
    This may include the email address associated with the account with which you authenticate your contractual Agreement.
    This information will be used for signing this artifact and will be stored in public transparency logs and cannot be removed later, and is subject to the Immutable Record notice at https://lfprojects.org/policies/hosted-project-tools-immutable-records/.

By typing 'y', you attest that (1) you are not submitting the personal data of any other person; and (2) you understand and agree to the statement and the Agreement terms at the URLs listed above.
tlog entry created with index: 953290159
```

**Step 5.** Confirm the attestations exist for the container image in the container registry.
```bash
cosign tree localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

You should get output similar to below.
```
📦 Supply Chain Security Related artifacts for an image: localhost:5001/web-dvwa@sha256:dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7
└── 💾 Attestations for an image tag: localhost:5001/web-dvwa:sha256-dae203fe11646a86937bf04db0079adef295f426da68a92b40e3b181f337daa7.att
   ├── 🍒 sha256:74926c7f6818c14e5267bc583e2eddd0b6f3bf3e372596fd61ac7db267d6612f
   └── 🍒 sha256:b044887ff03a592f128cdbe5801c2bae705e1871421dc90dcc334d2f2f3950fe
```

**Step 6.** Verify the SBOM attestation.
```bash
cosign verify-attestation \
  --key cosign.pub \
  --type cyclonedx \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

**Step 7.**  Verify the VEX attestation.
```bash
cosign verify-attestation \
  --key cosign.pub \
  --type openvex \
  localhost:${REGISTRY_PORT}/web-dvwa@sha256:${DIGEST}
```

## Deploy a Container on the Kubernetes Cluster
**Step 1.** Deploy a workload on your Kubernetes cluster that uses your container image. 
```bash
kubectl apply -f app.yaml
```

**Step 2.** Check on the health of the workload using the command below. 
```bash
kubectl describe pod demo-pod
```

**Step 3.** Open a browser to [http://localhost:30000](http://localhost:30000) and confirm you're able to interact with the workload.

## References
**Anchore: Open Source | Guides | Vulnerability Scanning | Filter scan results**  
https://oss.anchore.com/docs/guides/vulnerability/filter-results/#product-identification

**Cosign**  
Cosign stores attestations as OCI artifacts associated with an image digest. Attestations are not part of the image layers.
https://docs.sigstore.dev/cosign/verifying/attestation/

**Docker Scout: Create an exception using the VEX**  
https://docs.docker.com/scout/how-tos/create-exceptions-vex/

**kind: Local Registry**  
https://kind.sigs.k8s.io/docs/user/local-registry/

**kind: Using WSL2**  
https://kind.sigs.k8s.io/docs/user/using-wsl2/#accessing-a-kubernetes-service-running-in-wsl2

**Kyverno: Host Mount**    
https://main.kyverno.io/docs/policy-types/cluster-policy/verify-images/sigstore/#host-mount

**OCI Artifacts**  
Artifacts are stored as OCI manifests and reference a subject manifest via its digest.  
https://github.com/opencontainers/artifacts?tab=readme-ov-file

**OpenVEX Specification v0.2.0**  
https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md#status-justifications

**Package-URL (PURL) Specification: OCI Definition**  
https://github.com/package-url/purl-spec/blob/main/types/oci-definition.json
