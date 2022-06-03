# controlplane-in-docker
all kubernetes controlplane components in a single container

## How to use this

### Deploy

#### For testing

```bash
docker run -it --rm \
    -e IP={IP Address, that kubelet can access} \
    -p 6443:6443 -p 8132:8132 \
    iwanhae/controlplane-in-docker
```

#### For persistent using

```bash
docker run -d --name kubernetes \
    -e IP={IP Address, that kubelet can access} \
    -p 6443:6443 -p 8132:8132 \
    -v {path_for_etcd}:/var/lib/etcd -v {path_for_certs}:/etc/kubernetes \
    iwanhae/controlplane-in-docker`
```

### Add Worker Nodes

**[at controlplane host]**

get bootstrap token by `docker exec -it {docker_id} kubeadm token list`

or create new one by  `docker exec -it {docker_id} kubeadm token create`

**[at worker node]**

after installing **kubeadm** and **Container Runtime** (docker, containerd, CRI-O... etc)

```bash
kubeadm join \
    {IP for kube-apiserver}:6443 \
    --token {bootstrap token} \
    --discovery-token-unsafe-skip-ca-verification # or you can use ca.crt from "path_for_certs"
```

### Result

```bash
~/controlplane-in-docker$ kubectl get node -o wide
NAME       STATUS   ROLES    AGE    VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
worker-1   Ready    <none>   2d9h   v1.24.1   192.168.0.24   <none>        Ubuntu 20.04.4 LTS   5.4.0-113-generic   containerd://1.5.9
worker-2   Ready    <none>   2d8h   v1.24.1   192.168.0.48   <none>        Ubuntu 20.04.4 LTS   5.4.0-113-generic   containerd://1.5.9
```

### FYI

This container requires to port-forward 8132 port. It is used by [konnectivity](https://kubernetes.io/docs/tasks/extend-kubernetes/setup-konnectivity/).