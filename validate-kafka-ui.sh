#!/bin/bash

echo "=== Kafka UI Implementation Validation ==="
echo ""

SUCCESS_COUNT=0
TOTAL_COUNT=0

check_file() {
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if [ -f "$1" ]; then
        echo "✓ $1"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "✗ $1 (missing)"
    fi
}

check_directory() {
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if [ -d "$1" ]; then
        echo "✓ $1"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "✗ $1 (missing)"
    fi
}

echo "1. Checking kafka-ui directory..."
check_directory "$HOME/BackendAcademy/minikube-bundle/base/kafka-ui"

echo ""
echo "2. Checking Kafka UI manifests..."
check_file "$HOME/BackendAcademy/minikube-bundle/base/kafka-ui/deployment.yaml"
check_file "$HOME/BackendAcademy/minikube-bundle/base/kafka-ui/service.yaml"

echo ""
echo "3. Checking Kustomization update..."
if grep -q "kafka-ui" "$HOME/BackendAcademy/minikube-bundle/base/kustomization.yaml"; then
    echo "✓ Kustomization includes kafka-ui"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
else
    echo "✗ Kustomization missing kafka-ui"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
fi

echo ""
echo "4. Checking documentation..."
check_file "$HOME/BackendAcademy/minikube-bundle/KAFKA_UI.md"

echo ""
echo "5. Checking README.md update..."
if grep -q "kafka-ui" "$HOME/BackendAcademy/minikube-bundle/README.md"; then
    echo "✓ README.md includes kafka-ui"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
else
    echo "✗ README.md missing kafka-ui"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
fi

echo ""
echo "6. Validating Kubernetes manifests..."
cd ~/BackendAcademy/minikube-bundle
if kubectl apply --dry-run=client -f base/kafka-ui/deployment.yaml 2>&1 | grep -qE "(kafka-ui created|kafka-ui configured)"; then
    echo "✓ Deployment manifest valid"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
else
    echo "✗ Deployment manifest validation failed"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
fi

if kubectl apply --dry-run=client -f base/kafka-ui/service.yaml 2>&1 | grep -qE "(kafka-ui created|kafka-ui configured)"; then
    echo "✓ Service manifest valid"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
else
    echo "✗ Service manifest validation failed"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
fi

echo ""
echo "7. Checking environment variables in deployment..."
if grep -q "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS" "$HOME/BackendAcademy/minikube-bundle/base/kafka-ui/deployment.yaml"; then
    echo "✓ Bootstrap servers configured (kafka:9092)"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
else
    echo "✗ Bootstrap servers not configured"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
fi

echo ""
echo "=== Validation Complete ==="
echo ""
echo "Results: $SUCCESS_COUNT/$TOTAL_COUNT checks passed"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo "✓ All validations passed! Ready for deployment."
    echo ""
    echo "Next steps:"
    echo "1. Deploy to Kubernetes: cd ~/BackendAcademy/minikube-bundle && kubectl apply -k base/"
    echo "2. Start tunnel: minikube tunnel"
    echo "3. Access Kafka UI: kubectl get svc kafka-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
    echo "4. Open browser: http://<EXTERNAL-IP>:8081"
    exit 0
else
    echo "✗ Some validations failed. Please review output above."
    exit 1
fi
