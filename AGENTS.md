# AGENTS.md

This repository contains Kubernetes manifests managed with Kustomize for deploying observability and messaging infrastructure.

## Build/Validation Commands

```bash
# Validate manifests without applying (dry run)
kubectl apply --dry-run=client -k base/
kubectl apply --dry-run=client -k overlays/minikube/

# View what will be deployed
kubectl get -k base/

# Apply to cluster
kubectl apply -k base/

# Delete all resources
kubectl delete -k base/

# Check service status and external IPs
kubectl get svc
```

## Project Structure

```
base/                 # Base Kustomize resources
├── kustomization.yaml
├── postgres/
├── prometheus/
├── grafana/
│   └── dashboards/   # JSON dashboard definitions
├── loki/
├── kafka/
├── artemis/
└── template-service/
overlays/             # Environment-specific overrides
└── minikube/
```

## Code Style Guidelines

### File Naming
- Use lowercase with hyphens for directories: `postgres/`, `grafana/dashboards/`
- Manifest files: `deployment.yaml`, `service.yaml`, `configmap.yaml`
- Service-specific configs: `{service}-{purpose}.yaml` (e.g., `exporter-configmap.yaml`)

### YAML Structure

**Deployments:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <service-name>
  labels:
    app: <service-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <service-name>
  template:
    metadata:
      labels:
        app: <service-name>
```

**Services:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <service-name>
spec:
  type: LoadBalancer
  selector:
    app: <service-name>
  ports:
    - name: <purpose>    # e.g., db, exporter, web
      port: <port>
      targetPort: <port>
```

### Labeling Conventions
- Consistent `app: <service-name>` label across deployment, pods, and services
- Use descriptive port names in services: `db`, `exporter`, `web`, `amqp`

### ConfigMaps
- Use dash-separated keys for config files: `prometheus.yml`, `datasources.yml`
- Embed multi-line config with `|` operator
- Reference ConfigMaps in volumes: `configMap.name: <configmap-name>`

### Exporters as Sidecars
- Exporters run as sidecar containers in main service pods
- Exporter container names: `<service>-exporter`
- Default exporter ports: postgres=9187, kafka=9308, artemis=9404
- Exporter listens on localhost, accessed via pod name in Prometheus

### Environment Variables
- Use `name: value` for simple values
- Prefer uppercase with underscores: `POSTGRES_PASSWORD`, `KAFKA_BROKER`

### Image Tags
- Use specific tags where available: `postgres:16`, `grafana/loki:3.2.0`
- Use `latest` for frequently updated images: `prom/prometheus:latest`

### Kustomization
- List all resources in base/kustomization.yaml in logical order
- Use `configMapGenerator` with `behavior: replace` for dashboards
- Maintain alphabetical order where appropriate

## Adding New Services

1. Create directory in `base/`: `base/new-service/`
2. Add `deployment.yaml` with consistent labels
3. Add `service.yaml` with LoadBalancer type
4. If config needed: add `configmap.yaml` with embedded config
5. If metrics needed: add exporter sidecar container
6. Update `base/kustomization.yaml` with new resources

## Metrics Integration

- All exporters port 9xxx standard: postgres=9187, kafka=9308, artemis=9404
- Configure scrape jobs in `prometheus/configmap.yaml`
- Targets use service names: `postgres:9187`, `kafka:9308`

## Dashboards

- Place JSON dashboards in `base/grafana/dashboards/`
- Add to `configMapGenerator` in `base/kustomization.yaml`
- Name format: `<service>.json`
