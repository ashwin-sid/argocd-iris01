#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <customer-number> <argocd-cluster-name> [domain-suffix]"
  echo "Example: $0 3 downstream-rancher example.internal"
  exit 1
fi

num="$1"
cluster="$2"
domain="${3:-example.internal}"

printf -v cust "cust%03d" "${num}"
name="${cust}-appy-bbbbb"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
out="${repo_root}/customers/${cust}.yaml"

if [[ -e "${out}" ]]; then
  echo "ERROR: ${out} already exists"
  exit 1
fi

cat > "${out}" <<EOF
customer:
  id: ${cust}

app:
  name: ${name}
  namespace: ${name}

destination:
  clusterName: ${cluster}

iris:
  version: v2.4.29
  ingress:
    enabled: "false"
    host: iris-${cust}.${domain}
  storageClass: ""
  storage:
    database: 10Gi
    shared: 20Gi
  secrets:
    create: "true"
    existingSecret: iris-secrets
EOF

echo "Created ${out}"
