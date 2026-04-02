# Kafka UI Integration

## Overview
Added provectuslabs/kafka-ui to minikube-bundle for web-based Kafka management.

## Quick Start

### 1. Deploy kafka-ui
```bash
cd ~/BackendAcademy/minikube-bundle
kubectl apply -k base/
```

### 2. Access kafka-ui
```bash
# Start minikube tunnel (if not already running)
minikube tunnel

# Get external IP
EXTERNAL_IP=$(kubectl get svc kafka-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Access Kafka UI
echo "Access Kafka UI at: http://$EXTERNAL_IP:8081"
```

### 3. Configure Kafka Cluster (First Time)
1. Open Kafka UI in browser: `http://$EXTERNAL_IP:8081`
2. Navigate to **Clusters** section
3. You should see **minikube-kafka** cluster already configured
4. Click on the cluster to view topics, brokers, etc.

## Features

### Topic Management
- **View Topics**: List all topics in the cluster
- **Create Topics**: Create new topics dynamically
- **Topic Details**: View partitions, replication factor, configuration
- **Delete Topics**: Remove topics when no longer needed

### Message Browsing
- **Browse Messages**: View messages in topics
- **Filter Messages**: Filter by partition, offset, key
- **Message Formats**: Support for JSON, plain text, Avro

### Consumer Groups
- **View Groups**: List all consumer groups
- **Lag Monitoring**: View consumer lag per partition
- **Offsets**: Check current consumer offsets
- **Group Details**: View consumer group configuration

### Cluster Overview
- **Brokers**: View Kafka broker information
- **Controller Status**: Check KRaft controller status
- **Performance Metrics**: Monitor cluster health

## Configuration

### Static Configuration (Infrastructure as Code)

The kafka-ui deployment uses static environment variables for cluster configuration:

```yaml
env:
  - name: DYNAMIC_CONFIG_ENABLED
    value: 'false'  # Disable web-based config
  
  - name: KAFKA_CLUSTERS_0_NAME
    value: 'minikube-kafka'  # Cluster display name
  
  - name: KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS
    value: 'kafka:9092'  # Kafka broker address
  
  - name: KAFKA_CLUSTERS_0_PROPERTIES
    value: 'security.protocol=PLAINTEXT'  # Security properties
```

### Adding Additional Clusters

To add more clusters, add additional environment variables:

```yaml
env:
  # ... existing cluster 0 ...

  - name: KAFKA_CLUSTERS_1_NAME
    value: 'production-kafka'
  - name: KAFKA_CLUSTERS_1_BOOTSTRAPSERVERS
    value: 'prod-kafka-broker:9092'
  
  - name: KAFKA_CLUSTERS_2_NAME
    value: 'staging-kafka'
  - name: KAFKA_CLUSTERS_2_BOOTSTRAPSERVERS
    value: 'staging-kafka:9092'
```

## Service Details

### Deployment
- **Name**: kafka-ui
- **Image**: provectuslabs/kafka-ui:latest
- **Replicas**: 1
- **Internal Port**: 8080
- **Health Endpoint**: /actuator/health

### Service
- **Name**: kafka-ui
- **Type**: LoadBalancer
- **External Port**: 8081
- **Target Port**: 8080
- **Access**: http://<EXTERNAL-IP>:8081

## Troubleshooting

### kafka-ui Pod Not Starting

```bash
# Check pod status
kubectl get pods -l app=kafka-ui

# View logs
kubectl logs -f -l app=kafka-ui
```

### Can't Connect to Kafka

**Symptoms:**
- Cluster shows as "Disconnected"
- Can't see topics
- Error messages in logs

**Solutions:**

1. **Verify Kafka is running:**
   ```bash
   kubectl get pods -l app=kafka
   ```

2. **Check Kafka service:**
   ```bash
   kubectl get svc kafka
   ```

3. **Verify bootstrap servers:**
   - Should be: `kafka:9092`
   - Service name: `kafka` (not IP address)

4. **Review Kafka UI logs:**
   ```bash
   kubectl logs -l app=kafka-ui | grep -i error
   ```

### External IP Shows <pending>

**Solution:**
```bash
# Ensure minikube tunnel is running in separate terminal
minikube tunnel
```

### Port 8081 Not Accessible

**Symptoms:**
- Connection timeout
- Page not loading

**Solutions:**

