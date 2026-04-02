# Minikube Bundle

Kubernetes bundle for local development with observability stack and message brokers.

## Services

| Service | Port | Image |
|---------|------|-------|
| PostgreSQL | 5432 | postgres:16 |
| Prometheus | 9090 | prom/prometheus:latest |
| Grafana | 3000 | grafana/grafana:latest |
| Loki | 3100 | grafana/loki:3.2.0 |
| Kafka (KRaft) | 9092 | apache/kafka:latest |
| ArtemisMQ | 8161 (console), 61616 (AMQP) | apache/activemq-artemis:latest |
| kafka-ui | 8081 | provectuslabs/kafka-ui:latest |
| template-service | 8080 | nginx:alpine |

## Quick Start

### Prerequisites
- minikube installed
- kubectl installed
- Docker or container runtime

### Deploy

```bash
# Start minikube
minikube start

# Deploy all services
kubectl apply -k minikube-bundle/base/

# Start tunnel (separate terminal)
minikube tunnel

# Check services and external IPs
kubectl get svc
```

### Access Services

After running `minikube tunnel`, services are accessible at:
- PostgreSQL: `<EXTERNAL-IP>:5432`
- Prometheus: `<EXTERNAL-IP>:9090`
- Grafana: `<EXTERNAL-IP>:3000` (admin/admin)
- Loki: `<EXTERNAL-IP>:3100`
- Kafka: `<EXTERNAL-IP>:9092`
- ArtemisMQ Console: `<EXTERNAL-IP>:8161` (artemis/artemis)
- ArtemisMQ AMQP: `<EXTERNAL-IP>:61616`
- kafka-ui: `<EXTERNAL-IP>:8081`
- template-service: `<EXTERNAL-IP>:8080`

### Kafka UI

kafka-ui provides a web-based interface for managing Kafka clusters:

```bash
# Access Kafka UI
EXTERNAL_IP=$(kubectl get svc kafka-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
open http://$EXTERNAL_IP:8081
```

**Features:**
- View and manage Kafka topics
- Browse messages in topics
- Monitor consumer groups and lag
- Create and delete topics dynamically
- View broker and cluster information

**Configuration:**
- Pre-configured to connect to `kafka:9092`
- Static configuration via environment variables
- No authentication required for local development

For detailed usage, see [KAFKA_UI.md](KAFKA_UI.md)

## Project Structure

```
minikube-bundle/
├── base/                    # Base manifests
│   ├── kustomization.yaml
│   ├── postgres/
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   ├── kafka/
│   ├── kafka-ui/
│   ├── artemis/
│   └── template-service/
└── overlays/                # Environment overlays
    └── minikube/
```

## Configuration

### PostgreSQL
- Password: `postgres`
- Database: `postgres`

### Grafana
- Username: `admin`
- Password: `admin`

### ArtemisMQ
- Username: `artemis`
- Password: `artemis`

## Using with Overlay

```bash
kubectl apply -k minikube-bundle/overlays/minikube/
```

## Dashboards

Grafana comes pre-configured with dashboards for:

- **Kafka**: Shows broker, topic, and consumer group metrics
- **PostgreSQL**: Database connections, queries, locks, performance
- **ArtemisMQ**: Queue metrics, message rates, consumer statistics

Dashboards are auto-provisioned from `base/grafana/dashboards/`.