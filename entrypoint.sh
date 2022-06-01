#!/bin/bash
CA_KEY=/etc/kubernetes/pki/ca.key
CA_CRT=/etc/kubernetes/pki/ca.crt

if [[ ! -v IP ]]; then
    echo "no env IP set. exit"
    exit -1
fi

if [[ ! -f "$CA_CRT" ]]; then
    IS_INIT=1
    echo "$CA_CRT not exists."
    bash cert.bash
fi

etcd \
    --advertise-client-urls=https://127.0.0.1:2379 \
    --cert-file=/etc/kubernetes/pki/etcd/server.crt \
    --client-cert-auth=true \
    --data-dir=/var/lib/etcd \
    --initial-advertise-peer-urls=https://127.0.0.1:2380 \
    --initial-cluster=master=https://127.0.0.1:2380 \
    --key-file=/etc/kubernetes/pki/etcd/server.key \
    --listen-client-urls=https://127.0.0.1:2379 \
    --listen-peer-urls=https://127.0.0.1:2380 \
    --name=master \
    --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt \
    --peer-client-cert-auth=true \
    --peer-key-file=/etc/kubernetes/pki/etcd/peer.key \
    --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \
    --snapshot-count=10000 \
    --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt &

kube-apiserver \
    --advertise-address=$IP \
    --allow-privileged=true \
    --authorization-mode=Node,RBAC \
    --client-ca-file=/etc/kubernetes/pki/ca.crt \
    --enable-admission-plugins=NodeRestriction \
    --enable-bootstrap-token-auth=true \
    --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt \
    --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt \
    --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key \
    --etcd-servers=https://127.0.0.1:2379 \
    --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
    --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
    --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
    --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
    --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
    --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
    --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt \
    --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key \
    --requestheader-allowed-names=front-proxy-client \
    --requestheader-client-ca-file=/etc/kubernetes/pki/ca.crt \
    --requestheader-extra-headers-prefix=X-Remote-Extra- \
    --requestheader-group-headers=X-Remote-Group \
    --requestheader-username-headers=X-Remote-User \
    --secure-port=6443 \
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \
    --service-account-key-file=/etc/kubernetes/pki/sa.pub \
    --service-account-signing-key-file=/etc/kubernetes/pki/sa.key \
    --service-cluster-ip-range=10.96.0.0/12 \
    --tls-cert-file=/etc/kubernetes/pki/apiserver.crt \
    --tls-private-key-file=/etc/kubernetes/pki/apiserver.key &

if [[ -v IS_INIT ]]; then
    kubeadm init phase upload-config kubeadm
    timeout 10s bash -c 'kubeadm init phase upload-config kubelet -v6' || true # it will be failed, but don't care
    kubeadm init phase addon all --apiserver-advertise-address $IP --control-plane-endpoint $IP
    kubeadm init phase bootstrap-token
    kubectl apply -f ./kube-flannel.yml    
fi


kube-controller-manager \
    --allocate-node-cidrs \
    --cluster-cidr=10.244.0.0/16 \
    --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf \
    --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf \
    --bind-address=127.0.0.1 \
    --client-ca-file=/etc/kubernetes/pki/ca.crt \
    --cluster-name=kubernetes \
    --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt \
    --cluster-signing-key-file=/etc/kubernetes/pki/ca.key \
    --controllers=*,bootstrapsigner,tokencleaner \
    --kubeconfig=/etc/kubernetes/controller-manager.conf \
    --leader-elect=true \
    --requestheader-client-ca-file=/etc/kubernetes/pki/ca.crt \
    --root-ca-file=/etc/kubernetes/pki/ca.crt \
    --service-account-private-key-file=/etc/kubernetes/pki/sa.key \
    --use-service-account-credentials=true &

kube-scheduler \
    --authentication-kubeconfig=/etc/kubernetes/scheduler.conf \
    --authorization-kubeconfig=/etc/kubernetes/scheduler.conf \
    --bind-address=127.0.0.1 \
    --kubeconfig=/etc/kubernetes/scheduler.conf \
    --leader-elect=false &

# need 
# to use iptables, `--cap-add NET_ADMIN`
# to use iptables in continaer network namespace, `--cap-add=NET_RAW`
# to use port forwarding, `--sysctl net.ipv4.conf.all.route_localnet=1`
if [[ -v ENABLE_KUBE_PROXY ]]; then
    kube-proxy --config=kube-proxy.conf &
fi

wait -n
exit $?
