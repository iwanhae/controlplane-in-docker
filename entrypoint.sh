#!/bin/bash
CA_KEY=/etc/kubernetes/pki/ca.key
CA_CRT=/etc/kubernetes/pki/ca.crt

if [[ ! -f "$CA_CRT" ]]; then
    echo "$CA_CRT not exists."
    bash cert.bash
fi

bash kubeconfig.bash

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
    --advertise-address=$IP \
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

./kube-controller-manager \
    --authentication-kubeconfig=/root/.kube/config \
    --authorization-kubeconfig=/root/.kube/config \
    --bind-address=127.0.0.1 \
    --client-ca-file=/etc/kubernetes/pki/ca.crt \
    --cluster-name=kubernetes \
    --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt \
    --cluster-signing-key-file=/etc/kubernetes/pki/ca.key \
    --controllers=*,bootstrapsigner,tokencleaner \
    --kubeconfig=/root/.kube/config \
    --leader-elect=true \
    --requestheader-client-ca-file=/etc/kubernetes/pki/ca.crt \
    --root-ca-file=/etc/kubernetes/pki/ca.crt \
    --service-account-private-key-file=/etc/kubernetes/pki/sa.key \
    --use-service-account-credentials=true &

./kube-scheduler \
        --authentication-kubeconfig=/root/.kube/config \
        --authorization-kubeconfig=/root/.kube/config \
        --bind-address=127.0.0.1 \
        --kubeconfig=/root/.kube/config \
        --leader-elect=false &

wait -n
exit $?
