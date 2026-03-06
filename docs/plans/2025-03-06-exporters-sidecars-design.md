# Design: Add Exporters as Sidecars

**Date:** 2025-03-06

## Overview

Enhance the minikube bundle with Prometheus exporters added as sidecar containers to existing deployments (Kafka, PostgreSQL, ArtemisMQ) to improve observability with simpler architecture.

## Objectives

- Add Prometheus exporters for all data services as sidecars
- Pre-configure Grafana dashboards for each service
- Maintain existing functionality and configuration
- Simplify architecture by reducing pod count

## Architecture

### Sidecar Pattern

Each service deployment will contain 2 containers:
1. **Main service container** (kafka/postgres/artemis)
2. **Exporter container** (connects to localhost, exposes metrics on its own port)

### Components

**Kafka Deployment (`base/kafka/deployment.yaml`)**
- Add `kafka-exporter` sidecar container
- Image: `danielqsj/kafka-exporter:latest`
- Port: 9308 (exposed)
- Connection: `localhost:9092` (to Kafka container in same pod)
- Env: `KAFKA_BROKER=localhost:9092`
- Service update: Add port 9308 to `base/kafka/service.yaml`

**PostgreSQL Deployment (`base/postgres/deployment.yaml`)**
- Add `postgres-exporter` sidecar container
- Image: `prometheuscommunity/postgres-exporter:latest`
- Port: 9187 (exposed)
- Connection: `localhost:5432` (to PostgreSQL container in same pod)
- Env: `DATA_SOURCE_NAME=postgresql://postgres:postgres@localhost:5432/postgres?sslmode=disable`
- Service update: Add port 9187 to `base/postgres/service.yaml`

**ArtemisMQ Deployment (`base/artemis/deployment.yaml`)**
- Add `artemis-exporter` sidecar container
- Image: `quay.io/brancz/jmx-exporter:latest`
- Port: 9404 (exposed)
- Connection: JMX to Artemis container in same pod
- Requires: JMX config via ConfigMap (`base/artemis/exporter-configmap.yaml`)
- Service update: Add port 9404 to `base/artemis/service.yaml`

### Grafana Dashboard Provisioning

- Update `base/grafana/configmap.yaml`
- Add dashboard provisioning configuration
- Source dashboards from Grafana.com community
- Dashboards auto-load on Grafana startup

### Prometheus Configuration

- Update `base/prometheus/configmap.yaml`
- Add scrape targets for new exporters
- Configure appropriate scrape intervals

## Implementation Details

### Directory Structure

```
base/
├── kafka/
│   ├── deployment.yaml (modified - add sidecar)
│   └── service.yaml (modified - add exporter port)
├── postgres/
│   ├── deployment.yaml (modified - add sidecar)
│   └── service.yaml (modified - add exporter port)
├── artemis/
│   ├── deployment.yaml (modified - add sidecar)
│   ├── service.yaml (modified - add exporter port)
│   └── exporter-configmap.yaml (new)
├── grafana/
│   ├── configmap.yaml (modified - add dashboard provisioning)
│   ├── dashboards/ (new directory)
│   │   ├── kafka.json
│   │   ├── postgres.json
│   │   └── artemis.json
│   └── dashboards-configmap.yaml (new)
└── prometheus/
    └── configmap.yaml (modified - add exporter scrape targets)
```

### Configuration

- Exporters connect to services via localhost within same pod
- Services expose both main port and exporter port
- Prometheus scrapes using `<service-name>:<exporter-port>` via Kubernetes DNS
- All metrics exposed on standard exporter ports (9308, 9187, 9404)

## Success Criteria

- All exporters running as sidecars in existing pods
- Prometheus successfully scraping all new targets
- Grafana dashboards auto-provisioned on startup
- Existing services unaffected
- Total pods: 6 (was 6) - no increase in pod count
