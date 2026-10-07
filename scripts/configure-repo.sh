#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <git-repo-url>"
  exit 1
fi

repo_url="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

python3 - "${repo_root}" "${repo_url}" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
repo = sys.argv[2]
p = root / "bootstrap" / "applicationset.yaml"
text = p.read_text()
text = text.replace("REPLACE_ME_GIT_REPO_URL", repo)
p.write_text(text)
print(f"Configured {p} for {repo}")
PY
