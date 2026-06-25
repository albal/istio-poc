# istio-poc

Istio Proof of Concept running on [K3D](https://k3d.io/) (K3s in Docker).

Designed for a host with **32 GB of RAM**, providing a production-like Istio
setup with the full observability stack (Prometheus, Grafana, Kiali, Jaeger).

---

## Architecture

| Component | Details |
|---|---|
| **K3D cluster** | 1 server node + 3 agent nodes |
| **Istio profile** | `default` (istiod + ingress gateway) |
| **Replicas** | istiod × 2, ingress-gateway × 2 |
| **Observability** | Prometheus, Grafana, Kiali, Jaeger |

## Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| **Docker** | 20.x+ | Must be running |
| **bash** | 4.x+ | macOS users: `brew install bash` |
| **curl** | any | Used by the install scripts |

> **RAM:** The cluster and Istio are sized for a 32 GB host. Running on less
> than 16 GB may cause instability.

## Quick start

```bash
# Clone the repository
git clone https://github.com/albal/istio-poc.git
cd istio-poc

# Full end-to-end setup (installs k3d, kubectl, istioctl, creates cluster, installs Istio)
make setup

# OR run the script directly
bash scripts/setup.sh
```

The setup script will:

1. Install `k3d` and `kubectl` if they are not already present.
2. Create a K3D cluster called `istio-poc` using `k3d/cluster-config.yaml`.
3. Download `istioctl` and install Istio using `istio/istio-operator.yaml`.
4. Label the `default` namespace for automatic sidecar injection.
5. Install the Prometheus / Grafana / Kiali / Jaeger addon manifests.

## Makefile targets

```
make setup           # Full end-to-end setup
make create-cluster  # Create the K3D cluster only
make install-istio   # Install Istio on an existing cluster
make dashboards      # Open all observability dashboards
make status          # Show node and Istio pod status
make destroy         # Delete the K3D cluster
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `K3D_VERSION` | `v5.7.4` | k3d release to install |
| `ISTIO_VERSION` | `1.22.3` | Istio release to install |
| `CLUSTER_NAME` | `istio-poc` | K3D cluster name |
| `INSTALL_DIR` | `/usr/local/bin` | Directory for installed binaries |

## Observability dashboards

After setup, the dashboards are available on the host via the K3D load-balancer
ports or via `istioctl dashboard <name>`:

| Dashboard | URL (K3D port-forward) | `istioctl` command |
|---|---|---|
| Kiali | <http://localhost:20001> | `istioctl dashboard kiali` |
| Grafana | <http://localhost:3000> | `istioctl dashboard grafana` |
| Jaeger | <http://localhost:16686> | `istioctl dashboard jaeger` |
| Prometheus | <http://localhost:9090> | `istioctl dashboard prometheus` |

```bash
# Open all dashboards at once
make dashboards
```

## Repository layout

```
.
├── Makefile                  # Convenience targets
├── k3d/
│   └── cluster-config.yaml   # K3D cluster definition (1 server + 3 agents)
├── istio/
│   └── istio-operator.yaml   # IstioOperator resource (sized for 32 GB host)
└── scripts/
    ├── setup.sh              # End-to-end orchestration script
    ├── install-k3d.sh        # Installs k3d and kubectl
    └── install-istio.sh      # Installs istioctl and deploys Istio
```

## Resource sizing (32 GB host)

| Component | CPU request | CPU limit | Memory request | Memory limit |
|---|---|---|---|---|
| istiod (×2) | 500 m | 2 | 512 Mi | 2 Gi |
| ingress-gateway (×2) | 100 m | 2 | 128 Mi | 1 Gi |
| Envoy sidecar (per pod) | 100 m | 2 | 128 Mi | 1 Gi |

## Teardown

```bash
make destroy
# or
k3d cluster delete istio-poc
```

## License

MIT – see [LICENSE](LICENSE).
