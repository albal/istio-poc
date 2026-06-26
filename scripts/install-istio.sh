#!/usr/bin/env bash
# install-istio.sh – Download istioctl and install Istio on the current cluster
set -euo pipefail

ISTIO_VERSION="${ISTIO_VERSION:-$(curl -sSL https://api.github.com/repos/istio/istio/releases/latest | grep '"tag_name"' | awk -F'"' '{print $4}')}"
ISTIO_OPERATOR_FILE="${ISTIO_OPERATOR_FILE:-$(dirname "$0")/../istio/istio-operator.yaml}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── istioctl ──────────────────────────────────────────────────────────────────
if command -v istioctl &>/dev/null && istioctl version --remote=false 2>/dev/null | grep -q "${ISTIO_VERSION}"; then
  log "istioctl ${ISTIO_VERSION} already installed."
else
  log "Downloading istioctl ${ISTIO_VERSION} …"
  curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" TARGET_ARCH="$(uname -m)" sh -
  sudo mv "istio-${ISTIO_VERSION}/bin/istioctl" "${INSTALL_DIR}/istioctl"
  rm -rf "istio-${ISTIO_VERSION}"
  log "istioctl installed: $(istioctl version --remote=false)"
fi

# ── pre-flight check ──────────────────────────────────────────────────────────
log "Running istioctl pre-flight checks …"
istioctl x precheck

# ── install Istio ─────────────────────────────────────────────────────────────
log "Installing Istio using operator profile from ${ISTIO_OPERATOR_FILE} …"
istioctl install -f "${ISTIO_OPERATOR_FILE}" --skip-confirmation

# ── label default namespace ───────────────────────────────────────────────────
log "Enabling automatic sidecar injection in 'default' namespace …"
kubectl label namespace default istio-injection=enabled --overwrite

# ── wait for control plane ────────────────────────────────────────────────────
log "Waiting for Istio control plane to become ready …"
kubectl rollout status deployment/istiod -n istio-system --timeout=300s
kubectl rollout status deployment/istio-ingressgateway -n istio-system --timeout=300s

# ── install observability addons ─────────────────────────────────────────────
ADDONS_BASE="https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons"
log "Installing observability addons (Prometheus, Grafana, Kiali, Jaeger) …"
for addon in prometheus grafana kiali jaeger; do
  kubectl apply -f "${ADDONS_BASE}/${addon}.yaml" || true
done

log "Waiting for addon deployments …"
for deploy in prometheus grafana kiali jaeger; do
  kubectl rollout status deployment/"${deploy}" -n istio-system --timeout=180s 2>/dev/null || true
done

log ""
log "✅  Istio ${ISTIO_VERSION} installed successfully."
log ""
log "Ingress gateway address:"
kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}' 2>/dev/null || \
  kubectl get svc istio-ingressgateway -n istio-system
