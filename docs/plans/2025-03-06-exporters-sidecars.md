# Add Exporters as Sidecars Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Prometheus exporters as sidecar containers to existing Kafka, PostgreSQL, and ArtemisMQ deployments, configure Prometheus to scrape them, and auto-provision Grafana dashboards.

**Architecture:** Add exporter containers as sidecars to existing service deployments (kafka/postgres/artemis), each exposing metrics on standard ports while connecting to their service via localhost within the same pod.

**Tech Stack:** Kubernetes manifests, Kustomize, Prometheus exporters, Grafana provisioning

---

## Task 1: Add Kafka Exporter Sidecar to Deployment

**Files:**
- Modify: `base/kafka/deployment.yaml`

**Step 1: Read current kafka deployment**

Read: `base/kafka/deployment.yaml`

**Step 2: Add kafka-exporter sidecar container**

Add this container to the `spec.template.spec.containers` array after the kafka container:

```yaml
        - name: kafka-exporter
          image: danielqsj/kafka-exporter:latest
          ports:
            - containerPort: 9308
          env:
            - name: KAFKA_BROKER
              value: "localhost:9092"
```

**Step 3: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid Kubernetes manifest with 2 containers in kafka pod

**Step 4: Commit**

```bash
git add base/kafka/deployment.yaml
git commit -m "feat: add kafka-exporter as sidecar to kafka deployment"
```

---

## Task 2: Add Kafka Exporter Port to Service

**Files:**
- Modify: `base/kafka/service.yaml`

**Step 1: Read current kafka service**

Read: `base/kafka/service.yaml`

**Step 2: Add exporter port**

Add to the `spec.ports` array:

```yaml
  - port: 9308
    targetPort: 9308
```

**Step 3: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid Service with 2 ports (9092 and 9308)

**Step 4: Commit**

```bash
git add base/kafka/service.yaml
git commit -m "feat: add kafka-exporter port to kafka service"
```

---

## Task 3: Add PostgreSQL Exporter Sidecar to Deployment

**Files:**
- Modify: `base/postgres/deployment.yaml`

**Step 1: Read current postgres deployment**

Read: `base/postgres/deployment.yaml`

**Step 2: Add postgres-exporter sidecar container**

Add this container to the `spec.template.spec.containers` array after the postgres container:

```yaml
        - name: postgres-exporter
          image: prometheuscommunity/postgres-exporter:latest
          ports:
            - containerPort: 9187
          env:
            - name: DATA_SOURCE_NAME
              value: "postgresql://postgres:postgres@localhost:5432/postgres?sslmode=disable"
```

**Step 3: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid Kubernetes manifest with 2 containers in postgres pod

**Step 4: Commit**

```bash
git add base/postgres/deployment.yaml
git commit -m "feat: add postgres-exporter as sidecar to postgres deployment"
```

---

## Task 4: Add PostgreSQL Exporter Port to Service

**Files:**
- Modify: `base/postgres/service.yaml`

**Step 1: Read current postgres service**

Read: `base/postgres/service.yaml`

**Step 2: Add exporter port**

Add to the `spec.ports` array:

```yaml
  - port: 9187
    targetPort: 9187
```

**Step 3: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid Service with 2 ports (5432 and 9187)

**Step 4: Commit**

```bash
git add base/postgres/service.yaml
git commit -m "feat: add postgres-exporter port to postgres service"
```

---

## Task 5: Create Artemis Exporter JMX Config

**Files:**
- Create: `base/artemis/exporter-configmap.yaml`

**Step 1: Write artemis jmx exporter config**

File: `base/artemis/exporter-configmap.yaml`

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
git add base/artemis/exporter-configmap.yaml
git commit -m "feat: add artemis jmx exporter config"
```

---

## Task 6: Add Artemis Exporter Sidecar to Deployment

**Files:**
- Modify: `base/artemis/deployment.yaml`

**Step 1: Read current artemis deployment**

Read: `base/artemis/deployment.yaml`

**Step 2: Add artemis-exporter sidecar container**

Add this container to the `spec.template.spec.containers` array after the artemis container:

```yaml
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
```

**Step 3: Add configmap volume to deployment**

Add to the `spec.template.spec.volumes` array:

```yaml
        - name: jmx-config
          configMap:
            name: artemis-jmx-config
```

**Step 4: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid Kubernetes manifest with 2 containers in artemis pod

**Step 5: Commit**

```bash
git add base/artemis/deployment.yaml
git commit -m "feat: add artemis-exporter as sidecar to artemis deployment"
```

---

## Task 7: Add Artemis Exporter Port to Service

**Files:**
- Modify: `base/artemis/service.yaml`

**Step 1: Read current artemis service**

Read: `base/artemis/service.yaml`

**Step 2: Add exporter port**

Add to the `spec.ports` array:

```yaml
  - port: 9404
    targetPort: 9404
```

**Step 3: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid Service with 3 ports (8161, 61616, 9404)

**Step 4: Commit**

```bash
git add base/artemis/service.yaml
git commit -m "feat: add artemis-exporter port to artemis service"
```

---

## Task 8: Update Prometheus Config for Exporters

**Files:**
- Modify: `base/prometheus/configmap.yaml`

**Step 1: Read current prometheus config**

Read: `base/prometheus/configmap.yaml`

**Step 2: Add exporter scrape configs**

Add these jobs to the `scrape_configs` section:

```yaml
- job_name: 'kafka-exporter'
  static_configs:
    - targets: ['kafka:9308']
