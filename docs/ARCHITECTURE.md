# Architecture

## Responsibility split

### Rancher

Rancher is responsible for the Kubernetes cluster lifecycle:

- provisioning/importing the cluster;
- Kubernetes upgrades;
- node lifecycle;
- cluster health;
- storage and ingress platform components as required by your environment.

### Argo CD

Argo CD is responsible for application desired state:

- watches this Git repository;
- ApplicationSet generates one Application per customer;
- each generated Application targets the registered downstream cluster;
- Argo CD creates the customer namespace;
- Helm renders and deploys the DFIR-IRIS workload.

## Topology

```text
Management VM
+---------------------------------------------------+
| Rancher                                           |
| Argo CD                                           |
| ApplicationSet controller                         |
+---------------------------+-----------------------+
                            |
                            | Kubernetes API
                            v
Downstream/target VM
+---------------------------------------------------+
| Rancher-managed Kubernetes cluster                |
|                                                   |
| namespace cust001-appy-bbbbb                      |
|   DFIR-IRIS app / worker / db / rabbitmq / PVCs   |
|                                                   |
| namespace cust002-appy-bbbbb                      |
|   DFIR-IRIS app / worker / db / rabbitmq / PVCs   |
+---------------------------------------------------+
```

## Why a Git file generator

A List generator would work, but it makes the ApplicationSet itself the customer inventory.

The Git file generator keeps the generic ApplicationSet stable and moves tenant-specific data into individual files:

```text
customers/cust001.yaml
customers/cust002.yaml
customers/cust003.yaml
```

That gives a small, auditable customer-onboarding change and avoids copying whole Kubernetes manifests.

## Data isolation

Each customer gets:

- a dedicated namespace;
- a dedicated PostgreSQL PVC;
- a dedicated shared IRIS data PVC;
- a dedicated IRIS Secret;
- separate Deployments and Services.

RBAC, NetworkPolicy and firewall isolation are intentionally outside this example.
