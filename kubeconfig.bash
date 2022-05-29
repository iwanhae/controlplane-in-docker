#!/bin/bash
CA_KEY=/etc/kubernetes/pki/ca.key
CA_CRT=/etc/kubernetes/pki/ca.crt

# kubectl
echo "
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
C = No
ST = One
L = Care
O = system:masters
OU = This
CN = default-admin


[ v3_ext ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = \"OpenSSL Generated Client Certificate\"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
" > admin.cnf

openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -config admin.cnf
openssl x509 -req -in admin.csr -CA $CA_CRT -CAkey $CA_KEY \
    	-CAcreateserial -out admin.crt -days 10000 \
    	-extensions v3_ext -extfile admin.cnf

./kubectl config set-cluster local --server=https://127.0.0.1:6443 --certificate-authority=$CA_CRT
./kubectl config set-credentials admin --client-certificate=./admin.crt --client-key=./admin.key
./kubectl config set-context local-context --cluster=local --user=admin
./kubectl config use-context local-context