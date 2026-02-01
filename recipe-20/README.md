## Recipe 20: Policy-as-Code

## Setup
**Step 1.** Install `kubectl`.
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Step 2.** Install `kind`.
```bash
go install sigs.k8s.io/kind@v0.31.0
```

**Step 3.** Create a Kubernetes cluster called `demo`.
```bash
kind create cluster --name demo --image kindest/node:v1.34.0 --config recipe-20/cluster-config.yml
```

**Step 4.** Print cluster information.
```bash
kubectl cluster-info --context kind-demo
```

You should get output similar to below.
```
Kubernetes control plane is running at https://127.0.0.1:38167
CoreDNS is running at https://127.0.0.1:38167/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

**Step 5.** Create a deployment.
```bash
kubectl create deployment nginx --image=nginx --port=80
```

**Step 6.** Create a service.
```bash
kubectl create service nodeport nginx --tcp=80:80 --node-port=30000
```

**Step 7.** Access the service. 
```bash
curl localhost:30000
```

## References
**kind: Using WSL2**  
https://kind.sigs.k8s.io/docs/user/using-wsl2/#accessing-a-kubernetes-service-running-in-wsl2