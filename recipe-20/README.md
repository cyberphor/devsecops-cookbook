## Recipe 20: Policy-as-Code
* [Setup](#setup)
* [Provision a Kubernetes Cluster](#provision-a-kubernetes-cluster)
* [Create an SBOM and VEX Document](#create-an-sbom-and-vex-document)
* [Attach the SBOM and VEX Document to the Container Image](#attach-the-sbom-and-vex-document-to-the-container-image)
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

## Attach the SBOM and VEX Document to the Container Image
**Step 1.** Text goes here.

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
**Docker Scout: Create an exception using the VEX**  
https://docs.docker.com/scout/how-tos/create-exceptions-vex/

**kind: Using WSL2**  
https://kind.sigs.k8s.io/docs/user/using-wsl2/#accessing-a-kubernetes-service-running-in-wsl2

**OpenVEX Specification v0.2.0**  
https://github.com/openvex/spec/blob/main/OPENVEX-SPEC.md#status-justifications

**Package-URL (PURL) Specification: OCI Definition**  
https://github.com/package-url/purl-spec/blob/main/types/oci-definition.json
