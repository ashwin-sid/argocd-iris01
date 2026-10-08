# DFIR-IRIS multi-customer GitOps with Rancher + Argo CD ApplicationSet

This repository implements the following operating model:

- **Rancher** provisions and manages the downstream Kubernetes cluster.
- **Argo CD** is connected to that downstream cluster and deploys DFIR-IRIS.
- **ApplicationSet** is the customer templating engine.
- Each customer gets one Argo CD `Application` and one Kubernetes namespace.
- Naming convention: `cust001-appy-bbbbb`, `cust002-appy-bbbbb`, etc.
- Argo CD Project: `dfir` (the Kubernetes-safe form of “DFIR”).

The Rancher server and Argo CD server can run on the same management VM. The workload cluster can be on a separate VM. Argo CD does not need to be installed on the workload VM; the cluster only needs to be registered with Argo CD.

> DFIR-IRIS note: this example pins the stable v2.4.29 container images. Review the upstream DFIR-IRIS release notes before changing versions.

## Repository layout

```text
.
├── bootstrap/
│   ├── appproject.yaml
│   └── applicationset.yaml
├── charts/
│   └── dfir-iris/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── customers/
│   ├── cust001.yaml
│   └── cust002.yaml
├── scripts/
│   ├── add-customer.sh
│   ├── configure-repo.sh
│   └── validate.sh
└── docs/
    ├── ARCHITECTURE.md
    └── OPERATIONS.md
```

## 1. Prerequisites

You already have most of these:

1. Rancher is managing the downstream Kubernetes cluster.
2. Argo CD is running on the management VM.
3. The downstream cluster is already registered in Argo CD.
4. Argo CD can read this Git repository.
5. The downstream cluster can pull images from `ghcr.io`.
6. A default StorageClass exists, or you set a StorageClass in each customer file.

Check the Argo CD cluster name:

```bash
argocd cluster list
```

The value in the `NAME` column is what should be used as `destination.clusterName` in each customer file.

## 2. Put this repository in Git

Create a Git repository and push this directory. Then replace the placeholder repository URL:

```bash
./scripts/configure-repo.sh \
  https://git.example.com/platform/dfir-iris-gitops.git
```

Commit and push the change.

For a private Git repository, add its credentials to Argo CD using your normal Argo CD repository configuration.

## 3. Set the downstream cluster name

Edit each customer file under `customers/`.

Example:

```yaml
customer:
  id: cust001

app:
  name: cust001-appy-bbbbb
  namespace: cust001-appy-bbbbb

destination:
  clusterName: downstream-rancher

iris:
  version: v2.4.29
  ingress:
    enabled: "false"
    host: iris-cust001.example.internal
  storageClass: ""
  storage:
    database: 10Gi
    shared: 20Gi
  secrets:
    create: "true"
    existingSecret: iris-secrets
```

`app.name` and `app.namespace` are intentionally explicit, so your naming standard is visible in Git and reviewed in pull requests.

## 4. Bootstrap the Argo CD Project and ApplicationSet


Also, before applying the ApplicationSet, make sure bootstrap/applicationset.yaml no longer contains:
REPLACE_ME_GIT_REPO_URL

and make sure this works:
argocd cluster list

Apply these two resources to the cluster where Argo CD itself is running:

```bash
kubectl apply -f bootstrap/appproject.yaml
kubectl apply -f bootstrap/applicationset.yaml
```

The ApplicationSet controller reads `customers/*.yaml`. Each file becomes an Argo CD `Application`.

Expected result:

```text
dfir project
├── cust001-appy-bbbbb  -> downstream-rancher / namespace cust001-appy-bbbbb
└── cust002-appy-bbbbb  -> downstream-rancher / namespace cust002-appy-bbbbb
```

The ApplicationSet uses:

```yaml
syncOptions:
  - CreateNamespace=true
```

so Argo CD creates each customer namespace.

## 5. Add future customers

Use the helper:

```bash
./scripts/add-customer.sh 3 downstream-rancher
```

This creates:

```text
customers/cust003.yaml
```

with:

```text
cust003-appy-bbbbb
```

Review the customer-specific host, storage and version, then commit and push:

```bash
git add customers/cust003.yaml
git commit -m "Add cust003 DFIR-IRIS tenant"
git push
```

ApplicationSet will discover the new file and generate the new Argo CD Application automatically.

## 6. Secrets

The chart contains placeholder values so the repository can render without an external secret-management dependency.

**Before production use, do not leave the `CHANGEME` values in place.**

The recommended production pattern is to change each customer file to:

```yaml
iris:
  secrets:
    create: "false"
    existingSecret: iris-secrets
```

and create/manage a Secret named `iris-secrets` in each customer namespace with your preferred mechanism (for example SOPS, External Secrets, Vault, or Sealed Secrets).

Expected keys:

```text
POSTGRES_PASSWORD
POSTGRES_ADMIN_PASSWORD
IRIS_SECRET_KEY
IRIS_SECURITY_PASSWORD_SALT
IRIS_ADM_PASSWORD
```

This repository intentionally does not implement RBAC, NetworkPolicies, firewall rules or Rancher ACLs.

## 7. Access

By default the sample customers have ingress disabled.

For initial testing you can port-forward the IRIS application service:

```bash
kubectl -n cust001-appy-bbbbb port-forward svc/cust001-appy-bbbbb 8000:8000
```

Then browse to:

```text
http://127.0.0.1:8000
```

If you already have an ingress controller, set:

```yaml
iris:
  ingress:
    enabled: "true"
    host: iris-cust001.example.internal
```

The chart creates a standard Kubernetes Ingress to the IRIS app service. TLS termination can be added later to match your environment.

## 8. How ApplicationSet is acting as the templating engine

The important flow is:

```text
customers/cust001.yaml
        |
        v
ApplicationSet Git file generator
        |
        +--> metadata.name       = cust001-appy-bbbbb
        +--> destination.name    = downstream-rancher
        +--> destination.namespace = cust001-appy-bbbbb
        +--> Helm parameters     = version, ingress, storage
        |
        v
Generated Argo CD Application
        |
        v
Helm renders DFIR-IRIS Kubernetes resources
        |
        v
Rancher-managed downstream cluster
```

You do not manually copy an Application manifest per customer. The customer file is the unit of configuration.

## 9. Storage note

The IRIS app and worker share a PVC. On a single-node downstream cluster, `ReadWriteOnce` is normally sufficient because both pods can run on the same node.

For a multi-node cluster, use an RWX-capable StorageClass and change:

```yaml
persistence:
  shared:
    accessMode: ReadWriteMany
```

in `charts/dfir-iris/values.yaml`.

## 10. Remove a customer

Remove its customer file and commit:

```bash
git rm customers/cust003.yaml
git commit -m "Remove cust003 DFIR-IRIS tenant"
git push
```

Because `preserveResourcesOnDeletion: true` is configured, removal of the generated Argo CD Application will **not automatically delete the customer's Kubernetes resources**. This is intentional to reduce the risk of accidental customer-data deletion.

Perform customer decommissioning as a separate controlled procedure.

## 11. Validate locally

Run:

```bash
./scripts/validate.sh
```

This validates the YAML files and checks the naming rules and required customer fields.
