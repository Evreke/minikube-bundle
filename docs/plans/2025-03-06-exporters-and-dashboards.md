# Add Exporters and Dashboards Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Prometheus exporters and Grafana dashboards for Kafka, PostgreSQL, and ArtemisMQ to improve observability in the minikube bundle.

**Architecture:** Deploy three new exporter services (kafka-exporter, postgres-exporter, artemis-exporter) as separate deployments, configure Prometheus to scrape their metrics, and auto-provision Grafana dashboards from community sources.

**Tech Stack:** Kubernetes manifests, Kustomize, Prometheus exporters, Grafana provisioning

---

## Task 1: Remove Zookeeper

**Files:**
- Delete: `base/zookeeper/deployment.yaml`
- Delete: `base/zookeeper/service.yaml`

**Step 1: Delete zookeeper directory and files**

```bash
rm -rf base/zookeeper/
```

**Step 2: Verify removal**

Run: `ls base/`
Expected: Zookeeper directory not listed

**Step 3: Update base kustomization**

File: `base/kustomization.yaml`

Remove these lines:
```yaml
- zookeeper/deployment.yaml
- zookeeper/service.yaml
```

**Step 4: Commit**

```bash
git add base/zookeeper/ base/kustomization.yaml
git commit -m "Remove unused zookeeper (not needed with KRaft mode)"
```

---

## Task 2: Create Kafka Exporter Deployment

**Files:**
- Create: `base/kafka-exporter/deployment.yaml`

**Step 1: Write kafka-exporter deployment**

File: `base/kafka-exporter/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka-exporter
  labels:
    app: kafka-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka-exporter
  template:
    metadata:
      labels:
        app: kafka-exporter
    spec:
      containers:
        - name: kafka-exporter
          image: danielqsj/kafka-exporter:latest
          ports:
            - containerPort: 9308
          env:
            - name: KAFKA_BROKER
              value: "kafka:9092"
```

**Step 2: Commit**

```bash
git add base/kafka-exporter/deployment.yaml
git commit -m "feat: add kafka-exporter deployment"
```

---

## Task 3: Create Kafka Exporter Service

**Files:**
- Create: `base/kafka-exporter/service.yaml`

**Step 1: Write kafka-exporter service**

File: `base/kafka-exporter/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-exporter
  labels:
    app: kafka-exporter
spec:
  type: ClusterIP
  selector:
    app: kafka-exporter
  ports:
    - port: 9308
      targetPort: 9308
```

**Step 2: Commit**

```bash
git add base/kafka-exporter/service.yaml
git commit -m "feat: add kafka-exporter service"
```

---

## Task 4: Add Kafka Exporter to Kustomization

**Files:**
- Modify: `base/kustomization.yaml`

**Step 1: Add kafka-exporter resources**

File: `base/kustomization.yaml`

Add these lines in the resources list:
```yaml
  - kafka-exporter/deployment.yaml
  - kafka-exporter/service.yaml
```

**Step 2: Commit**

```bash
git add base/kustomization.yaml
git commit -m "feat: add kafka-exporter to kustomization"
```

---

## Task 5: Create PostgreSQL Exporter Deployment

**Files:**
- Create: `base/postgres-exporter/deployment.yaml`

**Step 1: Write postgres-exporter deployment**

File: `base/postgres-exporter/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
  labels:
    app: postgres-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-exporter
  template:
    metadata:
      labels:
        app: postgres-exporter
    spec:
      containers:
        - name: postgres-exporter
          image: prometheuscommunity/postgres-exporter:latest
          ports:
            - containerPort: 9187
          env:
            - name: DATA_SOURCE_NAME
              value: "postgresql://postgres:postgres@postgres:5432/postgres?sslmode=disable"
```

**Step 2: Commit**

```bash
git add base/postgres-exporter/deployment.yaml
git commit -m "feat: add postgres-exporter deployment"
```

---

## Task 6: Create PostgreSQL Exporter Service

**Files:**
- Create: `base/postgres-exporter/service.yaml`

**Step 1: Write postgres-exporter service**

File: `base/postgres-exporter/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-exporter
  labels:
    app: postgres-exporter
spec:
  type: ClusterIP
  selector:
    app: postgres-exporter
  ports:
    - port: 9187
      targetPort: 9187
```

**Step 2: Commit**

