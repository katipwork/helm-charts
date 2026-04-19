# Common Helm Library Chart

Helm library chart สำหรับ deploy container-based applications บน Kubernetes ใช้เป็น dependency ร่วมกันของทุก app chart เพื่อลด boilerplate และให้ทุก service มี standard เดียวกัน

## Requirements

- Helm 3.x
- Kubernetes 1.18+

## Installation

เพิ่ม dependency ใน `Chart.yaml` ของ app chart:

```yaml
dependencies:
  - name: common
    version: "0.1.0"
    repository: "https://your-org.github.io/helm-charts"
```

จากนั้นรัน:

```bash
helm dependency update ./your-app
```

---

## Usage

App chart แต่ละตัวสร้าง template file ที่ include named template จาก common chart:

**`templates/deployment.yaml`**
```yaml
{{ include "common.deployment" . }}
```

**`templates/service.yaml`**
```yaml
{{ include "common.service" . }}
```

**`templates/ingress.yaml`**
```yaml
{{ include "common.ingress" . }}
---
{{ include "common.httproute" . }}
```

**`templates/configmap.yaml`**
```yaml
{{ include "common.configmap" . }}
```

**`templates/secret.yaml`**
```yaml
{{ include "common.secret" . }}
```

**`templates/externalsecret.yaml`**
```yaml
{{ include "common.externalsecret" . }}
```

สำหรับ StatefulSet ให้ใช้แทน Deployment และเพิ่ม headless service:

**`templates/statefulset.yaml`**
```yaml
{{ include "common.statefulset" . }}
```

**`templates/service.yaml`**
```yaml
{{ include "common.service" . }}
---
{{ include "common.service.headless" . }}
```

---

## Values Reference

### Image

```yaml
image:
  repository: myregistry/myapp  # required
  tag: "1.0.0"                  # default: Chart.AppVersion
  pullPolicy: IfNotPresent       # default: IfNotPresent
```

### Deployment

```yaml
replicaCount: 1

nameOverride: ""
fullnameOverride: ""

podAnnotations: {}

# Environment variables
env:
  - name: APP_ENV
    value: production

# Environment variables จาก ConfigMap หรือ Secret
envFrom:
  - configMapRef:
      name: my-app
  - secretRef:
      name: my-app

# Entrypoint override
command: []
args: []

# Resource limits
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# Health checks
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

# Scheduling
nodeSelector: {}
tolerations: []
affinity: {}

# Volumes (freeform)
volumes: []
volumeMounts: []

# Init containers (freeform)
initContainers: []

# Image pull secrets
imagePullSecrets: []
```

### StatefulSet

ใช้ values เดียวกับ Deployment และเพิ่ม:

```yaml
statefulset:
  updateStrategy:
    type: RollingUpdate       # RollingUpdate | OnDelete
  podManagementPolicy: OrderedReady  # OrderedReady | Parallel

  volumeClaimTemplates:
    - name: data
      mountPath: /var/lib/data
      storage: 10Gi
      storageClassName: fast-ssd
      accessModes:
        - ReadWriteOnce
```

### Service

```yaml
service:
  type: ClusterIP             # ClusterIP | NodePort | LoadBalancer
  port: 8080
  annotations: {}
  nodePort: 30080             # ใช้เฉพาะตอน type: NodePort

  # Ports เพิ่มเติม
  extraPorts:
    - name: grpc
      port: 9090
      targetPort: grpc
    - name: metrics
      port: 9091
```

### Ingress

```yaml
ingress:
  enabled: false
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod

  # Simple — host เดียว
  host: myapp.example.com
  path: /
  pathType: Prefix

  # Complex — หลาย host หลาย path (ใช้แทน host/path ด้านบน)
  rules:
    - host: myapp.example.com
      paths:
        - path: /api
          pathType: Prefix
        - path: /health
          pathType: Exact

  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls
```

### HTTPRoute (Gateway API)

```yaml
httpRoute:
  enabled: false
  annotations: {}

  parentRefs:
    - name: main-gateway
      namespace: gateway
      sectionName: https

  hostnames:
    - myapp.example.com

  # Simple — ไม่ต้องกำหนด rules จะ default PathPrefix /

  # Complex — กำหนด rules เอง
  rules:
    - matches:
        - path: /api
          pathType: PathPrefix
```

> **หมายเหตุ:** `ingress` และ `httpRoute` ใช้พร้อมกันได้ ควบคุมด้วย `enabled` ของแต่ละอัน

### ConfigMap

```yaml
configMap:
  enabled: false
  annotations: {}

  # Key-value สำหรับใช้เป็น env
  data:
    APP_ENV: production
    LOG_LEVEL: info

  # File content สำหรับ mount เป็นไฟล์
  files:
    app.yaml: |
      server:
        port: 8080
```

