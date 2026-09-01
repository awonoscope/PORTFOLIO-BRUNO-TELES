#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY_FILE="$REPO_ROOT/AEGIS/config/security-policy.env"
LOG_FILE="$REPO_ROOT/AEGIS/logs/aegis-audit.jsonl"

# shellcheck disable=SC1090
source "$POLICY_FILE"
"$REPO_ROOT/AEGIS/bin/preflight.sh" >/dev/null

interval="${AEGIS_GUARD_INTERVAL_SECONDS:-5}"
telemetry_file="$REPO_ROOT/AEGIS/logs/telemetry-local.jsonl"

echo "[AEGIS] guard iniciado (intervalo=${interval}s). Ctrl+C para encerrar."
while true; do
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  if "$REPO_ROOT/AEGIS/bin/check-integrity.sh" >/dev/null 2>&1; then
    printf '{"timestamp":"%s","source":"aegis","event":"guard_heartbeat","status":"ok"}\n' "$ts" >> "$telemetry_file"
  else
    printf '{"timestamp":"%s","source":"aegis","event":"integrity_fail_detected","status":"alert"}\n' "$ts" >> "$telemetry_file"
    if [[ "${AEGIS_AUTO_RESTORE_ON_INTEGRITY_FAIL:-1}" == "1" ]]; then
      if "$REPO_ROOT/AEGIS/bin/restore-checkpoint.sh" >/dev/null 2>&1; then
        printf '{"timestamp":"%s","source":"aegis","event":"auto_restore","status":"ok"}\n' "$ts" >> "$telemetry_file"
      else
        printf '{"timestamp":"%s","source":"aegis","event":"auto_restore","status":"error"}\n' "$ts" >> "$telemetry_file"
      fi
    fi
  fi
  sleep "$interval"
done
