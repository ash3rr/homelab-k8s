#!/usr/bin/env bash
set -euo pipefail

# 1. Start Colima
colima start --cpu 4 --memory 8

# 2. Create k3d cluster
k3d cluster create homelab \
  --servers 3 \
  --agents 2 \
  --port "5432:30432@loadbalancer" \
  --port "3306:30306@loadbalancer" \
  --port "1433:31433@loadbalancer"

kubectl config use-context k3d-homelab

# 3. Namespaces
kubectl apply -f namespaces/

# 4. CloudNativePG operator
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  -f helm/cnpg-values.yaml

# 5. Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f helm/prometheus-values.yaml

# 6. Database clusters and monitoring
kubectl apply -f postgres/
kubectl apply -f monitoring/
kubectl apply -f cnpg-operator-podmonitor.yaml
