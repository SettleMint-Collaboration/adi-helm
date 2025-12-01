#!/usr/bin/env bash
set -euo pipefail

# ADI Stack Helm Chart Installer
# Usage: ./install.sh [mainnet|testnet] [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${SCRIPT_DIR}/adi-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
ADI Stack Helm Chart Installer

Usage: $0 <network> [options]

Networks:
  mainnet     Deploy with Ethereum mainnet (production)
  testnet     Deploy with Sepolia testnet

Options:
  -n, --namespace <ns>    Kubernetes namespace (default: adi-stack)
  -r, --release <name>    Helm release name (default: adi-stack)
  -o, --openshift         Use OpenShift-specific values
  -c, --cloud <provider>  Cloud provider: aws, gke, azure (optional)
  -p, --performance <tier> Performance tier: low, medium, high (default: medium)
  -t, --cert-manager      Use cert-manager for TLS certificates
  -f, --values <file>     Additional values file to merge
  -s, --set <key=value>   Set a Helm value (can be used multiple times)
  -d, --dry-run           Perform a dry run (template only)
  -u, --upgrade           Upgrade existing release instead of install
  -h, --help              Show this help message

Cloud Provider Settings (-c):
  aws     AWS EKS: gp3/io2 storage, ALB ingress annotations
  gke     Google GKE: premium-rwo/hyperdisk storage, GCE ingress
  azure   Azure AKS: managed-csi-premium storage, App Gateway ingress

Performance Tiers (-p):
  low     Development/Testing (3K IOPS, basic storage)
  medium  Testnet nodes (16K IOPS, SSD storage)
  high    Production mainnet (64K+ IOPS, premium storage)

Examples:
  $0 mainnet                           # Install mainnet on Kubernetes
  $0 testnet -n adi-testnet            # Install testnet in custom namespace
  $0 mainnet -o                        # Install mainnet on OpenShift
  $0 testnet -o -n adi-test            # Install testnet on OpenShift
  $0 mainnet -u                        # Upgrade existing mainnet release
  $0 mainnet -d                        # Dry run for mainnet
  $0 mainnet -c aws -p high            # AWS with high-performance storage
  $0 testnet -c gke -p medium          # GKE with medium-performance storage
  $0 mainnet -c azure -p high          # Azure with premium storage
  $0 testnet -c aws -t                 # AWS with cert-manager TLS
  $0 testnet -s erigon.enabled=false -s l1Rpc.url=https://eth.example.com  # External L1 RPC

EOF
    exit "${1:-0}"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Default values
NAMESPACE="adi-stack"
RELEASE_NAME="adi-stack"
OPENSHIFT=false
CLOUD_PROVIDER=""
PERFORMANCE_TIER="medium"
CERT_MANAGER=false
EXTRA_VALUES=""
HELM_SETS=()
DRY_RUN=false
UPGRADE=false
NETWORK=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        mainnet|testnet)
            NETWORK="$1"
            shift
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -o|--openshift)
            OPENSHIFT=true
            shift
            ;;
        -c|--cloud)
            CLOUD_PROVIDER="$2"
            if [[ ! "$CLOUD_PROVIDER" =~ ^(aws|gke|azure)$ ]]; then
                log_error "Invalid cloud provider: $CLOUD_PROVIDER (must be aws, gke, or azure)"
            fi
            shift 2
            ;;
        -p|--performance)
            PERFORMANCE_TIER="$2"
            if [[ ! "$PERFORMANCE_TIER" =~ ^(low|medium|high)$ ]]; then
                log_error "Invalid performance tier: $PERFORMANCE_TIER (must be low, medium, or high)"
            fi
            shift 2
            ;;
        -t|--cert-manager)
            CERT_MANAGER=true
            shift
            ;;
        -f|--values)
            EXTRA_VALUES="$2"
            shift 2
            ;;
        -s|--set)
            HELM_SETS+=("$2")
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -u|--upgrade)
            UPGRADE=true
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        *)
            log_error "Unknown option: $1"
            ;;
    esac
done

# Validate network selection
if [[ -z "$NETWORK" ]]; then
    log_error "Network must be specified: mainnet or testnet"
fi

# Check for required tools
command -v helm >/dev/null 2>&1 || log_error "helm is required but not installed"
command -v kubectl >/dev/null 2>&1 || log_error "kubectl is required but not installed"

# Determine values file based on network and platform
if [[ "$OPENSHIFT" == true ]]; then
    VALUES_FILE="${CHART_DIR}/examples/values-openshift-${NETWORK}.yaml"
    log_info "Using OpenShift configuration for ${NETWORK}"
