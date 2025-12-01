<p align="center">
  <img src="adi.svg" width="120px" align="center" alt="ADI Foundation logo" />
  <h1 align="center">ADI Stack Helm Chart</h1>
  <p align="center">
    A joint effort by <a href="https://adifoundation.ai">ADI Foundation</a> and <a href="https://settlemint.com">SettleMint</a>
    <br/>
    Production-ready Kubernetes deployment for ADI Stack zkOS L2 External Nodes.
  </p>
</p>
<br/>
<p align="center">
<a href="https://github.com/settlemint/adi-helm/actions?query=branch%3Amain"><img src="https://github.com/settlemint/adi-helm/actions/workflows/release.yml/badge.svg?event=push&branch=main" alt="CI status" /></a>
<a href="https://github.com/settlemint/adi-helm" rel="nofollow"><img src="https://img.shields.io/badge/helm-v3%20%7C%20v4-blue" alt="Helm v3 | v4"></a>
<a href="https://github.com/settlemint/adi-helm" rel="nofollow"><img src="https://img.shields.io/badge/kubernetes-1.24%2B-blue" alt="Kubernetes 1.24+"></a>
<a href="https://github.com/settlemint/adi-helm" rel="nofollow"><img src="https://img.shields.io/github/license/settlemint/adi-helm" alt="License"></a>
<a href="https://github.com/settlemint/adi-helm" rel="nofollow"><img src="https://img.shields.io/github/stars/settlemint/adi-helm" alt="stars"></a>
</p>

<div align="center">
  <a href="https://github.com/ADI-Foundation-Labs/ADI-Network-Documentation">Documentation</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://github.com/settlemint/adi-helm/issues">Issues</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://adifoundation.ai">ADI Foundation</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://settlemint.com">SettleMint</a>
  <br />
</div>

## Introduction

