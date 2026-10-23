#!/usr/bin/env bash
set -euo pipefail

echo "Checking Colima..."
if ! colima status &>/dev/null; then
  echo "Colima is not running. Starting it..."
  colima start --cpu 4 --memory 8
fi

echo "Setting kubectl context..."
kubectl config use-context k3d-homelab

echo "Starting port-forwards..."

kubectl port-forward -n databases svc/pg-lab-rw 5432:5432 > /tmp/pg-pf.log 2>&1 &
echo "Postgres (pg-lab-rw) -> localhost:5432 [PID $!]"

kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 > /tmp/grafana-pf.log 2>&1 &
echo "Grafana -> localhost:3000 [PID $!]"

kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 > /tmp/prom-pf.log 2>&1 &
echo "Prometheus -> localhost:9090 [PID $!]"

sleep 2
echo ""
echo "Active port-forward jobs:"
jobs

echo ""
echo "If any job shows 'Done' or 'Exit', check its log in /tmp/*-pf.log"
