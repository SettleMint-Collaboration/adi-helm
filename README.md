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
<a href="https://github.com/ADI-Foundation-Labs/adi-helm/actions?query=branch%3Amain"><img src="https://github.com/ADI-Foundation-Labs/adi-helm/actions/workflows/lint.yml/badge.svg?event=push&branch=main" alt="CI status" /></a>
<a href="https://github.com/ADI-Foundation-Labs/adi-helm" rel="nofollow"><img src="https://img.shields.io/badge/helm-v3-blue" alt="Helm v3"></a>
<a href="https://github.com/ADI-Foundation-Labs/adi-helm" rel="nofollow"><img src="https://img.shields.io/badge/kubernetes-1.24%2B-blue" alt="Kubernetes 1.24+"></a>
<a href="https://github.com/ADI-Foundation-Labs/adi-helm" rel="nofollow"><img src="https://img.shields.io/github/license/ADI-Foundation-Labs/adi-helm" alt="License"></a>
<a href="https://github.com/ADI-Foundation-Labs/adi-helm" rel="nofollow"><img src="https://img.shields.io/github/stars/ADI-Foundation-Labs/adi-helm" alt="stars"></a>
</p>

<div align="center">
  <a href="https://github.com/ADI-Foundation-Labs/ADI-Network-Documentation">Documentation</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://github.com/ADI-Foundation-Labs/adi-helm/issues">Issues</a>
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
- **Integrated Ethereum Node** - Optional built-in Reth node for L1 RPC (mainnet or Sepolia)
- **Flexible Ingress** - Auto-detection for Kubernetes Ingress, Gateway API, or OpenShift Routes
- **Enterprise Security** - OpenShift restricted SCC compatible, Pod Security Standards compliant
- **Cloudflare Tunnel** - Built-in Cloudflared support for secure external access
- **Proof Synchronization** - Azure Blob Storage integration for proof data
- **Monitoring Ready** - Prometheus ServiceMonitor support out of the box

## Quick Start

### Prerequisites

- Kubernetes 1.24+ or OpenShift 4.12+
- Helm 3.x
- PersistentVolume provisioner support
- (Optional) Prometheus Operator for ServiceMonitor

### Installation

Use the included install script for guided deployment:

```bash
# Clone the repository
git clone https://github.com/ADI-Foundation-Labs/adi-helm.git
cd adi-helm

# Deploy to testnet (Sepolia)
./install.sh testnet

# Deploy to mainnet
./install.sh mainnet

# Deploy on OpenShift
./install.sh testnet --openshift
./install.sh mainnet --openshift
```

Or install directly with Helm:

```bash
# Testnet deployment
helm install adi-stack ./adi-stack \
  -n adi-stack --create-namespace \
  -f adi-stack/examples/values-testnet.yaml

# Mainnet deployment
helm install adi-stack ./adi-stack \
  -n adi-stack --create-namespace \
  -f adi-stack/examples/values-production.yaml
```

## Configuration

### Required Values

| Parameter                  | Description                | Example                                      |
| -------------------------- | -------------------------- | -------------------------------------------- |
| `genesis.bridgehubAddress` | Bridgehub contract address | `0xc1662F0478e0E93Dc6CC321281Eb180A21036Da6` |
| `genesis.chainId`          | Chain ID for the network   | `36900`                                      |
| `genesis.mainNodeRpcUrl`   | Main node RPC URL          | `https://rpc.ab.testnet.adifoundation.ai/`   |

### L1 RPC Configuration

The chart supports two modes for L1 RPC access:

#### Built-in Reth Node (Recommended)

```yaml
reth:
  enabled: true
  chain: mainnet # or "sepolia" for testnet
  syncMode: checkpoint
  persistence:
    size: 1500Gi # 100Gi for Sepolia
```

#### External RPC Provider

```yaml
reth:
  enabled: false

l1Rpc:
  url: "https://eth-mainnet.example.com"
  # Or use existing secret:
  existingSecret:
    name: l1-rpc-credentials
    key: url
```

### Example Configurations

| File                                     | Description                     |
| ---------------------------------------- | ------------------------------- |
| `examples/values-testnet.yaml`           | Kubernetes testnet (Sepolia)    |
| `examples/values-production.yaml`        | Kubernetes mainnet (production) |
| `examples/values-openshift-testnet.yaml` | OpenShift testnet               |
| `examples/values-openshift-mainnet.yaml` | OpenShift mainnet               |

## Monitoring

Check pod status and sync progress:

```bash
# View all pods
kubectl get pods -n adi-stack

# Monitor Reth sync progress
kubectl logs -n adi-stack -l app.kubernetes.io/component=reth -f

# Monitor External Node logs
kubectl logs -n adi-stack -l app.kubernetes.io/component=external-node -f

# Access RPC endpoint locally
kubectl port-forward -n adi-stack svc/adi-stack-adi-stack 3050:3050
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to the [GitHub repository](https://github.com/ADI-Foundation-Labs/adi-helm).

## About

### ADI Foundation

[ADI Foundation](https://adifoundation.ai) is building the next generation of blockchain infrastructure with zkOS, a zero-knowledge Layer 2 solution designed for scalability, security, and enterprise adoption.

### SettleMint

[SettleMint](https://settlemint.com) is the leading enterprise blockchain platform, providing tools and infrastructure for building, deploying, and managing blockchain applications at scale.

## License

This project is licensed under the MIT License - see the [LICENSE](adi-stack/LICENSE) file for details.
