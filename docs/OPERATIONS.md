# Operations

## Check generated Applications

```bash
kubectl -n argocd get applicationset dfir-iris-customers
kubectl -n argocd get applications -l app.kubernetes.io/part-of=dfir-iris
```

## Check one customer

```bash
kubectl -n cust001-appy-bbbbb get pods,pvc,svc,ingress
```

## Check IRIS logs

```bash
kubectl -n cust001-appy-bbbbb logs deploy/cust001-appy-bbbbb
kubectl -n cust001-appy-bbbbb logs deploy/cust001-appy-bbbbb-worker
```

## Initial administrator password

If using the placeholder Secret created by the chart, the initial password is taken from the chart value `secrets.irisAdminPassword`.

For production, supply a unique secret per customer.

## Upgrade all customers

Change each customer file:

```yaml
iris:
  version: v2.4.29
```

to the tested target release and commit the changes.

For a controlled rollout, update one customer first, verify, then update the remainder.

## Pause auto-sync for a customer

A generated Application is owned by the ApplicationSet. Do not edit it manually as a long-term configuration strategy.

Instead change the ApplicationSet policy or use an environment-specific mechanism in Git if you need staged synchronization.

## Customer deletion

Deletion is intentionally conservative:

```yaml
preserveResourcesOnDeletion: true
```

Removing `customers/custNNN.yaml` removes the generated Application but preserves the Kubernetes resources.

This prevents a Git file deletion from also deleting the customer's database and evidence data.
