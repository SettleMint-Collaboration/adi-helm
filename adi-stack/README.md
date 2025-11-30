# ADI Stack Helm Chart

A production-ready Helm chart for deploying the ADI Stack (zkOS External Node) on Kubernetes and OpenShift clusters.

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

| Parameter                  | Description                |
| -------------------------- | -------------------------- |
| `genesis.bridgehubAddress` | Bridgehub contract address |
| `genesis.chainId`          | Chain ID for the network   |
| `genesis.mainNodeRpcUrl`   | Main node RPC URL          |
| `l1Rpc.url`                | L1 RPC endpoint URL        |

### Key Configuration Sections

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

#### Proof Sync

```yaml
proofSync:
  enabled: true
  azureStorageAccount: ""
  azureContainerName: ""
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

See the `examples/` directory for complete configuration examples:

- `values-testnet.yaml` - Testnet deployment
- `values-production.yaml` - Production deployment with HA
- `values-openshift.yaml` - OpenShift-specific configuration

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