```bash
git add base/postgres-exporter/service.yaml
git commit -m "feat: add postgres-exporter service"
```

---

## Task 7: Add PostgreSQL Exporter to Kustomization

**Files:**
- Modify: `base/kustomization.yaml`

**Step 1: Add postgres-exporter resources**

File: `base/kustomization.yaml`

Add these lines in the resources list:
```yaml
  - postgres-exporter/deployment.yaml
  - postgres-exporter/service.yaml
```

**Step 2: Commit**

```bash
git add base/kustomization.yaml
git commit -m "feat: add postgres-exporter to kustomization"
```

---

## Task 8: Create Artemis Exporter Deployment

**Files:**
- Create: `base/artemis-exporter/deployment.yaml`

**Step 1: Write artemis-exporter deployment**

File: `base/artemis-exporter/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: artemis-exporter
  labels:
    app: artemis-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: artemis-exporter
  template:
    metadata:
      labels:
        app: artemis-exporter
    spec:
      containers:
        - name: artemis-exporter
          image: quay.io/brancz/jmx-exporter:latest
          ports:
            - containerPort: 9404
          volumeMounts:
            - name: jmx-config
              mountPath: /config.yaml
              subPath: config.yaml
          args:
            - "/config.yaml"
      volumes:
        - name: jmx-config
          configMap:
            name: artemis-jmx-config
```

**Step 2: Commit**

```bash
git add base/artemis-exporter/deployment.yaml
git commit -m "feat: add artemis-exporter deployment"
```

---

## Task 9: Create Artemis JMX Config

**Files:**
- Create: `base/artemis-exporter/configmap.yaml`

**Step 1: Write artemis jmx config**

File: `base/artemis-exporter/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: artemis-jmx-config
data:
  config.yaml: |
    startDelaySeconds: 0
    hostPort: 9404
    rules:
      - pattern: 'org.apache.activemq.artemis<type=Broker>([^<]+)<>(CurrentDateFormat|CriticalAnalyzer|MessageCounterEnabled|MessageCounterMaxDayCount|MessageCounterSamplePeriod|Version)<>([^:]+)'
        name: artemis_broker_$3_$4
        type: GAUGE
      - pattern: 'org.apache.activemq.artemis<type=Broker, subType=([^>]+)><>([^:]+)'
        name: artemis_broker_$2
        type: GAUGE
      - pattern: 'org.apache.activemq.artemis<type=Queue, address=([^,]+), queue=([^>]+)><>(ConsumerCount|DeliveringCount|Durable|MessagesAcked|MessagesAdded|MessagesExpired|MessagesKilled|Paused|ScheduledCount|Temporary)<>([^:]+)'
        name: artemis_queue_$3_$4
        labels:
          address: $1
          queue: $2
        type: GAUGE
```

**Step 2: Commit**

```bash
git add base/artemis-exporter/configmap.yaml
git commit -m "feat: add artemis jmx exporter config"
```

---

## Task 10: Create Artemis Exporter Service

**Files:**
- Create: `base/artemis-exporter/service.yaml`

**Step 1: Write artemis-exporter service**

File: `base/artemis-exporter/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: artemis-exporter
  labels:
    app: artemis-exporter
spec:
  type: ClusterIP
  selector:
    app: artemis-exporter
  ports:
    - port: 9404
      targetPort: 9404
```

**Step 2: Commit**

```bash
git add base/artemis-exporter/service.yaml
git commit -m "feat: add artemis-exporter service"
```

---

## Task 11: Add Artemis Exporter to Kustomization

**Files:**
- Modify: `base/kustomization.yaml`

**Step 1: Add artemis-exporter resources**

File: `base/kustomization.yaml`

Add these lines in the resources list:
```yaml
  - artemis-exporter/configmap.yaml
  - artemis-exporter/deployment.yaml
  - artemis-exporter/service.yaml
```

**Step 2: Commit**

```bash
git add base/kustomization.yaml
git commit -m "feat: add artemis-exporter to kustomization"
```

---

## Task 12: Update Prometheus Config for Exporters

**Files:**
- Modify: `base/prometheus/configmap.yaml`

**Step 1: Read current prometheus config**

File: `base/prometheus/configmap.yaml`

Read the file to understand current structure.

**Step 2: Add exporter scrape configs**

Update the configmap to include these jobs in the scrape_configs section:

