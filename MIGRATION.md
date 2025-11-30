# Helm v3 to v4 Migration Guide

This guide covers migrating your ADI Stack Helm deployments from Helm v3 to Helm v4.

## Overview

Helm v4 was released in November 2025 and introduces several improvements:

- **Server-Side Apply (SSA)**: Better conflict detection and GitOps compatibility
- **Values Schema Validation**: Automatic configuration validation via `values.schema.json`
- **OCI Digest Support**: Immutable chart references for supply chain security
- **Performance Improvements**: 40-60% faster deployments through content-based caching

This chart supports **both Helm v3 and v4** - no immediate migration is required.

## Compatibility Matrix

| Chart Version | Helm v3.14+ | Helm v4.0+ | Kubernetes |
| ------------- | ----------- | ---------- | ---------- |
| 0.2.0+        | Yes         | Yes        | 1.24+      |
| 0.1.x         | Yes         | Yes        | 1.24+      |

## Migration Steps

### Step 1: Verify Current Setup

```bash
# Check your current Helm version
helm version

# List current releases
helm list -n adi-stack
```

### Step 2: Install Helm v4

Both Helm v3 and v4 can coexist on the same machine.

```bash
# macOS
brew install helm

# Or download directly
curl https://get.helm.sh/helm-v4.0.3-darwin-arm64.tar.gz | tar xz
mv darwin-arm64/helm /usr/local/bin/helm4

# Verify installation
helm version
# Should show v4.x.x
```

### Step 3: Test Before Upgrading

```bash
# Dry-run an upgrade with Helm v4
helm upgrade adi-stack ./adi-stack \
  -n adi-stack \
  -f your-values.yaml \
  --dry-run

# Validate your values against the schema
helm lint ./adi-stack -f your-values.yaml --strict
```

### Step 4: Upgrade

```bash
# Standard upgrade (SSA is automatic in v4)
helm upgrade adi-stack ./adi-stack \
  -n adi-stack \
  -f your-values.yaml
```

## Server-Side Apply (SSA)

Helm v4 uses Server-Side Apply by default, which changes how resources are managed.

### What Changes

- **Field Ownership**: Helm tracks which fields it manages at the field level, not resource level
- **Conflict Detection**: Explicit errors if another controller modified Helm-managed fields
- **GitOps Compatibility**: Better coexistence with ArgoCD, Flux, and other tools

### Handling Conflicts

If you see ownership conflicts during upgrade:

```bash
# Option 1: Force Helm to take ownership (use with caution)
helm upgrade adi-stack ./adi-stack \
  -n adi-stack \
  -f your-values.yaml \
  --force-conflicts

# Option 2: Review conflicting fields and resolve manually
kubectl get statefulset adi-stack-external-node -n adi-stack \
  -o jsonpath='{.metadata.managedFields}' | jq
```

### GitOps Users

If you use ArgoCD, Flux, or similar tools alongside Helm:

1. **Review field ownership**: Ensure Helm and GitOps tools don't manage the same fields
2. **Consider using `--force-conflicts`**: If your GitOps tool is authoritative for certain fields
3. **Use annotations**: Mark resources that should be ignored by Helm or GitOps

## Values Schema Validation

The chart now includes `values.schema.json` for automatic validation.

### Benefits

- Configuration errors caught at deploy time
- IDE autocompletion (with YAML language server)
- Documentation built into the schema

### Common Validation Errors

```bash
# Error: Invalid storage size format
# Fix: Use proper Kubernetes quantity format
persistence:
  size: 500Gi  # Correct
  size: 500GB  # Wrong

# Error: Invalid Ethereum address format
# Fix: Use proper hex format with 0x prefix
genesis:
  bridgehubAddress: "0xc1662F0478e0E93Dc6CC321281Eb180A21036Da6"  # Correct
  bridgehubAddress: "c1662F0478e0E93Dc6CC321281Eb180A21036Da6"   # Wrong

# Error: Invalid chain value
# Fix: Use allowed enum values
erigon:
  chain: mainnet  # Correct (mainnet, sepolia, holesky)
  chain: goerli   # Wrong (not supported)
```

## Rollback

If you need to rollback after upgrading with Helm v4:

```bash
# List release history
helm history adi-stack -n adi-stack

# Rollback to previous revision
helm rollback adi-stack 1 -n adi-stack

# Or rollback with Helm v3 (if v4 release causes issues)
helm3 rollback adi-stack 1 -n adi-stack
```

## Troubleshooting

### "Error: chart requires Helm version X"

This chart supports both v3 and v4. If you see this error:

1. Check your Helm version: `helm version`
2. Ensure you're using v3.14+ or v4.0+

### SSA Conflict Errors

```
Error: UPGRADE FAILED: cannot patch "adi-stack-external-node" with kind StatefulSet:
Apply failed with 1 conflict: conflict with "kubectl" using apps/v1: .spec.replicas
```

**Solution**: Use `--force-conflicts` or manually resolve the conflict.

### Schema Validation Errors

```
Error: values don't meet the specifications of the schema(s)
```

**Solution**: Check your values file against the schema. Common issues:

- Typos in field names
- Wrong data types (string vs integer)
- Missing required fields

### Resources Not Updating

With SSA, unchanged fields aren't patched. This is expected behavior and improves performance.

## Support Timeline

| Version | Bug Fixes Until | Security Fixes Until |
| ------- | --------------- | -------------------- |
| Helm v3 | July 8, 2026    | November 11, 2026    |
| Helm v4 | Ongoing         | Ongoing              |

We recommend migrating to Helm v4 before November 2026.

## Resources

- [Helm v4 Release Blog](https://helm.sh/blog/helm-4-released/)
- [Server-Side Apply Documentation](https://kubernetes.io/docs/reference/using-api/server-side-apply/)
- [Helm v4 Changelog](https://helm.sh/docs/changelog/)
