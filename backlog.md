# Backlog

## Completed Features

### Auto-Create Queues in Artemis
**Status:** ✅ Completed
**Date:** 2025-03-06
**File Modified:** `base/artemis/configmap.yaml`

**Description:**
Updated Artemis broker.xml configuration to enable automatic queue and address creation, eliminating the need to manually define queues in the configuration file.

**Changes Made:**
- Updated XML namespace from `http://activemq.org/schema` to `http://activemq.apache.org/schema/artemis/broker`
- Added acceptor configurations:
  - AMQP acceptor on port 61616 for message consumption
  - HTTP acceptor on port 8161 for web console access
- Added `address-settings` section with auto-creation enabled:
  - `match="#"` (wildcard for all addresses)
  - `auto-create-queues: true`
  - `auto-create-addresses: true`
  - `default-queue-routing-type: ANYCAST`
  - `default-address-routing-type: ANYCAST`
- Removed manually defined queues (user.created, order.processed, notification.sent)
- Kept JMX management enabled for metrics exporter

**Benefits:**
- Queues are automatically created when messages are sent to any address
- No need to update broker.xml when adding new queues
- Simplified configuration for dynamic message routing
- Maintains backward compatibility with existing metrics exporter

**Validation:**
```bash
kubectl apply --dry-run=client -k base/
```