```yaml
- job_name: 'kafka-exporter'
  static_configs:
    - targets: ['kafka-exporter:9308']
- job_name: 'postgres-exporter'
  static_configs:
    - targets: ['postgres-exporter:9187']
- job_name: 'artemis-exporter'
  static_configs:
    - targets: ['artemis-exporter:9404']
```

**Step 3: Commit**

```bash
git add base/prometheus/configmap.yaml
git commit -m "feat: configure prometheus to scrape exporters"
```

---

## Task 13: Create Grafana Dashboards Directory

**Files:**
- Create: `base/grafana/dashboards/`

**Step 1: Create dashboards directory**

```bash
mkdir -p base/grafana/dashboards
```

**Step 2: Commit**

```bash
git add base/grafana/dashboards
git commit -m "feat: add grafana dashboards directory"
```

---

## Task 14: Create Kafka Dashboard

**Files:**
- Create: `base/grafana/dashboards/kafka.json`

**Step 1: Fetch Kafka dashboard from Grafana.com**

Use Grafana.com to get a Kafka dashboard. Recommended: ID 7589 "Kafka Exporter"

```bash
curl -o base/grafana/dashboards/kafka.json https://grafana.com/api/dashboards/7589/revisions/1/download
```

**Step 2: Commit**

```bash
git add base/grafana/dashboards/kafka.json
git commit -m "feat: add kafka dashboard from grafana.com"
```

---

## Task 15: Create PostgreSQL Dashboard

**Files:**
- Create: `base/grafana/dashboards/postgres.json`

**Step 1: Fetch PostgreSQL dashboard from Grafana.com**

Use Grafana.com to get a PostgreSQL dashboard. Recommended: ID 9628 "PostgreSQL Database"

```bash
curl -o base/grafana/dashboards/postgres.json https://grafana.com/api/dashboards/9628/revisions/1/download
```

**Step 2: Commit**

```bash
git add base/grafana/dashboards/postgres.json
git commit -m "feat: add postgres dashboard from grafana.com"
```

---

## Task 16: Create Artemis Dashboard

**Files:**
- Create: `base/grafana/dashboards/artemis.json`

**Step 1: Create custom Artemis dashboard**

File: `base/grafana/dashboards/artemis.json`

```json
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "values": false,
          "calcs": ["lastNotNull"],
          "fields": ""
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "7.5.7",
      "targets": [
        {
          "expr": "rate(artemis_queue_MessagesAdded_total[5m])",
          "refId": "A"
        }
      ],
      "title": "Message Rate",
      "type": "gauge"
    },
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "short"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "calcs": ["mean", "lastNotNull"],
          "displayMode": "table",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "pluginVersion": "7.5.7",
      "targets": [
        {
          "expr": "artemis_queue_ConsumerCount",
          "refId": "A"
        }
      ],
      "title": "Consumer Count",
      "type": "timeseries"
    }
  ],
  "schemaVersion": 27,
  "style": "dark",
  "tags": ["artemis", "jms"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "ArtemisMQ Overview",
  "uid": "artemis-overview",
  "version": 1
}
```

**Step 2: Commit**

```bash
git add base/grafana/dashboards/artemis.json
git commit -m "feat: add artemis dashboard"
```

---

## Task 17: Update Grafana Config for Dashboard Provisioning

**Files:**
- Modify: `base/grafana/configmap.yaml`

**Step 1: Read current grafana config**

File: `base/grafana/configmap.yaml`

Read the file to understand current structure.

**Step 2: Add dashboard provisioning**

Update the configmap to include dashboard provisioning. Add a new file in the configmap data section:

```yaml
  dashboards.yaml: |
    apiVersion: 1
    providers:
      - name: 'Default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        updateIntervalSeconds: 10
        allowUiUpdates: true
        options:
          path: /etc/grafana/provisioning/dashboards
```

**Step 3: Add volume mount for dashboards to grafana deployment**

File: `base/grafana/deployment.yaml`

Add to volumes:
```yaml
        - name: dashboards
          configMap:
            name: grafana-dashboards
```

Add to container volumeMounts:
```yaml
          - name: dashboards
            mountPath: /etc/grafana/provisioning/dashboards
```

**Step 4: Create dashboards configmap**

File: `base/grafana/dashboards-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
data:
  kafka.json: |
{{ .Files.Get "dashboards/kafka.json" | indent 4 }}
  postgres.json: |
{{ .Files.Get "dashboards/postgres.json" | indent 4 }}
  artemis.json: |
{{ .Files.Get "dashboards/artemis.json" | indent 4 }}
```

