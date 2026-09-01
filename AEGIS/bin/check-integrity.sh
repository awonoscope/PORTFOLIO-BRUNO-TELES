#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE_FILE="$REPO_ROOT/AEGIS/logs/integrity.sha256"

cd "$REPO_ROOT"

if [[ "${1:-}" == "--init" ]]; then
  find AEGIS -type f ! -path "AEGIS/logs/*" -print0 | sort -z | xargs -0 sha256sum > "$BASELINE_FILE"
  echo "[AEGIS] baseline criada em $BASELINE_FILE"
  exit 0
fi

if [[ ! -f "$BASELINE_FILE" ]]; then
  echo "[AEGIS] ERRO: baseline inexistente. Execute: $0 --init" >&2
  exit 1
fi

tmp_file="$(mktemp)"
find AEGIS -type f ! -path "AEGIS/logs/*" -print0 | sort -z | xargs -0 sha256sum > "$tmp_file"

if diff -u "$BASELINE_FILE" "$tmp_file"; then
  echo "[AEGIS] integridade OK"
  rm -f "$tmp_file"
  exit 0
else
  echo "[AEGIS] ALERTA: divergência de integridade detectada" >&2
  rm -f "$tmp_file"
  exit 2
fi
