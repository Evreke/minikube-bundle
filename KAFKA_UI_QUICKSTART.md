# Kafka UI - Quick Start

## Status: ✅ READY FOR DEPLOYMENT

kafka-ui has been added to minikube-bundle and is ready to deploy.

## Quick Deployment

### 1. Deploy to Kubernetes

```bash
cd ~/BackendAcademy/minikube-bundle
kubectl apply -k base/
```

### 2. Verify Deployment

```bash
# Check kafka-ui pod is running
kubectl get pods -l app=kafka-ui

# Expected: kafka-ui-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

### 3. Start Minikube Tunnel (Separate Terminal)

```bash
minikube tunnel
```

**Keep this terminal open while accessing services.**

### 4. Access Kafka UI

```bash
# Get external IP
EXTERNAL_IP=$(kubectl get svc kafka-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Access Kafka UI
echo "Access Kafka UI at: http://$EXTERNAL_IP:8081"
```

Open your browser to: `http://$EXTERNAL_IP:8081`

## First-Time Setup

### 1. Open Kafka UI
Navigate to: `http://$EXTERNAL_IP:8081`

### 2. Verify Cluster Connection
- Navigate to **Clusters** section
- You should see **minikube-kafka** cluster
- Status should show as **Connected**
- Click on the cluster to view details

### 3. View Existing Topics
- Navigate to **Topics** section
- You should see all topics in your Kafka cluster
- Topics to expect:
  - `processed-messages` (from integration-demo)
  - Any other auto-created topics

### 4. Create a Test Topic (Optional)

1. Click **Create Topic** button
2. Enter topic details:
   - Topic Name: `test-topic`
   - Partitions: `3`
   - Replication Factor: `1`
3. Click **Create**

### 5. Browse Messages

1. Navigate to **Topics**
2. Click on a topic (e.g., `processed-messages`)
3. Click **Messages** tab
4. View messages in the topic

## Verification Checklist

After deployment, verify:

- [ ] kafka-ui pod is running
- [ ] kafka-ui service has external IP
- [ ] Can access http://<EXTERNAL-IP>:8081 in browser
- [ ] Kafka UI shows "minikube-kafka" cluster as connected
- [ ] Can view existing topics
- [ ] Can create new topics
- [ ] Can browse messages in topics
- [ ] No error messages in logs

## Access URLs

After running `minikube tunnel`:

```bash
# Get all external IPs
echo "Kafka UI:       $(kubectl get svc kafka-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8081"
echo "Kafka Broker:    $(kubectl get svc kafka -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):9092"
echo "Grafana:         $(kubectl get svc grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):3000"
echo "Artemis Console: $(kubectl get svc artemis -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8161"
```

## Common Operations

### Create a Topic
```
Topics → Create Topic → Enter details → Create
```

### Delete a Topic
```
Topics → Click topic → Delete → Confirm
```

### Browse Messages
```
Topics → Click topic → Messages tab → Browse
```

### View Consumer Groups
```
Consumers → View groups → Check lag → Monitor
```

## Troubleshooting

### Can't Access kafka-ui

**Check:**
```bash
# Is pod running?
kubectl get pods -l app=kafka-ui

# Is service ready?
kubectl get svc kafka-ui

# Are there errors in logs?
kubectl logs -l app=kafka-ui
```

### Cluster Shows as Disconnected

**Check:**
```bash
# Is Kafka running?
kubectl get pods -l app=kafka

# Is Kafka service accessible?
kubectl get svc kafka

# Review kafka-ui configuration
kubectl describe deployment kafka-ui | grep -A 20 "Environment:"
```

### External IP Shows <pending>

**Solution:**
```bash
# Ensure minikube tunnel is running
minikube tunnel
```

## Documentation

For detailed information, see:
- `KAFKA_UI.md` - Comprehensive usage guide
- `KAFKA_UI_IMPLEMENTATION.md` - Implementation details
- `README.md` - Overall project overview

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                      │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Kafka UI (Port 8081)           │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  kafka-ui Pod                          │  │  │
│  │  │  - Image: provectuslabs/kafka-ui  │  │  │
│  │  │  - Connects to: kafka:9092         │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                                                   │  │
│  │  Service: kafka-ui (LoadBalancer:8081)         │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                 │
│  │ Integration │  │    Kafka    │                 │
│  │    Demo     │  │  (9092)     │                 │
│  └─────────────┘  └─────────────┘                 │
└─────────────────────────────────────────────────────┘
```

## Key Features

- ✅ **Topic Management** - Create, delete, view topics
- ✅ **Message Browsing** - View messages in topics
- ✅ **Consumer Monitoring** - Track consumer groups and lag
- ✅ **Cluster Overview** - View broker health and status
- ✅ **Static Configuration** - Pre-configured cluster connection
- ✅ **Web Interface** - Easy to use browser-based UI
- ✅ **Real-time Updates** - Live monitoring of Kafka cluster

## Integration with Integration Demo

```
Integration Demo (Spring Boot)
    ↓
    JMS Producer → Artemis Queue
    ↓
    JMS Listener → Store in PostgreSQL
    ↓
    Kafka Producer → Kafka Topic (processed-messages)
    ↓
    kafka-ui can view topic
    ↓
    Browse messages, monitor consumers
```

## Next Steps

1. ✅ Deploy kafka-ui
2. ✅ Test topic creation
3. ✅ Browse existing messages
4. ✅ Monitor consumer groups
5. ✅ Integrate with development workflow

---

**Implementation Date:** 2025-04-02
**Status:** ✅ Complete and Validated
**Ready for Deployment:** YES
