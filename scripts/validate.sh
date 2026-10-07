#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

python3 - "${repo_root}" <<'PY'
from pathlib import Path
import re
import sys
import yaml

root = Path(sys.argv[1])
errors = []

# Parse non-template YAML.
for p in [
    root / "bootstrap" / "appproject.yaml",
    root / "bootstrap" / "applicationset.yaml",
    root / "charts" / "dfir-iris" / "Chart.yaml",
    root / "charts" / "dfir-iris" / "values.yaml",
]:
    try:
        yaml.safe_load(p.read_text())
    except Exception as exc:
        errors.append(f"{p}: invalid YAML: {exc}")

pattern = re.compile(r"^cust\d{3}-appy-bbbbb$")
cust_pattern = re.compile(r"^cust\d{3}$")

for p in sorted((root / "customers").glob("*.yaml")):
    try:
        data = yaml.safe_load(p.read_text())
    except Exception as exc:
        errors.append(f"{p}: invalid YAML: {exc}")
        continue

    cid = data.get("customer", {}).get("id", "")
    app = data.get("app", {}).get("name", "")
    ns = data.get("app", {}).get("namespace", "")
    cluster = data.get("destination", {}).get("clusterName", "")

    if not cust_pattern.match(cid):
        errors.append(f"{p}: customer.id must look like cust001")
    if not pattern.match(app):
        errors.append(f"{p}: app.name must look like cust001-appy-bbbbb")
    if ns != app:
        errors.append(f"{p}: app.namespace must equal app.name")
    if not cluster:
        errors.append(f"{p}: destination.clusterName is required")
    if p.stem != cid:
        errors.append(f"{p}: filename should match customer.id")

appset = (root / "bootstrap" / "applicationset.yaml").read_text()
if "REPLACE_ME_GIT_REPO_URL" in appset:
    print("WARNING: bootstrap/applicationset.yaml still contains REPLACE_ME_GIT_REPO_URL")

if errors:
    print("Validation failed:")
    for e in errors:
        print(f" - {e}")
    raise SystemExit(1)

print("Validation passed.")
PY