เมื่อ `configMap.enabled: true` จะมี checksum annotation ใน Pod อัตโนมัติ ทำให้ rolling restart เมื่อ ConfigMap เปลี่ยน

### Secret

> ⚠️ ไม่ควรเก็บ secret จริงใน `values.yaml` ควรใช้ร่วมกับ Helm Secrets plugin หรือใช้ ExternalSecret แทน

```yaml
secret:
  enabled: false
  type: Opaque    # Opaque | kubernetes.io/tls | kubernetes.io/dockerconfigjson

  # data — ใส่ plaintext ได้เลย chart จะ base64 encode ให้อัตโนมัติ
  data:
    DB_PASSWORD: mysecretpassword
    API_KEY: abc123

  # stringData — Kubernetes จัดการ encode เอง
  stringData:
    config.json: |
      {"apiKey": "abc123"}
```

### ExternalSecret

```yaml
externalSecret:
  enabled: false
  refreshInterval: 1h

  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore   # ClusterSecretStore | SecretStore

  target:
    name: ""                   # default: ใช้ fullname ของ chart
    creationPolicy: Owner

    # Template สำหรับ transform secret ก่อน sync (optional)
    template:
      type: Opaque
      data:
        CONNECTION_STRING: "postgresql://{{ .username }}:{{ .password }}@postgres:5432/db"

  # dataFrom — ดึงทั้ง path มาเลย
  dataFrom:
    - key: myapp/production

  # data — เลือก map ทีละ key (ใช้แทน dataFrom)
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: myapp/production
        property: db_password
```

---

## Examples

### Basic Web Application

```yaml
# values.yaml
image:
  repository: myregistry/myapp
  tag: v1.0.0

service:
  port: 8080

ingress:
  enabled: true
  className: nginx
  host: myapp.example.com
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  httpGet:
    path: /health
    port: http

readinessProbe:
  httpGet:
    path: /ready
    port: http
```

### Application with ExternalSecret

```yaml
image:
  repository: myregistry/myapp
  tag: v1.0.0

externalSecret:
  enabled: true
  secretStoreRef:
    name: vault-backend
  dataFrom:
    - key: myapp/production

# Mount secret เป็น env
envFrom:
  - secretRef:
      name: my-app   # ชื่อเดียวกับ fullname หรือ externalSecret.target.name
```

### Application with ConfigMap as File

```yaml
image:
  repository: myregistry/myapp
  tag: v1.0.0

configMap:
  enabled: true
  files:
    app.yaml: |
      server:
        port: 8080
        timeout: 30s

volumes:
  - name: config
    configMap:
      name: my-app

volumeMounts:
  - name: config
    mountPath: /etc/config
    readOnly: true
```

### Application with Init Container

```yaml
image:
  repository: myregistry/myapp
  tag: v1.0.0

initContainers:
  - name: migrate
    image: myregistry/myapp:v1.0.0
    command: ["./migrate"]
    env:
      - name: DB_URL
        valueFrom:
          secretKeyRef:
            name: my-app
            key: DB_URL

externalSecret:
  enabled: true
  secretStoreRef:
    name: vault-backend
  dataFrom:
    - key: myapp/production
```

### StatefulSet with Persistent Storage

```yaml
image:
  repository: myregistry/myapp
  tag: v1.0.0

service:
  port: 8080

statefulset:
  updateStrategy:
    type: RollingUpdate
  podManagementPolicy: OrderedReady
  volumeClaimTemplates:
    - name: data
      mountPath: /var/lib/data
      storage: 10Gi
      storageClassName: fast-ssd
      accessModes:
        - ReadWriteOnce
```

---

## Named Templates Reference

| Template | Description |
|---|---|
| `common.name` | Chart name (ใช้ `nameOverride` ถ้ามี) |
| `common.fullname` | Release name + chart name (ใช้ `fullnameOverride` ถ้ามี) |
| `common.labels` | Standard Kubernetes labels |
| `common.selectorLabels` | Selector labels สำหรับ Deployment/StatefulSet |
| `common.image` | Image string (`repository:tag`) |
| `common.initContainers` | Init containers block |
| `common.deployment` | Deployment manifest |
| `common.statefulset` | StatefulSet manifest |
| `common.service` | ClusterIP/NodePort/LoadBalancer Service |
| `common.service.headless` | Headless Service สำหรับ StatefulSet |
| `common.ingress` | Ingress manifest |
| `common.httproute` | HTTPRoute manifest (Gateway API) |
| `common.configmap` | ConfigMap manifest |
| `common.configmap.checksum` | Checksum annotation สำหรับ force restart |
| `common.secret` | Secret manifest |
| `common.secret.checksum` | Checksum annotation สำหรับ force restart |
| `common.externalsecret` | ExternalSecret manifest |