- job_name: 'postgres-exporter'
  static_configs:
    - targets: ['postgres:9187']
- job_name: 'artemis-exporter'
  static_configs:
    - targets: ['artemis:9404']
```

**Step 3: Verify YAML structure**

Run: `kubectl apply -k base/ --dry-run=client`
Expected: Valid ConfigMap with new scrape jobs

**Step 4: Commit**

```bash
git add base/prometheus/configmap.yaml
git commit -m "feat: configure prometheus to scrape exporter sidecars"
```

---

## Task 9: Create Grafana Dashboards Directory

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

## Task 10: Create Kafka Dashboard

**Files:**
- Create: `base/grafana/dashboards/kafka.json`

**Step 1: Fetch Kafka dashboard from Grafana.com**

```bash
curl -o base/grafana/dashboards/kafka.json https://grafana.com/api/dashboards/7589/revisions/1/download
```

**Step 2: Commit**

```bash
git add base/grafana/dashboards/kafka.json
git commit -m "feat: add kafka dashboard from grafana.com"
```

---

## Task 11: Create PostgreSQL Dashboard

**Files:**
- Create: `base/grafana/dashboards/postgres.json`

**Step 1: Fetch PostgreSQL dashboard from Grafana.com**

```bash
curl -o base/grafana/dashboards/postgres.json https://grafana.com/api/dashboards/9628/revisions/1/download
```

**Step 2: Commit**

```bash
git add base/grafana/dashboards/postgres.json
git commit -m "feat: add postgres dashboard from grafana.com"
```

---

## Task 12: Create Artemis Dashboard

**Files:**
- Create: `base/grafana/dashboards/artemis.json`

**Step 1: Write artemis dashboard**

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

## Task 13: Update Grafana Config for Dashboard Provisioning

**Files:**
- Modify: `base/grafana/configmap.yaml`

**Step 1: Read current grafana config**

Read: `base/grafana/configmap.yaml`

**Step 2: Add dashboard provisioning**

Add a new file in the configmap data section:

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

**Step 5: Update kustomization**

File: `base/kustomization.yaml`

Add to resources list:

```yaml
  - grafana/dashboards-configmap.yaml
  - artemis/exporter-configmap.yaml
```

**Step 6: Commit**

```bash
git add base/grafana/configmap.yaml base/grafana/deployment.yaml base/grafana/dashboards-configmap.yaml base/kustomization.yaml
git commit -m "feat: configure grafana dashboard provisioning"
```

---

## Task 14: Update README with Exporter Information

**Files:**
- Modify: `README.md`

**Step 1: Read current README**

Read: `README.md`

**Step 2: Add exporters to services table**

Update the Services table to include exporters:

```markdown
| kafka-exporter | 9308 | danielqsj/kafka-exporter:latest (sidecar) |
| postgres-exporter | 9187 | prometheuscommunity/postgres-exporter:latest (sidecar) |
| artemis-exporter | 9404 | quay.io/brancz/jmx-exporter:latest (sidecar) |
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

## Task 15: Clean Up Separate Exporter Resources

**Files:**
- Delete: `base/kafka-exporter/`
- Delete: `base/postgres-exporter/`
- Modify: `base/kustomization.yaml`

**Step 1: Remove separate exporter directories**

```bash
rm -rf base/kafka-exporter/
rm -rf base/postgres-exporter/
```

**Step 2: Update kustomization**

File: `base/kustomization.yaml`

Remove these lines from resources list (if present):

```yaml
  - kafka-exporter/deployment.yaml
  - kafka-exporter/service.yaml
  - postgres-exporter/deployment.yaml
  - postgres-exporter/service.yaml
```

**Step 3: Commit**

```bash
git add base/kafka-exporter/ base/postgres-exporter/ base/kustomization.yaml
git commit -m "refactor: remove separate exporter deployments, using sidecars instead"
```

---

## Task 16: Verify Deployment

**Files:**
- N/A

**Step 1: Deploy bundle**

```bash
kubectl apply -k base/
```

**Step 2: Wait for all pods to be ready**

```bash
kubectl wait --for=condition=ready pod -l app=kafka --timeout=120s
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=artemis --timeout=120s
```

**Step 3: Check pods are running**

```bash
kubectl get pods
```

Expected: Each pod shows 2/2 containers running

**Step 4: Check services**

```bash
kubectl get svc
```

Expected: Services show exporter ports (kafka:9092,9308 | postgres:5432,9187 | artemis:8161,61616,9404)

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

All exporters run as sidecars in existing pods:
- kafka-exporter: http://kafka:9308/metrics (in kafka pod)
- postgres-exporter: http://postgres:9187/metrics (in postgres pod)
- artemis-exporter: http://artemis:9404/metrics (in artemis pod)

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
- 3 Prometheus exporters as sidecars (Kafka, PostgreSQL, Artemis)
- 3 pre-configured Grafana dashboards
- Updated Prometheus scrape configuration
- Automatic dashboard provisioning
- Cleaner architecture with no additional pods

Total: 16 tasks, approximately 2-3 hours to complete.
