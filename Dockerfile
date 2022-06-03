# fetch konnectivity from container image
FROM us.gcr.io/k8s-artifacts-prod/kas-network-proxy/proxy-server:v0.0.16 as konnectivity-server

FROM ubuntu:20.04

RUN apt-get update && apt-get install -y etcd openssl wget iptables vim curl

WORKDIR /root
RUN wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubeadm && \
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-apiserver && \
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kubectl && \
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-controller-manager && \
    wget https://dl.k8s.io/v1.23.7/bin/linux/amd64/kube-scheduler && \
    chmod +x kube* && mv kube* /usr/local/bin
RUN apt-get install -y bash-completion && \
    echo 'source /etc/bash_completion' >> ~/.bashrc && \
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
ENV KUBECONFIG=/etc/kubernetes/admin.conf

COPY --from=konnectivity-server /proxy-server /usr/local/bin
COPY deploy deploy
COPY config config
COPY cert.bash ./cert.bash
COPY entrypoint.sh entrypoint.sh

VOLUME [ "/etc/kubernetes" ]
VOLUME [ "/var/lib/etcd" ]
EXPOSE 6443

CMD [ "bash", "entrypoint.sh" ]