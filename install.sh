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
  -f, --values <file>     Additional values file to merge
  -d, --dry-run           Perform a dry run (template only)
  -u, --upgrade           Upgrade existing release instead of install
  -h, --help              Show this help message

Examples:
  $0 mainnet                           # Install mainnet on Kubernetes
  $0 testnet -n adi-testnet            # Install testnet in custom namespace
  $0 mainnet -o                        # Install mainnet on OpenShift
  $0 testnet -o -n adi-test            # Install testnet on OpenShift
  $0 mainnet -u                        # Upgrade existing mainnet release
  $0 mainnet -d                        # Dry run for mainnet

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
EXTRA_VALUES=""
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
        -f|--values)
            EXTRA_VALUES="$2"
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

# Build helm command
HELM_CMD="helm"
if [[ "$DRY_RUN" == true ]]; then
    HELM_CMD="$HELM_CMD template"
else
    if [[ "$UPGRADE" == true ]]; then
        HELM_CMD="$HELM_CMD upgrade"
    else
        HELM_CMD="$HELM_CMD install"
    fi
fi

HELM_CMD="$HELM_CMD $RELEASE_NAME $CHART_DIR"
HELM_CMD="$HELM_CMD -n $NAMESPACE"
HELM_CMD="$HELM_CMD -f $VALUES_FILE"

if [[ -n "$EXTRA_VALUES" ]]; then
    if [[ ! -f "$EXTRA_VALUES" ]]; then
        log_error "Extra values file not found: $EXTRA_VALUES"
    fi
    HELM_CMD="$HELM_CMD -f $EXTRA_VALUES"
fi

if [[ "$DRY_RUN" == false ]]; then
    HELM_CMD="$HELM_CMD --create-namespace"
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
log_info "Executing: $HELM_CMD"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    eval "$HELM_CMD"
else
    eval "$HELM_CMD"

    echo ""
    log_info "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Check pod status:"
    echo "     kubectl get pods -n $NAMESPACE"
    echo ""
    echo "  2. View Reth sync progress:"
    echo "     kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=reth -f"
    echo ""
    echo "  3. View external-node logs:"
    echo "     kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=external-node -f"
    echo ""
    echo "  4. Access RPC endpoint:"
    echo "     kubectl port-forward -n $NAMESPACE svc/${RELEASE_NAME}-adi-stack 3050:3050"
    echo ""
fi
