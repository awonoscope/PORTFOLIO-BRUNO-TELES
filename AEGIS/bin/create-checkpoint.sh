#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY_FILE="$REPO_ROOT/AEGIS/config/security-policy.env"
LOG_FILE="$REPO_ROOT/AEGIS/logs/aegis-audit.jsonl"
CHECKPOINT_DIR="$REPO_ROOT/AEGIS/checkpoints"

# shellcheck disable=SC1090
source "$POLICY_FILE"
"$REPO_ROOT/AEGIS/bin/preflight.sh" >/dev/null

mkdir -p "$CHECKPOINT_DIR"
checkpoint_id="$(date -u +"%Y%m%dT%H%M%SZ")"
archive="$CHECKPOINT_DIR/aegis-$checkpoint_id.tar.gz"

cd "$REPO_ROOT"
tar -czf "$archive" AEGIS/bin AEGIS/config AEGIS/README.md
sha256sum "$archive" > "$archive.sha256"

printf '{"timestamp":"%s","source":"aegis","event":"checkpoint_created","action":"%s","status":"ok"}\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$archive" >> "$LOG_FILE"
echo "[AEGIS] checkpoint criado: $archive"
