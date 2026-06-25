#!/usr/bin/env bash
# setup.sh – End-to-end setup: install tools, create K3D cluster, install Istio
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLUSTER_CONFIG="${REPO_ROOT}/k3d/cluster-config.yaml"
CLUSTER_NAME="${CLUSTER_NAME:-istio-poc}"

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# ── sanity checks ─────────────────────────────────────────────────────────────
command -v docker &>/dev/null || die "Docker is required but not found. Please install Docker first."
TOTAL_RAM_GB=$(awk '/MemTotal/ { printf "%.0f", $2/1024/1024 }' /proc/meminfo 2>/dev/null || sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1073741824}')
if [[ "${TOTAL_RAM_GB:-0}" -lt 16 ]]; then
  log "WARNING: This setup is optimised for a 32 GB RAM host. Detected ~${TOTAL_RAM_GB} GB."
fi

# ── step 1: install k3d + kubectl ─────────────────────────────────────────────
log "==> Step 1/3: Installing prerequisites …"
bash "${SCRIPT_DIR}/install-k3d.sh"

# ── step 2: create K3D cluster ────────────────────────────────────────────────
log "==> Step 2/3: Creating K3D cluster '${CLUSTER_NAME}' …"
if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
  log "Cluster '${CLUSTER_NAME}' already exists – skipping creation."
else
  k3d cluster create --config "${CLUSTER_CONFIG}"
fi

log "Waiting for all nodes to be Ready …"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

log "Cluster nodes:"
kubectl get nodes -o wide

# ── step 3: install Istio ─────────────────────────────────────────────────────
log "==> Step 3/3: Installing Istio …"
bash "${SCRIPT_DIR}/install-istio.sh"

log ""
log "╔══════════════════════════════════════════════════════════════╗"
log "║  ✅  istio-poc cluster is ready!                             ║"
log "╠══════════════════════════════════════════════════════════════╣"
log "║  Cluster:   ${CLUSTER_NAME}"
log "║  Nodes:     1 server + 3 agents"
log "╠══════════════════════════════════════════════════════════════╣"
log "║  Dashboards (run 'make dashboards' or use port-forwards):   ║"
log "║    Kiali    → http://localhost:20001                         ║"
log "║    Grafana  → http://localhost:3000                          ║"
log "║    Jaeger   → http://localhost:16686                         ║"
log "║    Prometheus → http://localhost:9090                        ║"
log "╚══════════════════════════════════════════════════════════════╝"
