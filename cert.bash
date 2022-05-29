#!/bin/bash
CA_KEY=/etc/kubernetes/pki/ca.key
CA_CRT=/etc/kubernetes/pki/ca.crt

./kubeadm certs generate-csr

echo "
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = No
ST = One
L = Care
O = About
OU = This
CN = kube-apiserver

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = 10.96.0.1
IP.3 = $IP

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
" > /default.cnf

# Generate RootCA for all
openssl genrsa -out $CA_KEY 2048
openssl req -x509 -new -nodes -key $CA_KEY -subj "/CN=kubernetes" -days 36500 -out $CA_CRT

# Signing all CSR
for FILE in $(find /etc/kubernetes -name '*.csr'); do 
CRT="${FILE%.*}.crt"
echo $FILE -> $CRT; 
openssl x509 -req -in $FILE -CA $CA_CRT -CAkey $CA_KEY -CAcreateserial -days 36500 -out $CRT -extensions v3_ext -extfile /default.cnf
done


# sa.key
openssl genrsa -out /etc/kubernetes/pki/sa.key
openssl rsa -in /etc/kubernetes/pki/sa.key -out /etc/kubernetes/pki/sa.pub -pubout