The ADI Stack Helm Chart provides a production-ready deployment solution for running ADI Stack zkOS L2 External Nodes on Kubernetes and OpenShift clusters. This chart is developed and maintained jointly by [ADI Foundation](https://adifoundation.ai) and [SettleMint](https://settlemint.com), combining ADI's blockchain expertise with SettleMint's enterprise deployment experience.

### Key Features

- **Multi-Platform Support** - Deploy on Kubernetes 1.24+ or OpenShift 4.12+
- **Multi-Cloud Ready** - Optimized configurations for AWS EKS, Google GKE, and Azure AKS
- **Integrated Ethereum Node** - Built-in Erigon node with Caplin consensus layer for L1 RPC
- **Performance Tiers** - Pre-configured resource profiles for development, testnet, and production
- **Flexible Ingress** - Auto-detection for Kubernetes Ingress, Gateway API, or OpenShift Routes
- **Enterprise Security** - OpenShift restricted SCC compatible, Pod Security Standards compliant
- **Cloudflare Tunnel** - Built-in Cloudflared support for secure external access
- **Monitoring Ready** - Prometheus ServiceMonitor support out of the box

## Quick Start

### Prerequisites

- Kubernetes 1.24+ or OpenShift 4.12+
- Helm 3.x or 4.x (both supported, v4 recommended for new installations)
- PersistentVolume provisioner support
- (Optional) Prometheus Operator for ServiceMonitor

> **Helm v4 Users**: This chart fully supports Helm v4 with Server-Side Apply (SSA), values schema validation, and OCI digest support.

### Installation

Add the Helm repository:

```bash
helm repo add adi-stack https://settlemint.github.io/adi-helm
helm repo update
```

Install with Helm using layered values files:

```bash
# Testnet deployment (Sepolia L1)
helm install adi-stack adi-stack/adi-stack \
  -n adi-testnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-testnet.yaml

# Mainnet deployment (Ethereum L1)
helm install adi-stack adi-stack/adi-stack \
  -n adi-mainnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-production.yaml

# Mainnet on AWS with high performance
helm install adi-stack adi-stack/adi-stack \
  -n adi-mainnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-production.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-cloud-aws.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-performance-high.yaml

# OpenShift testnet
helm install adi-stack adi-stack/adi-stack \
  -n adi-testnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-openshift-testnet.yaml

# OpenShift mainnet
helm install adi-stack adi-stack/adi-stack \
  -n adi-mainnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-openshift-mainnet.yaml

# Testnet with external L1 RPC (instead of built-in Erigon)
helm install adi-stack adi-stack/adi-stack \
  -n adi-testnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-testnet.yaml \
  --set erigon.enabled=false \
  --set l1Rpc.url=https://eth-sepolia.example.com

# Mainnet with external L1 RPC (instead of built-in Erigon)
helm install adi-stack adi-stack/adi-stack \
  -n adi-mainnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-production.yaml \
  --set erigon.enabled=false \
  --set l1Rpc.url=https://eth-mainnet.example.com
```

### Using the Install Script

For local development or when cloning the repository, use the install script:

```bash
git clone https://github.com/settlemint/adi-helm.git
cd adi-helm

# Testnet on AWS with TLS and external L1 RPC
./install.sh testnet \
  -n adi-testnet \
  -c aws \
  -p low \
  -i contour \
  -t \
  -u \
  -s erigon.enabled=false \
  -s l1Rpc.url=https://eth-sepolia.example.com

# Mainnet on AWS with TLS and external L1 RPC
./install.sh mainnet \
  -n adi-mainnet \
  -c aws \
  -p low \
  -i contour \
  -t \
  -u \
  -s erigon.enabled=false \
  -s l1Rpc.url=https://eth-mainnet.example.com
```

**Script options:**

| Flag | Long Form       | Description                               |
| ---- | --------------- | ----------------------------------------- |
| `-n` | `--namespace`   | Kubernetes namespace                      |
| `-c` | `--cloud`       | Cloud provider (aws, gke, azure)          |
| `-p` | `--performance` | Performance tier (low, medium, high)      |
| `-i` | `--ingress`     | Ingress controller (contour, nginx, none) |
| `-t` | `--tls`         | Enable TLS with cert-manager              |
| `-u` | `--upgrade`     | Upgrade existing release                  |
| `-s` | `--set`         | Set Helm values (can be repeated)         |

## Ingress Controller Setup

### Contour with HTTPProxy (Recommended)

Contour with HTTPProxy provides timeout configuration essential for blockchain JSON-RPC workloads. Contour is installed once and watches HTTPProxy resources across all namespaces.

**Step 1: Install Contour with Helm**

```bash
# Add the official Contour Helm repository
helm repo add contour https://projectcontour.github.io/helm-charts
helm repo update

# For AWS EKS (internet-facing NLB)
helm install contour contour/contour \
  -n gateway --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/support/contour-values-aws.yaml

# For Google GKE
helm install contour contour/contour \
  -n gateway --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/support/contour-values-gke.yaml

# For Azure AKS
helm install contour contour/contour \
  -n gateway --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/support/contour-values-azure.yaml

# Verify
kubectl get pods -n gateway
kubectl get svc -n gateway contour-envoy
```

**Step 2: Deploy adi-stack**

Deploy testnet and/or mainnet - both use the shared Contour/Envoy instance:

```bash
# Testnet
helm install adi-stack adi-stack/adi-stack \
  -n adi-testnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-testnet.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-ingress-contour.yaml \
  --set ingress.hostname=testnet.example.com

# Mainnet
helm install adi-stack adi-stack/adi-stack \
  -n adi-mainnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-production.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-ingress-contour.yaml \
  --set ingress.hostname=mainnet.example.com
```

**Step 3: Configure DNS**

Point your domains to the shared LoadBalancer:

```bash
# Get the LoadBalancer hostname/IP
kubectl get svc -n gateway contour-envoy \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create CNAME records:

- `testnet.example.com -> <loadbalancer-hostname>`
- `mainnet.example.com -> <loadbalancer-hostname>`

### Other Ingress Options

```bash
# Disable ingress (use port-forward or LoadBalancer service directly)
./install.sh testnet -i none

# NGINX Ingress (deprecated, EOL March 2026)
./install.sh testnet -i nginx
```

> **Note**: NGINX Ingress Controller is [end-of-life](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). We recommend Contour with Gateway API.

## Configuration

### Required Values

| Parameter                  | Description                | Example                                      |
| -------------------------- | -------------------------- | -------------------------------------------- |
| `genesis.bridgehubAddress` | Bridgehub contract address | `0xc1662F0478e0E93Dc6CC321281Eb180A21036Da6` |
| `genesis.chainId`          | Chain ID for the network   | `36900`                                      |
| `genesis.mainNodeRpcUrl`   | Main node RPC URL          | `https://rpc.ab.testnet.adifoundation.ai/`   |

### L1 RPC Configuration

The chart supports two modes for L1 RPC access:

#### Built-in Erigon Node (Recommended)

Erigon includes an integrated Caplin consensus layer, eliminating the need for a separate beacon node:

```yaml
erigon:
  enabled: true
  chain: mainnet # or "sepolia" for testnet
  pruneMode: full # archive, full, or minimal
  caplin:
    enabled: true
    checkpointSyncUrl: "https://beaconstate.info/eth/v2/debug/beacon/states/finalized"
  persistence:
    size: 2Ti # 500Gi for testnet/minimal
```

#### External RPC Provider

```yaml
erigon:
  enabled: false

l1Rpc:
  url: "https://eth-mainnet.example.com"
  # Or use existing secret:
  existingSecret:
    name: l1-rpc-credentials
    key: url
```

### Example Configurations

**Base configurations:**

| File                                     | Description                     |
| ---------------------------------------- | ------------------------------- |
| `examples/values-testnet.yaml`           | Kubernetes testnet (Sepolia)    |
| `examples/values-production.yaml`        | Kubernetes mainnet (production) |
| `examples/values-openshift-testnet.yaml` | OpenShift testnet               |
| `examples/values-openshift-mainnet.yaml` | OpenShift mainnet               |

**Cloud provider layers (combine with base):**

| File                               | Description                            |
| ---------------------------------- | -------------------------------------- |
| `examples/values-cloud-aws.yaml`   | AWS EKS (ALB ingress, gp3/io2 storage) |
| `examples/values-cloud-gke.yaml`   | Google GKE (GCE ingress, premium-rwo)  |
| `examples/values-cloud-azure.yaml` | Azure AKS (App Gateway, managed-csi)   |

**Performance tiers (combine with base and cloud):**

| File                                      | Description                    |
| ----------------------------------------- | ------------------------------ |
| `examples/values-performance-low.yaml`    | Development/testing (3K IOPS)  |
| `examples/values-performance-medium.yaml` | Testnet nodes (16K IOPS)       |
| `examples/values-performance-high.yaml`   | Production mainnet (64K+ IOPS) |

**Contour ingress controller (install before adi-stack):**

| File                                         | Description                           |
| -------------------------------------------- | ------------------------------------- |
| `examples/support/contour-values-aws.yaml`   | Contour for AWS EKS (internet-facing) |
| `examples/support/contour-values-gke.yaml`   | Contour for Google GKE                |
| `examples/support/contour-values-azure.yaml` | Contour for Azure AKS                 |

**Optional add-ons:**

| File                                               | Description                                     |
| -------------------------------------------------- | ----------------------------------------------- |
| `examples/values-ingress-contour.yaml`             | Contour HTTPProxy (recommended for JSON-RPC)    |
| `examples/values-tls-certmanager.yaml`             | TLS with cert-manager (Ingress and Gateway API) |
| `examples/support/cert-manager-clusterissuer.yaml` | ClusterIssuer for Let's Encrypt                 |

### TLS with cert-manager

For automatic TLS certificates with Let's Encrypt:

**Step 1: Install cert-manager with Helm**

```bash
# Add the cert-manager Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager with CRDs
helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true \
  --set extraArgs={--enable-gateway-api}

# Create ClusterIssuer (IMPORTANT: edit email address first!)
kubectl apply -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/support/cert-manager-clusterissuer.yaml
```

**Step 2: Deploy with TLS**

```bash
# Testnet with TLS
helm install adi-stack adi-stack/adi-stack \
  -n adi-testnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-testnet.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-ingress-contour.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-tls-certmanager.yaml \
  --set ingress.hostname=testnet.example.com

# Mainnet with TLS
helm install adi-stack adi-stack/adi-stack \
  -n adi-mainnet --create-namespace \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-production.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-ingress-contour.yaml \
  -f https://raw.githubusercontent.com/settlemint/adi-helm/main/adi-stack/examples/values-tls-certmanager.yaml \
  --set ingress.hostname=mainnet.example.com
```

**Step 3: Configure DNS and verify**

```bash
# Get LoadBalancer hostname and create CNAME record
kubectl get svc -n gateway contour-envoy \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Check certificate status (should show READY: True after DNS propagates)
kubectl get certificate -n adi-testnet
kubectl get certificate -n adi-mainnet
```

## Monitoring

Check pod status and sync progress:

```bash
# View all pods
kubectl get pods -n adi-stack

# Monitor Erigon sync progress
kubectl logs -n adi-stack -l app.kubernetes.io/component=erigon -f

# Monitor External Node logs
kubectl logs -n adi-stack -l app.kubernetes.io/component=external-node -f

# Access RPC endpoint locally
kubectl port-forward -n adi-stack svc/adi-stack-adi-stack 3050:3050
```

## Schema Validation

This chart includes a JSON schema (`values.schema.json`) for validating your configuration. Helm v4 uses this schema automatically during `helm install` and `helm upgrade` to catch configuration errors early.

```bash
# Validate your values file before deploying
helm lint ./adi-stack -f my-values.yaml --strict
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to the [GitHub repository](https://github.com/settlemint/adi-helm).

## About

### ADI Foundation

[ADI Foundation](https://adifoundation.ai) is building the next generation of blockchain infrastructure with zkOS, a zero-knowledge Layer 2 solution designed for scalability, security, and enterprise adoption.

### SettleMint

[SettleMint](https://settlemint.com) is the leading enterprise blockchain platform, providing tools and infrastructure for building, deploying, and managing blockchain applications at scale.

## License

This project is licensed under the MIT License - see the [LICENSE](adi-stack/LICENSE) file for details.
