{{/*
Expand the name of the chart.
*/}}
{{- define "adi-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "adi-stack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "adi-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "adi-stack.labels" -}}
helm.sh/chart: {{ include "adi-stack.chart" . }}
{{ include "adi-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "adi-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "adi-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Labels for immutable resources (PVCs) - excludes version which changes
*/}}
{{- define "adi-stack.immutableLabels" -}}
helm.sh/chart: {{ .Chart.Name }}
{{ include "adi-stack.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "adi-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "adi-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Determine the ingress type to use (auto-detection or explicit)
*/}}
{{- define "adi-stack.ingressType" -}}
{{- $type := .Values.ingress.type -}}
{{- if eq $type "auto" -}}
  {{- if .Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1" -}}
    gateway
  {{- else if .Capabilities.APIVersions.Has "route.openshift.io/v1" -}}
    route
  {{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1" -}}
    ingress
  {{- else -}}
    none
  {{- end -}}
{{- else -}}
  {{- $type -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper image name for external-node
*/}}
{{- define "adi-stack.externalNode.image" -}}
{{- $registry := .Values.externalNode.image.registry -}}
{{- if .Values.global.imageRegistry -}}
{{- $registry = .Values.global.imageRegistry -}}
{{- end -}}
{{- if .Values.externalNode.image.digest -}}
{{- printf "%s/%s@%s" $registry .Values.externalNode.image.repository .Values.externalNode.image.digest -}}
{{- else -}}
{{- printf "%s/%s:%s" $registry .Values.externalNode.image.repository (.Values.externalNode.image.tag | default .Chart.AppVersion) -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper image name for proof-sync
*/}}
{{- define "adi-stack.proofSync.image" -}}
{{- $registry := .Values.proofSync.image.registry -}}
{{- if .Values.global.imageRegistry -}}
{{- $registry = .Values.global.imageRegistry -}}
{{- end -}}
{{- printf "%s/%s:%s" $registry .Values.proofSync.image.repository .Values.proofSync.image.tag -}}
{{- end -}}

{{/*
Return the proper image name for erigon
*/}}
{{- define "adi-stack.erigon.image" -}}
{{- $registry := .Values.erigon.image.registry -}}
{{- if .Values.global.imageRegistry -}}
{{- $registry = .Values.global.imageRegistry -}}
{{- end -}}
{{- printf "%s/%s:%s" $registry .Values.erigon.image.repository .Values.erigon.image.tag -}}
{{- end -}}

{{/*
Return the L1 RPC secret name
*/}}
{{- define "adi-stack.l1RpcSecretName" -}}
{{- if .Values.l1Rpc.existingSecret -}}
{{- .Values.l1Rpc.existingSecret -}}
{{- else -}}
{{- include "adi-stack.fullname" . -}}-secrets
{{- end -}}
{{- end -}}

{{/*
Return the L1 RPC secret key
*/}}
{{- define "adi-stack.l1RpcSecretKey" -}}
{{- if .Values.l1Rpc.existingSecret -}}
{{- .Values.l1Rpc.existingSecretKey -}}
{{- else -}}
l1-rpc-url
{{- end -}}
{{- end -}}

{{/*
Return the L1 RPC fallback secret name
*/}}
{{- define "adi-stack.l1RpcFallbackSecretName" -}}
{{- if .Values.l1Rpc.fallback.existingSecret -}}
{{- .Values.l1Rpc.fallback.existingSecret -}}
{{- else -}}
{{- include "adi-stack.fullname" . -}}-secrets
{{- end -}}
{{- end -}}

{{/*
Return the L1 RPC fallback secret key
*/}}
{{- define "adi-stack.l1RpcFallbackSecretKey" -}}
{{- if .Values.l1Rpc.fallback.existingSecret -}}
{{- .Values.l1Rpc.fallback.existingSecretKey -}}
{{- else -}}
l1-rpc-url
{{- end -}}
{{- end -}}

{{/*
Resolve L1 RPC URL
Returns the L1 RPC URL based on configuration priority:
1. erigon.enabled=true → internal Erigon service
2. l1Rpc.url → explicit URL
3. l1Rpc.existingSecret → will be resolved from secret (empty here)
*/}}
{{- define "adi-stack.l1RpcUrl" -}}
{{- if .Values.erigon.enabled -}}
http://{{ include "adi-stack.fullname" . }}-erigon:{{ .Values.erigon.httpPort }}
{{- else if .Values.l1Rpc.url -}}
{{ .Values.l1Rpc.url }}
{{- end -}}
{{- end -}}

{{/*
Check if L1 RPC should use internal Erigon
*/}}
{{- define "adi-stack.useInternalL1" -}}
{{- .Values.erigon.enabled -}}
{{- end -}}

{{/*
Warn about L1 RPC configuration conflicts
*/}}
{{- define "adi-stack.warnL1RpcConflict" -}}
{{- if and .Values.erigon.enabled .Values.l1Rpc.fallback.enabled -}}
{{/* Dual-mode: Both Erigon and fallback are enabled - this is the expected new behavior */}}
{{- else if and .Values.erigon.enabled (or .Values.l1Rpc.url .Values.l1Rpc.existingSecret) -}}
WARNING: erigon.enabled=true overrides l1Rpc.url and l1Rpc.existingSecret.
         The external-node will use the internal Erigon node at:
         http://{{ include "adi-stack.fullname" . }}-erigon:{{ .Values.erigon.httpPort }}
         To use external RPC as fallback while Erigon syncs, set l1Rpc.fallback.enabled=true
{{- end -}}
{{- end -}}

{{/*
Common annotations
*/}}
{{- define "adi-stack.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Pod annotations for config/secret checksums
*/}}
{{- define "adi-stack.podAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- if and (not .Values.l1Rpc.existingSecret) (not .Values.erigon.enabled) }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end }}
{{- range $key, $value := .Values.podAnnotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
OpenShift container security context
Used for all containers when running on OpenShift
*/}}
{{- define "adi-stack.openshiftContainerSecurityContext" -}}
allowPrivilegeEscalation: false
runAsNonRoot: true
capabilities:
  drop:
    - ALL
{{- end -}}

{{/*
Image pull secrets (combining global and local)
*/}}
{{- define "adi-stack.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- range .Values.global.imagePullSecrets }}
{{- $pullSecrets = append $pullSecrets . }}
{{- end }}
{{- range .Values.imagePullSecrets }}
{{- $pullSecrets = append $pullSecrets . }}
{{- end }}
{{- if $pullSecrets }}
imagePullSecrets:
{{- range $pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}