else
    if [[ "$NETWORK" == "mainnet" ]]; then
        VALUES_FILE="${CHART_DIR}/examples/values-production.yaml"
    else
        VALUES_FILE="${CHART_DIR}/examples/values-testnet.yaml"
    fi
    log_info "Using Kubernetes configuration for ${NETWORK}"
fi

# Verify values file exists
if [[ ! -f "$VALUES_FILE" ]]; then
    log_error "Values file not found: $VALUES_FILE"
fi

log_info "Values file: $VALUES_FILE"
log_info "Namespace: $NAMESPACE"
log_info "Release: $RELEASE_NAME"

# Build layered values files array
VALUES_FILES=()
VALUES_FILES+=("$VALUES_FILE")

# Add cloud provider values file if specified
if [[ -n "$CLOUD_PROVIDER" ]]; then
    CLOUD_VALUES="${CHART_DIR}/examples/values-cloud-${CLOUD_PROVIDER}.yaml"
    if [[ -f "$CLOUD_VALUES" ]]; then
        VALUES_FILES+=("$CLOUD_VALUES")
        log_info "Cloud provider: $CLOUD_PROVIDER (using $CLOUD_VALUES)"
    else
        log_error "Cloud values file not found: $CLOUD_VALUES"
    fi
fi

# Add performance tier values file
PERF_VALUES="${CHART_DIR}/examples/values-performance-${PERFORMANCE_TIER}.yaml"
if [[ -f "$PERF_VALUES" ]]; then
    VALUES_FILES+=("$PERF_VALUES")
    log_info "Performance tier: $PERFORMANCE_TIER (using $PERF_VALUES)"
else
    log_warn "Performance values file not found: $PERF_VALUES (using defaults)"
fi

# Add cert-manager values file if requested
if [[ "$CERT_MANAGER" == true ]]; then
    CERTMGR_VALUES="${CHART_DIR}/examples/values-tls-certmanager.yaml"
    if [[ -f "$CERTMGR_VALUES" ]]; then
        VALUES_FILES+=("$CERTMGR_VALUES")
        log_info "TLS: Using cert-manager (letsencrypt-prod)"
    else
        log_error "cert-manager values file not found: $CERTMGR_VALUES"
    fi
fi

# Build helm command using array (no eval for security)
HELM_CMD=("helm")

if [[ "$DRY_RUN" == true ]]; then
    HELM_CMD+=("template")
else
    if [[ "$UPGRADE" == true ]]; then
        HELM_CMD+=("upgrade")
    else
        HELM_CMD+=("install")
    fi
fi

HELM_CMD+=("$RELEASE_NAME" "$CHART_DIR")
HELM_CMD+=("-n" "$NAMESPACE")

# Add all layered values files
for vf in "${VALUES_FILES[@]}"; do
    HELM_CMD+=("-f" "$vf")
done

# Add extra values file if specified
if [[ -n "$EXTRA_VALUES" ]]; then
    if [[ ! -f "$EXTRA_VALUES" ]]; then
        log_error "Extra values file not found: $EXTRA_VALUES"
    fi
    HELM_CMD+=("-f" "$EXTRA_VALUES")
fi

# Add --set arguments
for set_arg in "${HELM_SETS[@]}"; do
    HELM_CMD+=("--set" "$set_arg")
    log_info "Set: $set_arg"
done

if [[ "$DRY_RUN" == false ]]; then
    HELM_CMD+=("--create-namespace")
    if [[ "$UPGRADE" == false ]]; then
        # Check if release already exists
        if helm status "$RELEASE_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
            log_warn "Release '$RELEASE_NAME' already exists in namespace '$NAMESPACE'"
            log_info "Use -u/--upgrade to upgrade the existing release"
            exit 1
        fi
    fi
fi

# Execute
log_info "Executing: ${HELM_CMD[*]}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    "${HELM_CMD[@]}"
else
    "${HELM_CMD[@]}"

    echo ""
    log_info "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Check pod status:"
    echo "     kubectl get pods -n $NAMESPACE"
    echo ""
    echo "  2. View Erigon sync progress:"
    echo "     kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=erigon -f"
    echo ""
    echo "  3. View external-node logs:"
    echo "     kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=external-node -f"
    echo ""
    echo "  4. Access RPC endpoint (get service name from 'helm status ${RELEASE_NAME} -n ${NAMESPACE}'):"
    echo "     kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-adi-stack 3050:3050"
    echo ""
fi
