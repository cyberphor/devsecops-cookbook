# Using Pepr and Attestations to Enforce Software Supply Chain Security

## Setup
Before getting started, make sure you:
* [have a Kubernetes cluster running UDS Core](../recipe-23/README.md#recipe)  
* [have the Node Version Manager installed](../setup/README.md#install-the-node-version-manager)  
* [have Node.js, the Node Package Manager (NPM), and Node Package Execute (NPX) installed](../setup/README.md#install-nodejs)

## Recipe
**Step 1.** Use NPX and the `pepr` tool to create a Pepr module. In layman's terms, a Pepr module is a self-contained TypeScript project. In the context of Pepr, a Pepr module is a collection of "capabilities." NOTE: the `pepr` tool will also initialize your TypeScript project as a Git repository.
```bash
npx pepr init
```

If you haven't installed the `pepr` tool before, NPX will prompt you for permission before installing and then running it.
```
Need to install the following packages:
pepr@2.0.0
Ok to proceed? (y)
```

When prompted, press enter values similar to below. 
```
✔ Enter a name for the new Pepr module. This will create a new directory based on the name.
 … attestations
✔ (Recommended) Enter a description for the new Pepr module.
 … Block pod creation requests that don't have container attestations.
✔ How do you want Pepr to handle errors encountered during K8s operations? › Reject the operation
✔ Enter a unique identifier for the new Pepr module.
 … 1
To be generated:

    attestations
    ├── eslint.config.mjs
    ├── .gitignore
    ├── .prettierrc
    ├── capabilties
    │   ├── hello-pepr.samples.yaml     
    │   └── hello-pepr.ts     
    ├── package.json
    │   {
    │     name: 'attestations',
    │     version: '0.0.1',
    │     description: 'Block pod creation requests that don't have container attestations.',
    │     keywords: [ 'pepr', 'k8s', 'policy-engine', 'pepr-module', 'security' ],
    │     engines: { node: '>=22.19.0' },
    │     pepr: {
    │       uuid: '1',
    │       onError: 'reject',
    │       webhookTimeout: 10,
    │       customLabels: { namespace: { 'pepr.dev': '' } },
    │       alwaysIgnore: { namespaces: [] },
    │       admission: { alwaysIgnore: { namespaces: [] } },
    │       watch: { alwaysIgnore: { namespaces: [] } },
    │       includedFiles: [],
    │       env: {}
    │     },
    │     scripts: {
    │       'k3d-setup': "k3d cluster delete pepr-dev && k3d cluster create pepr-dev --k3s-arg '--debug@server:0' --wait && kubectl rollout status deployment -n kube-system"
    │     },
    │     dependencies: { pepr: '2.0.0', undici: '^7.0.1' },
    │     devDependencies: {
    │       '@eslint/eslintrc': '^3.3.6',
    │       '@eslint/js': '^10.0.1',
    │       '@typescript-eslint/eslint-plugin': '8.66.0',
    │       '@typescript-eslint/parser': '8.66.0',
    │       '@types/node': '^24.13.3',
    │       eslint: '^10.8.0',
    │       globals: '17.9.0',
    │       typescript: '^5.8.3'
    │     },
    │     overrides: { 'brace-expansion': '1.1.11' }
    │   }
    ├── pepr.ts
    ├── README.md
    └── tsconfig.json
  
? Create the new Pepr module? › (y/N)
```

**Step 2.** Change directories to the Pepr module you just created. The main entrypoint to the Pepr module is the `pepr.ts` file.
```bash
cd attestations
```

**Step 3.** Replace the content of the `pepr.ts` file located in the root of your Pepr module with the code below.
```ts
import { PeprModule } from "pepr";
import cfg from "./package.json";
import { Attestations } from "./capabilities/attestations";

new PeprModule(cfg, [
  Attestations,
]);
``` 

**Step 4.** Create a file called `attestations.ts` in the `capabilities` folder and add the content below to it.
```ts
import {
  Capability,
  a,
} from "pepr";

export const Attestations = new Capability({
  name: "attestations",
  description: "Block pod creation requests that don't have container attestations.",
  namespaces: [],
});

const { When } = Attestations;

When(a.Namespace)
  .IsCreated()
  .Mutate(ns => ns.RemoveLabel("remove-me"));
```

**Step 5.** Run the command below to deploy your Pepr module onto your Kubernetes cluster.
```bash
npx pepr deploy
```

**Step 6.** Change directories to your previous working directory.
```bash
cd ..
```

**Step 7.** Create a file called `sonic-k8s-manifest.yaml` and add the content below to it.
```yaml
# sonic-k8s-manifest.yaml

---
apiVersion: v1
kind: Namespace
metadata:
  name: sonic

---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: sonic
  name: sonic
  labels:
    app.kubernetes.io/component: frontend
    remove-me: please
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: frontend
  template:
    metadata:
      labels:
        app.kubernetes.io/component: frontend
    spec:
      containers:
        - name: frontend
          image: dazdaz/sonic:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 8080

---
apiVersion: v1
kind: Service
metadata:
  namespace: sonic
  name: frontend
  labels:
    app.kubernetes.io/component: frontend
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/component: frontend
  ports:
    - port: 8080

```

**Step 8.** Create a file called `sonic-uds-package.yaml` and add the content below to it.
```yaml
# sonic-uds-package.yaml

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
        port: 8080

```

**Step 9.** Create a file called `zarf.yaml` and add the content below to it.
```yaml
# zarf.yaml

---
kind: ZarfPackageConfig
metadata:
  name: sonic
  version: 0.1.0
  annotations:
    dev.uds.title: Sonic
components:
  - name: sonic-container-image
    required: true
    images:
      - docker.io/dazdaz/sonic:latest
  - name: sonic-k8s-manifest
    required: true
    manifests:
      - name: sonic-k8s-manifest
        namespace: sonic
        files:
          - sonic-k8s-manifest.yaml
  - name: sonic-uds-manifest
    required: true
    manifests:
      - name: sonic-uds-manifest
        namespace: sonic
        files:
          - sonic-uds-package.yaml

```

**Step 10.** Create a Zarf package using the files you just created. 
```bash
uds zarf package create --confirm
```

**Step 11.** Deploy the Zarf package you just created.
```bash
uds zarf package deploy zarf-package-sonic-amd64-0.1.0.tar.zst --confirm
```

## Cleaning Up
When you're done, remove your Zarf package from your Kubernetes cluster and then delete the `.zst` file in your current working directory.
