# fetch konnectivity from container image
FROM registry.k8s.io/kas-network-proxy/proxy-server:v0.0.37 as konnectivity-server

FROM ubuntu:20.04

RUN apt-get update && apt-get install -y etcd openssl wget iptables vim curl

WORKDIR /root
RUN wget https://dl.k8s.io/v1.27.2/bin/linux/amd64/kubeadm && \
    wget https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-apiserver && \
    wget https://dl.k8s.io/v1.27.2/bin/linux/amd64/kubectl && \
    wget https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-controller-manager && \
    wget https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-scheduler && \
    chmod +x kube* && mv kube* /usr/local/bin
RUN apt-get install -y bash-completion && \
    echo 'source /etc/bash_completion' >> ~/.bashrc && \
    echo 'source <(kubectl completion bash)' >> ~/.bashrc && \
    rm -rf /var/lib/apt/lists/*
ENV KUBECONFIG=/etc/kubernetes/admin.conf

COPY --from=konnectivity-server /proxy-server /usr/local/bin
COPY deploy deploy
COPY config config
COPY cert.bash ./cert.bash
COPY entrypoint.sh entrypoint.sh
RUN mkdir -p /var/lib/konnectivity-server

VOLUME [ "/etc/kubernetes" ]
VOLUME [ "/var/lib/etcd" ]
EXPOSE 6443

CMD [ "bash", "entrypoint.sh" ]