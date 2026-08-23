# Deploy an app on a Kubernetes cluster using Zarf and UDS

**Step 1.** [Deploy UDS Core on a Kubernetes Cluster](../recipe-24/README.md). 


**Step 2.** Create a working directory. 
```bash
mkdir sonic 
```

**Step 3.** Change directories to the folder you just created. 
```bash
cd sonic
```

**Step 4.** Create a file called `zarf.yaml` and add the content below to it. 
```yaml
---
kind: ZarfPackageConfig
metadata:
  name: sonic
  version: 0.1.0

components:
  - name: sonic
    required: true
    charts:
      - name: sonic
        version: 0.1.0
        namespace: sonic
        localPath: charts
        valuesFiles:
          - charts/values.yaml
    manifests:
      - name: sonic-uds-config
        namespace: sonic
        files:
          - uds-package-sonic.yaml
    images:
      - docker.io/dazdaz/sonic:latest
```

**Step 5.** Create a file called `uds-package-sonic.yaml` and add the content below to it. 
```yaml
---
apiVersion: uds.dev/v1alpha1
kind: Package
metadata:
  name: sonic
  namespace: sonic
spec:
  network:
    expose:
      - service: sonic
        selector:
          app.kubernetes.io/name: sonic
        gateway: tenant
        host: sonic
        port: 8888
  sso:
    - name: sonic SSO
      clientId: uds-core-sonic
      redirectUris:
        - "https://sonic.uds.dev/login"
      enableAuthserviceSelector:
        app.kubernetes.io/name: sonic
      groups:
        anyOf:
          - "/UDS Core/Admin"
  monitor:
    - selector:
        app.kubernetes.io/name: sonic
      targetPort: 9898
      portName: http
      description: "sonic metrics"
      kind: PodMonitor
```

**Step 6.** Create the Zarf package. 
```bash
uds zarf package create --confirm
```

**Step 7.** If it's not already in your hosts file, add an entry for the app in question. 
```bash
echo "127.0.0.1 sonic.uds.dev" | sudo tee -a /etc/hosts
```

**Step 8.** Deploy the Zarf package. 
```bash
uds zarf package deploy zarf-package-sonic-amd64-0.1.0.tar.zst --confirm
```
