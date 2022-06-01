# controlplane-in-docker
all kubernetes controlplane components in a single container

## How to use this

### Deploy

#### For testing

```bash
docker run -it --rm \
    -e IP={IP Address, that kubelet can access} \
    -p 6443:6443 iwanhae/controlplane-in-docker
```

#### For persistent using

```bash
docker run -d --name kubernetes \
    -e IP={IP Address, that kubelet can access} \
    -p 6443:6443 -v {path_for_etcd}:/var/lib/etcd -v {path_for_certs}:/etc/kubernetes \
    iwanhae/controlplane-in-docker`
```

#### For persistent using with kube-proxy

This might not work depends on your kernel status.

related: https://github.com/kubernetes-sigs/kind/issues/1461#issuecomment-748605056

```bash
docker run -d --name kubernetes \
    -e IP={IP Address, that kubelet can access} \
    -e ENABLE_KUBE_PROXY=true \
    -v {path_for_etcd}:/var/lib/etcd -v {path_for_certs}:/etc/kubernetes \
    -p 6443:6443 --cap-add NET_ADMIN --cap-add=NET_RAW --sysctl net.ipv4.conf.all.route_localnet=1 \
    iwanhae/controlplane-in-docker
```

kube-proxy` will make kube-apiserver possible to use ClusterIP, which is prettry useful when using AdmissionWebhook, aggregation layer (metrics server uses this feature), etc. 

But, this does not mean that your kube-apiserver can access Pods by Pod IP (this is a CNI's job). So if you need these kind of feature, be sure that your target Pod is deployed with `hostNetwork: true`. This will make your Pod to have NodeIP, and make possible to access this Pod with NodeIP.

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

### TO DO

Use `Konnectivity` instead of `kube-proxy`. https://kubernetes.io/docs/tasks/extend-kubernetes/setup-konnectivity/
My Synology NAS kernel does not support `xt_comment`, which is necessary for `kube-proxy` :-(