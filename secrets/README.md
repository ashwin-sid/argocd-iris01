# Secrets

Do not commit plaintext production secrets here.

The Helm chart supports:

```yaml
secrets:
  create: false
  existingSecret: iris-secrets
```

Create the Secret in each customer namespace using your chosen secret-management solution.

Required keys:

- `POSTGRES_PASSWORD`
- `POSTGRES_ADMIN_PASSWORD`
- `IRIS_SECRET_KEY`
- `IRIS_SECURITY_PASSWORD_SALT`
- `IRIS_ADM_PASSWORD`