1. **Check firewall settings**
2. **Verify minikube tunnel is running**
3. **Check service status:**
   ```bash
   kubectl get svc kafka-ui
   ```

### Cluster Configuration Issues

**Symptoms:**
- Can't save cluster configuration
- Changes not persisting

**Solutions:**

1. **Check environment variables:**
   ```bash
   kubectl describe deployment kafka-ui | grep -A 20 "Environment:"
   ```

2. **Verify DYNAMIC_CONFIG_ENABLED is 'false'**

3. **Restart deployment if needed:**
   ```bash
   kubectl rollout restart deployment/kafka-ui
   ```

## Common Tasks

### View All Topics

1. Open Kafka UI
2. Navigate to **Topics**
3. Click on a topic to view details

### Create a New Topic

1. Navigate to **Topics**
2. Click **Create Topic** button
3. Fill in topic details:
   - Topic Name: `new-topic`
   - Partitions: `3`
   - Replication Factor: `1`
4. Click **Create**

### Browse Messages in a Topic

1. Navigate to **Topics**
2. Click on a topic
3. Click **Messages** tab
4. View messages in topic

### Monitor Consumer Lag

1. Navigate to **Consumers**
2. View consumer groups
3. Check **Lag** column for lagging consumers

### Delete a Topic

1. Navigate to **Topics**
2. Click on topic name
3. Click **Delete** button
4. Confirm deletion

## Integration with Existing Services

### Service Network

```
┌─────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                      │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                 │
│  │ kafka-ui     │  │   Kafka     │                 │
│  │ (8080/8081)  │  │   (9092)    │                 │
│  └─────────────┘  └──────┬───────┘                 │
│         │                  │                     │
│         │ Connects to       │                     │
│         └──────────────────┘                     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                 │
│  │ Integration │  │   Artemis   │                 │
│  │    Demo      │  │   (61616)   │                 │
│  └─────────────┘  └─────────────┘                 │
│         │                  │                     │
│         └────────────┬────────┘                    │
│                  │                              │
│                  └──────────────┐                 │
│                                 ┌─────────────┐   │
│                                 │ PostgreSQL   │   │
│                                 │   (5432)    │   │
│                                 └─────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Topic Flow

```
Integration Demo
    ↓
    JMS Producer
    ↓
    Artemis Queue (message.queue)
    ↓
    JMS Listener
    ↓
    PostgreSQL Store
    ↓
    Kafka Producer
    ↓
    Kafka Broker (processed-messages topic)
    ↓
    kafka-ui can view topic
    ↓
    Consumers can read
```

## Monitoring

### Health Checks

Kafka UI includes built-in health checks:

```bash
# Application health endpoint
curl http://$EXTERNAL_IP:8081/actuator/health

# Expected response: {"status":"UP"}
```

### Logs

```bash
# View kafka-ui logs
kubectl logs -f -l app=kafka-ui

# View Kafka broker logs
kubectl logs -l app=kafka -c kafka
```

### Resource Usage

```bash
# Check kafka-ui resource usage
kubectl top pods -l app=kafka-ui
```

## Cleanup

### Remove kafka-ui

```bash
# Delete deployment and service
kubectl delete deployment kafka-ui
kubectl delete service kafka-ui
```

### Remove All Services

```bash
# Delete entire base bundle
cd ~/BackendAcademy/minikube-bundle
kubectl delete -k base/
```

## Next Steps

1. **Configure Access Control**: Set up OAuth2 or SASL authentication for production
2. **Add Monitoring**: Integrate Prometheus metrics with Kafka UI
3. **Configure Alerts**: Set up alerts for consumer lag, topic health, broker availability
4. **Schema Registry**: Configure schema registry for Avro/Protobuf messages
5. **Documentation**: Document your Kafka topics and their purposes
6. **Backup**: Implement backup strategy for critical Kafka data

## References

- [Kafka UI GitHub Repository](https://github.com/provectus/kafka-ui)
- [Kafka UI Documentation](https://docs.kafka-ui.provectus.io/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)

## Support

For issues or questions:
- Check [Kafka UI Issues](https://github.com/provectus/kafka-ui/issues)
- Check [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- Review application logs for error messages

---

**Implementation Date:** 2025-04-02
**Image Version:** provectuslabs/kafka-ui:latest
**Configuration:** Static (Infrastructure as Code)
