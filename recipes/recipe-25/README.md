# Using Pepr and Attestations to Enforce Software Supply Chain Security

## Setup
Before getting started, make sure you:
* [have a Kubernetes cluster running UDS Core](../recipe-23/README.md#recipe)
* [have the Node Version Manager installed](../setup/README.md#install-the-node-version-manager)
* [have Node.js, the Node Package Manager (NPM), and Node Package Execute (NPX) installed](../setup/README.md#install-nodejs)

## Recipe
**Step 1.** Use NPX and the `pepr` tool to create a Pepr module. In layman's terms, a Pepr module is a self-contained TypeScript project. In the context of Pepr, a Pepr module is a collection of "capabilities." 
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
 … vuln-scan
✔ (Recommended) Enter a description for the new Pepr module.
 … Block deployments without vuln scan attestations
✔ How do you want Pepr to handle errors encountered during K8s operations? › Reject the operation
✔ Enter a unique identifier for the new Pepr module.
 … 1
To be generated:

    vuln-scan
    ├── eslint.config.mjs
    ├── .gitignore
    ├── .prettierrc
    ├── capabilties
    │   ├── hello-pepr.samples.yaml     
    │   └── hello-pepr.ts     
    ├── package.json
    │   {
    │     name: 'vuln-scan',
    │     version: '0.0.1',
    │     description: 'Block deployments without vuln scan attestations',
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
cd vuln-scan
```

**Step 3.** Create a file called `vuln-scan.ts` in the `capabilities` folder and add the content below to it.
```ts
import {
  Capability,
  a,
} from "pepr";

export const PodDeployment = new Capability({
  name: "pod-deployment",
  description: "Block pod deployments without a vuln scan attestations",
  namespaces: [],
});

const { When } = PodDeployment;

When(a.Namespace)
  .IsCreated()
  .Mutate(ns => ns.RemoveLabel("remove-me"));
```

**Step 4.** Replace the content of the `pepr.ts` file located in the root of your Pepr module with the code below.
```ts
import { PeprModule } from "pepr";
import cfg from "./package.json";
import { PodDeployment } from "./capabilities/vuln-scan";

new PeprModule(cfg, [
  PodDeployment,
]);
``` 

**Step 5.** Run the command below to create a k3s-based Kubernetes cluster.
```bash
npx run k3d-setup
```

**Step 6.** Run the command below to deploy your Pepr module onto your k3s-based Kubernetes cluster. If you make any changes to your Pepr module, this command will detect it and automatically deploy your changes.
```bash
npx pepr dev --host localhost
```

**Step 7.** Create a file called `app.yaml` in the root of your Pepr module and add the content below to it.
```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
  labels:
    app: dvwa
    remove-me: please
spec:
  containers:
  - name: dvwa
    image: vulnerables/web-dvwa:latest

---
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
```

**Step 8.** Apply the YAML file you created. 
```bash
kubectl apply -f app.yaml
```

## Cleaning Up
When you're done, remove the Zarf package using the command below (again, from the root of your project directory). 
```bash
make remove
```
