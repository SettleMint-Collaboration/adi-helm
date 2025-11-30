# ADI Stack Helm Chart

A production-ready Helm chart for deploying the ADI Stack (zkOS External Node) on Kubernetes and OpenShift clusters.

## Features

- **Multi-Cloud Support** - Optimized for AWS EKS, Google GKE, and Azure AKS
- **Integrated Erigon Node** - Built-in Ethereum node with Caplin consensus layer
- **Performance Tiers** - Pre-configured profiles for dev, testnet, and production workloads
- **Layered Configuration** - Combine base, cloud, and performance values files

## Prerequisites

- Kubernetes 1.24+ or OpenShift 4.12+
- Helm 3.x
- PV provisioner support in the underlying infrastructure
- (Optional) Prometheus Operator for ServiceMonitor
- (Optional) Gateway API CRDs for Gateway ingress type

## Installation

### From Helm Repository (Recommended)

```bash
# Add the repository
helm repo add adi-helm https://settlemint.github.io/adi-helm
helm repo update

# Install the chart
helm install adi-stack adi-helm/adi-stack \
  --namespace adi-stack \
  --create-namespace \
  -f values.yaml
```

### From Source

```bash
git clone https://github.com/settlemint/adi-helm
helm install adi-stack ./adi-helm/adi-stack -f values.yaml
```

## Configuration

### Required Values

| Parameter                  | Description                               |
| -------------------------- | ----------------------------------------- |
| `genesis.bridgehubAddress` | Bridgehub contract address                |
| `genesis.chainId`          | Chain ID for the network                  |
| `genesis.mainNodeRpcUrl`   | Main node RPC URL                         |
| `l1Rpc.url`                | L1 RPC endpoint URL (if not using Erigon) |

### Key Configuration Sections

#### Erigon (Integrated L1 Node)

```yaml
erigon:
  enabled: true
  chain: mainnet # mainnet, sepolia, or holesky
  pruneMode: full # archive (~2TB), full (~1TB), minimal (~500GB)
  caplin:
    enabled: true # Integrated consensus layer
    checkpointSyncUrl: "https://beaconstate.info/eth/v2/debug/beacon/states/finalized"
  persistence:
    size: 2Ti
    storageClass: "" # Use cluster default
  resources:
    requests:
      cpu: "4"
      memory: "16Gi"
```

#### External Node

```yaml
externalNode:
  image:
    repository: harbor.sre.ideasoft.io/adi-chain/external-node
    tag: "latest"
  resources:
    requests:
      memory: "4Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"
  persistence:
    size: 100Gi
    storageClass: "" # Use cluster default
```

#### Cloudflared TCP Proxy

```yaml
cloudflared:
  enabled: true
  tunnelToken: "" # Set via --set or existingSecret
  existingSecret:
    name: ""
    key: ""
```

### Ingress Options

The chart supports three ingress types with auto-detection:

#### Kubernetes Ingress (default)

```yaml
ingress:
  enabled: true
  type: auto # or "ingress"
  hostname: adi.example.com
  tls:
    enabled: true
    secretName: adi-tls
```

#### Gateway API

```yaml
ingress:
  enabled: true
  type: gateway
  hostname: adi.example.com
  gateway:
    gatewayClassName: istio
```

#### OpenShift Routes

```yaml
ingress:
  enabled: true
  type: route
  hostname: adi.example.com
  route:
    termination: edge
```

### Security Configuration

#### Pod Security Standards

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

containerSecurityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

#### OpenShift-specific

```yaml
openshift:
  enabled: true
  securityContext:
    runAsNonRoot: true
    # runAsUser omitted - assigned by OpenShift
```

### Monitoring

```yaml
metrics:
  serviceMonitor:
    enabled: true
    interval: 30s
    labels:
      release: prometheus
```

## Examples

The `examples/` directory contains layered configuration files. Combine them as needed:

**Base configurations:**

- `values-testnet.yaml` - Testnet deployment (Sepolia)
- `values-production.yaml` - Production mainnet
- `values-openshift-testnet.yaml` - OpenShift testnet
- `values-openshift-mainnet.yaml` - OpenShift mainnet

**Cloud provider layers:**

- `values-cloud-aws.yaml` - AWS EKS (ALB ingress, gp3/io2 storage)
- `values-cloud-gke.yaml` - Google GKE (GCE ingress, premium-rwo storage)
- `values-cloud-azure.yaml` - Azure AKS (App Gateway, managed-csi storage)

**Performance tiers:**

- `values-performance-low.yaml` - Development (3K IOPS)
- `values-performance-medium.yaml` - Testnet (16K IOPS)
- `values-performance-high.yaml` - Production (64K+ IOPS)

**Optional add-ons:**

- `values-tls-certmanager.yaml` - TLS with cert-manager

**Example usage:**

```bash
# AWS mainnet with high performance
helm install adi-stack ./adi-stack \
  -f examples/values-production.yaml \
  -f examples/values-cloud-aws.yaml \
  -f examples/values-performance-high.yaml
```

## Upgrading

```bash
helm upgrade adi-stack adi/adi-stack -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall adi-stack
```

Note: PersistentVolumeClaims are not deleted automatically. Remove them manually if needed:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=adi-stack
```

## Troubleshooting

### Check pod status

```bash
kubectl get pods -l app.kubernetes.io/instance=adi-stack
```

### View logs

```bash
kubectl logs -l app.kubernetes.io/component=external-node -f
```

### Run helm tests

```bash
helm test adi-stack
```
