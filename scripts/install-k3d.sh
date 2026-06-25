#!/usr/bin/env bash
# install-k3d.sh – Install k3d and kubectl (if not already present)
set -euo pipefail

KUBECTL_VERSION="${KUBECTL_VERSION:-$(curl -sSL https://dl.k8s.io/release/stable.txt)}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── k3d ──────────────────────────────────────────────────────────────────────
if command -v k3d &>/dev/null; then
  log "k3d already installed: $(k3d version | head -1)"
else
  log "Installing latest k3d release …"
  # Omitting TAG causes the install script to resolve the latest GitHub release
  curl -sSL "https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh" | bash
  log "k3d installed: $(k3d version | head -1)"
fi

# ── kubectl ──────────────────────────────────────────────────────────────────
if command -v kubectl &>/dev/null; then
  log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  log "Installing kubectl ${KUBECTL_VERSION} …"
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "${ARCH}" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64)   ARCH="arm64" ;;
  esac
  curl -sSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl"
  chmod +x kubectl
  sudo mv kubectl "${INSTALL_DIR}/kubectl"
  log "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

log "Done – prerequisites satisfied."
