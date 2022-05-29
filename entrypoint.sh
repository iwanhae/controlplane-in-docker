#!/bin/bash

CA_CRT=/etc/kubernetes/pki/ca.crt

if [[ ! -f "$CA_CRT" ]]; then
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
    --peer-trusted-ca-file=/etc/kubernetes/pki/ca.crt \
    --snapshot-count=10000 \
    --trusted-ca-file=/etc/kubernetes/pki/ca.crt &

./kube-apiserver \
    --advertise-address=$HOST \
    --allow-privileged=true \
    --authorization-mode=Node,RBAC \
    --client-ca-file=/etc/kubernetes/pki/ca.crt \
    --enable-admission-plugins=NodeRestriction \
    --enable-bootstrap-token-auth=true \
    --etcd-cafile=/etc/kubernetes/pki/ca.crt \
    --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt \
    --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key \
    --etcd-servers=https://127.0.0.1:2379 \
    --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
    --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
    --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
    --secure-port=6443 \
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \
    --service-account-key-file=/etc/kubernetes/pki/sa.pub \
    --service-account-signing-key-file=/etc/kubernetes/pki/sa.key \
    --service-cluster-ip-range=10.96.0.0/12 \
    --tls-cert-file=/etc/kubernetes/pki/apiserver.crt \
    --tls-private-key-file=/etc/kubernetes/pki/apiserver.key &

wait -n
exit $?