**Step 5: Commit**

```bash
git add base/grafana/configmap.yaml base/grafana/deployment.yaml base/grafana/dashboards-configmap.yaml
git commit -m "feat: configure grafana dashboard provisioning"
```

---

## Task 18: Update Kustomization for Grafana Dashboards

**Files:**
- Modify: `base/kustomization.yaml`

**Step 1: Add grafana dashboards resources**

File: `base/kustomization.yaml`

Add these lines in the resources list:
```yaml
  - grafana/dashboards-configmap.yaml
```

**Step 2: Commit**

```bash
git add base/kustomization.yaml
git commit -m "feat: add grafana dashboards configmap to kustomization"
```

---

## Task 19: Update README with Exporter Information

**Files:**
- Modify: `README.md`

**Step 1: Read current README**

File: `README.md`

Read to understand current structure.

**Step 2: Add exporter information to services table**

Add exporters to the Services table:

```markdown
| kafka-exporter | 9308 | danielqsj/kafka-exporter:latest |
| postgres-exporter | 9187 | prometheuscommunity/postgres-exporter:latest |
| artemis-exporter | 9404 | quay.io/brancz/jmx-exporter:latest |
```

**Step 3: Add dashboards section**

After "Configuration" section, add:

```markdown
## Dashboards

Grafana comes pre-configured with dashboards for:

- **Kafka**: Shows broker, topic, and consumer group metrics
- **PostgreSQL**: Database connections, queries, locks, performance
- **ArtemisMQ**: Queue metrics, message rates, consumer statistics

Dashboards are auto-provisioned from `base/grafana/dashboards/`.
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add exporter and dashboard information to README"
```

---

## Task 20: Verify Deployment

**Files:**
- N/A

**Step 1: Deploy bundle**

```bash
kubectl apply -k base/
```

**Step 2: Wait for all pods to be ready**

```bash
kubectl wait --for=condition=ready pod -l app=kafka-exporter --timeout=60s
kubectl wait --for=condition=ready pod -l app=postgres-exporter --timeout=60s
kubectl wait --for=condition=ready pod -l app=artemis-exporter --timeout=60s
```

**Step 3: Check pods are running**

```bash
kubectl get pods
```

Expected: kafka-exporter, postgres-exporter, artemis-exporter pods are running

**Step 4: Check services**

```bash
kubectl get svc
```

Expected: kafka-exporter, postgres-exporter, artemis-exporter services exist

**Step 5: Verify Prometheus targets**

```bash
kubectl port-forward svc/prometheus 9090:9090
```

Visit http://localhost:9090/targets
Expected: kafka-exporter, postgres-exporter, artemis-exporter in UP state

**Step 6: Verify Grafana dashboards**

```bash
kubectl port-forward svc/grafana 3000:3000
```

Visit http://localhost:3000, login with admin/admin
Expected: Kafka, PostgreSQL, Artemis dashboards are visible and show data

**Step 7: Commit verification notes**

```bash
cat > docs/deployment-verification.md << 'EOF'
# Deployment Verification

## Exporters

All exporters should be running and exposing metrics:
- kafka-exporter: http://kafka-exporter:9308/metrics
- postgres-exporter: http://postgres-exporter:9187/metrics
- artemis-exporter: http://artemis-exporter:9404/metrics

## Prometheus Targets

Check http://localhost:9090/targets after port-forward:
- kafka-exporter should be UP
- postgres-exporter should be UP
- artemis-exporter should be UP

## Grafana Dashboards

Login to http://localhost:3000 (admin/admin):
- "Kafka Exporter" dashboard should be available
- "PostgreSQL Database" dashboard should be available
- "ArtemisMQ Overview" dashboard should be available
- All dashboards should show data
EOF
git add docs/deployment-verification.md
git commit -m "docs: add deployment verification notes"
```

---

## Summary

This implementation plan adds comprehensive observability to the minikube bundle through:
- 3 Prometheus exporters (Kafka, PostgreSQL, Artemis)
- 3 pre-configured Grafana dashboards
- Updated Prometheus scrape configuration
- Automatic dashboard provisioning
- Clean removal of unused Zookeeper

Total: 20 tasks, approximately 2-3 hours to complete.
