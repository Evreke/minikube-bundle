# Design: Add Exporters and Dashboards to Minikube Bundle

**Date:** 2025-03-06

## Overview

Enhance the minikube bundle with Prometheus exporters and Grafana dashboards for Kafka, PostgreSQL, and ArtemisMQ to improve observability.

## Objectives

- Remove unused Zookeeper resources
- Add Prometheus exporters for all data services
- Pre-configure Grafana dashboards for each service
- Maintain existing functionality and configuration

## Architecture

### Cleanup

- Delete `base/zookeeper/` directory (not needed with KRaft mode)

### New Components

#### Kafka Exporter
- **Location:** `base/kafka-exporter/`
- **Image:** `danielqsj/kafka-exporter:latest`
- **Port:** 9308
- **Purpose:** Monitors Kafka topics, consumer groups, broker health
- **Connection:** Connects to Kafka service on port 9092

#### PostgreSQL Exporter
- **Location:** `base/postgres-exporter/`
- **Image:** `prometheuscommunity/postgres-exporter:latest`
- **Port:** 9187
- **Purpose:** Monitors database connections, transactions, locks, performance
- **Connection:** Uses DATABASE_URL environment variable

#### Artemis Exporter
- **Location:** `base/artemis-exporter/`
- **Image:** `quay.io/brancz/kafka-rabbitmq-prometheus-discovery:latest`
- **Port:** 9404
- **Purpose:** Monitors queues, connections, message rates via JMX
- **Connection:** Connects to Artemis JMX port

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
├── kafka-exporter/
│   ├── deployment.yaml
│   └── service.yaml
├── postgres-exporter/
│   ├── deployment.yaml
│   └── service.yaml
├── artemis-exporter/
│   ├── deployment.yaml
│   └── service.yaml
├── grafana/
│   └── configmap.yaml (updated)
└── prometheus/
    └── configmap.yaml (updated)
```

### Configuration

- Exporters connect to services via Kubernetes DNS
- Use environment variables for connection parameters
- Services use ClusterIP for internal communication
- All metrics exposed on standard exporter ports

## Success Criteria

- All exporters running and exposing metrics on correct ports
- Prometheus successfully scraping all new targets
- Grafana dashboards auto-provisioned on startup
- Existing services unaffected
- Zookeeper removed successfully
