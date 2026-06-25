.PHONY: help setup create-cluster install-istio dashboards destroy

CLUSTER_NAME ?= istio-poc
ISTIO_VERSION ?= 1.22.3

help: ## Show this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z_-]+:.*?##/{printf "  \033[36m%-20s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)

setup: ## Install tools, create K3D cluster and install Istio (full end-to-end)
	bash scripts/setup.sh

create-cluster: ## Create the K3D cluster only
	k3d cluster create --config k3d/cluster-config.yaml

install-istio: ## Install Istio on the existing cluster
	ISTIO_VERSION=$(ISTIO_VERSION) bash scripts/install-istio.sh

dashboards: ## Open observability dashboards via istioctl
	istioctl dashboard kiali &
	istioctl dashboard grafana &
	istioctl dashboard jaeger &
	istioctl dashboard prometheus &

destroy: ## Delete the K3D cluster entirely
	k3d cluster delete $(CLUSTER_NAME)

status: ## Show cluster and Istio status
	@echo "=== Nodes ==="
	kubectl get nodes -o wide
	@echo ""
	@echo "=== Istio pods ==="
	kubectl get pods -n istio-system
	@echo ""
	@echo "=== Ingress gateway ==="
	kubectl get svc istio-ingressgateway -n istio-system
