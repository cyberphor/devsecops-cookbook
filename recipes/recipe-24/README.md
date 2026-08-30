# Deploy an app onto a Kubernetes cluster using Zarf and UDS

Before getting started, [make sure you have a Kubernetes cluster running UDS Core](../recipe-23/README.md#recipe). The following steps will produce a number of files and folders. By the end of this process, your current working directory will look like below. 
```
├── Makefile
├── charts
│   └── frontend
│       ├── Chart.yaml
│       ├── templates
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       └── values.yaml
├── uds-package.yaml
└── zarf.yaml
```

## Recipe
**Step 1.** Create a Makefile and add the content below to it. NOTE: this specific Makefile has the Zarf package name and version `sonic` and `v0.1.0` hardcoded.  
```makefile
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

```

**Step 2.** Create a folder called `charts`.
```bash
mkdir charts
```

**Step 3.** In the `charts` folder, create a folder called `frontend`. 
```bash
mkdir charts/frontend
```

**Step 4.** In the `charts/frontend` folder, create a file called `Chart.yaml` and add the content below to it. 
```yaml
# charts/frontend/Chart.yaml

---
# Chart metadata.
apiVersion: v2
type: application
version: v0.1.0

# Component metadata.
name: frontend
appVersion: v0.1.0

```

**Step 5.** In the `charts/frontend` folder, create another file but call it `values.yaml` and add the content below to it. 
```yaml
# charts/frontend/values.yaml

---
namespace: sonic
replicaCount: 1
image: 
  pullPolicy: Always
  repository: dazdaz/sonic
  tag: latest
service: 
  type: ClusterIP
  name: frontend
  port: 8080

```

**Step 6.** In the `charts/frontend` folder, create a folder called `templates`. 
```bash
mkdir charts/frontend/templates
```

**Step 7.** In the `charts/frontend/templates` folder, create a file called `deployment.yaml` and add the content below to it.   
```yaml
# charts/frontend/templates/deployment.yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: {{ .Values.namespace }}
  name: {{ .Values.service.name }}
  labels:
    app.kubernetes.io/component: {{ .Values.service.name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/component: {{ .Values.service.name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/component: {{ .Values.service.name }}
    spec:
      containers:
        - name: {{ .Values.service.name }}
          image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}

```

**Step 8.** In the `charts/frontend/templates` folder, create another file but call it `service.yaml` and add the content below to it.   
```yaml
# charts/frontend/templates/service.yaml

---
apiVersion: v1
kind: Service
metadata:
  namespace: {{ .Values.namespace }}
  name: {{ .Values.service.name }}
  labels:
    app.kubernetes.io/component: {{ .Values.service.name }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app.kubernetes.io/component: {{ .Values.service.name }}
  ports:
    - port: {{ .Values.service.port }}

```

**Step 9.** In the root of your project directory, create a file called `uds-package.yaml` and add the content below to it. 
```yaml
# uds-package.yaml

---
apiVersion: uds.dev/v1alpha1
kind: Package
metadata:
  namespace: sonic
  name: sonic
spec:
  network:
    expose:    
      - service: frontend
        selector:
          app.kubernetes.io/component: frontend
        host: sonic

```

**Step 10.** In the root of your project directory, create another file but call it `zarf.yaml` and add the content below to it. 
```yaml
# zarf.yaml

---
kind: ZarfPackageConfig
metadata:
  name: sonic
  version: v0.1.0
  annotations:
    dev.uds.title: Sonic
components:
  - name: sonic
    required: true
    manifests:
      - name: sonic
        namespace: sonic
        files:
          - uds-package.yaml
    charts:
      - name: sonic
        version: v0.1.0
        namespace: sonic
        localPath: charts/frontend
        valuesFiles:
          - charts/frontend/values.yaml
    images:
      - docker.io/dazdaz/sonic:latest

```

**Step 11.** If it's not already in your `/etc/hosts` file, add a DNS entry for the app you are deploying. 
```bash
echo "127.0.0.1 sonic.uds.dev" | sudo tee -a /etc/hosts
```

If you completed this recipe using WSL, make sure to also add a DNS entry to your Windows host. NOTE: this will require opening a Terminal window as an administrator.  
```powershell
powershell_ise.exe C:\Windows\System32\drivers\etc\hosts
```

```
127.0.0.1 sonic.uds.dev
```

**Step 12.** Create and deploy your app as a Zarf package (run this command in the root of your project). 
```bash
make
```

**Step 13.** Once your app is deployed, open it (e.g., [`https://sonic.uds.dev`](https://sonic.uds.dev)) in a browser.

## Cleaning Up
When you're done, remove the Zarf package using the command below (again, from the root of your project directory). 
```bash
make remove
```
