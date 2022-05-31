#!/bin/bash
CA_KEY=/etc/kubernetes/pki/ca.key
CA_CRT=/etc/kubernetes/pki/ca.crt

kubeadm init phase certs all --apiserver-advertise-address $IP --apiserver-cert-extra-sans 127.0.0.1
kubeadm init phase kubeconfig controller-manager --apiserver-advertise-address $IP --control-plane-endpoint 127.0.0.1
kubeadm init phase kubeconfig scheduler --apiserver-advertise-address $IP --control-plane-endpoint 127.0.0.1
kubeadm init phase kubeconfig admin --apiserver-advertise-address $IP --control-plane-endpoint $IP