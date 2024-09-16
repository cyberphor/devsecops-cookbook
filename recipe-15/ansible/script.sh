# control node
# step 1
sudo kubeadm init

# step 2
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# step 3
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml

# step 4
wget https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml

# step 5
kubectl create -f custom-resources.yaml

# step 6
kubectl get pods -n calico-system

# worker node
# step 4
kubeadm join 10.0.0.13:6443 \
    --token xxx \
    --discovery-token-ca-cert-hash sha256:xxx