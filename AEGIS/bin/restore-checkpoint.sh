#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY_FILE="$REPO_ROOT/AEGIS/config/security-policy.env"
LOG_FILE="$REPO_ROOT/AEGIS/logs/aegis-audit.jsonl"
CHECKPOINT_DIR="$REPO_ROOT/AEGIS/checkpoints"

# shellcheck disable=SC1090
source "$POLICY_FILE"
"$REPO_ROOT/AEGIS/bin/preflight.sh" >/dev/null

archive="${1:-}"
if [[ -z "$archive" ]]; then
  archive="$(ls -1t "$CHECKPOINT_DIR"/aegis-*.tar.gz 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$archive" || ! -f "$archive" ]]; then
  echo "[AEGIS] ERRO: checkpoint não encontrado." >&2
  exit 1
fi

if [[ ! -f "$archive.sha256" ]]; then
  echo "[AEGIS] ERRO: hash do checkpoint não encontrado." >&2
  exit 1
fi

sha256sum -c "$archive.sha256" >/dev/null

cd "$REPO_ROOT"
tar -xzf "$archive"

printf '{"timestamp":"%s","source":"aegis","event":"checkpoint_restored","action":"%s","status":"ok"}\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$archive" >> "$LOG_FILE"
echo "[AEGIS] restore aplicado de: $archive"
