#!/usr/bin/env bash
set -euo pipefail

echo "Deleting k3d cluster (this removes all workloads, namespaces, and Helm releases running inside it)..."
k3d cluster delete homelab

echo "Stopping Colima..."
colima stop

echo "Done. Run ./setup.sh to rebuild from scratch."
