#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY_FILE="$REPO_ROOT/AEGIS/config/security-policy.env"
LOG_FILE="$REPO_ROOT/AEGIS/logs/aegis-audit.jsonl"

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "[AEGIS] ERRO: policy não encontrada." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$POLICY_FILE"
"$REPO_ROOT/AEGIS/bin/preflight.sh" >/dev/null

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 '<comando-local>'" >&2
  exit 1
fi

CMD="$*"
LOWER_CMD="$(echo "$CMD" | tr '[:upper:]' '[:lower:]')"

if [[ "${AEGIS_DENY_UPLOAD_DOWNLOAD:-1}" == "1" ]]; then
  for blocked in ${AEGIS_BLOCKED_COMMANDS}; do
    if [[ "$LOWER_CMD" == *"$blocked"* ]]; then
      ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      printf '{"timestamp":"%s","source":"aegis","event":"blocked_command","action":"%s","status":"denied"}\n' "$ts" "${CMD//"/\\\"}" >> "$LOG_FILE"
      echo "[AEGIS] BLOQUEADO: comando contém padrão proibido: $blocked" >&2
      exit 2
    fi
  done
fi

tries=0
max_retries="${AEGIS_MAX_RETRY:-3}"
timeout_s="${AEGIS_TIMEOUT_SECONDS:-15}"
status="error"

while (( tries < max_retries )); do
  tries=$((tries + 1))
  if timeout "$timeout_s" bash -lc "$CMD"; then
    status="ok"
    break
  fi
  sleep $((tries * 2))
done

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
printf '{"timestamp":"%s","source":"aegis","event":"secure_run","action":"%s","status":"%s","retries":%d}\n' "$ts" "${CMD//"/\\\"}" "$status" "$tries" >> "$LOG_FILE"

if [[ "$status" != "ok" ]]; then
  echo "[AEGIS] ERRO: comando falhou após $tries tentativa(s)." >&2
  exit 3
fi

echo "[AEGIS] OK: comando executado com segurança local."
