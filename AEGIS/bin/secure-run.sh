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
  echo "Uso: $0 <comando-local> [args...]" >&2
  exit 1
fi

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

contains_shell_meta() {
  local arg
  for arg in "$@"; do
    if [[ "$arg" =~ [\;\|\&\`\$\(\)\<\>] ]]; then
      return 0
    fi
  done
  return 1
}

cmd_name="$1"
shift
cmd_base="$(basename "$cmd_name")"
cmd_lower="$(printf '%s' "$cmd_base" | tr '[:upper:]' '[:lower:]')"
command_line="$cmd_base"
if [[ $# -gt 0 ]]; then
  command_line+=" $*"
fi
escaped_cmd="$(json_escape "$command_line")"

allowed=0
for allowed_cmd in ${AEGIS_ALLOWED_COMMANDS:-}; do
  if [[ "$cmd_lower" == "$allowed_cmd" ]]; then
    allowed=1
    break
  fi
done

if (( allowed == 0 )); then
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '{"timestamp":"%s","source":"aegis","event":"command_not_allowed","action":"%s","status":"denied"}\n' "$ts" "$escaped_cmd" >> "$LOG_FILE"
  echo "[AEGIS] BLOQUEADO: comando fora da allowlist: $cmd_base" >&2
  exit 2
fi

if contains_shell_meta "$cmd_base" "$@"; then
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '{"timestamp":"%s","source":"aegis","event":"shell_meta_blocked","action":"%s","status":"denied"}\n' "$ts" "$escaped_cmd" >> "$LOG_FILE"
  echo "[AEGIS] BLOQUEADO: metacaracteres de shell não permitidos." >&2
  exit 2
fi

if [[ "${AEGIS_DENY_UPLOAD_DOWNLOAD:-1}" == "1" ]]; then
  for blocked in ${AEGIS_BLOCKED_COMMANDS}; do
    if [[ "$cmd_lower" == "$blocked" ]]; then
      ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      printf '{"timestamp":"%s","source":"aegis","event":"blocked_command","action":"%s","status":"denied"}\n' "$ts" "$escaped_cmd" >> "$LOG_FILE"
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
  if timeout "$timeout_s" "$cmd_base" "$@"; then
    status="ok"
    break
  fi
  sleep $((tries * 2))
done

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
printf '{"timestamp":"%s","source":"aegis","event":"secure_run","action":"%s","status":"%s","retries":%d}\n' "$ts" "$escaped_cmd" "$status" "$tries" >> "$LOG_FILE"

if [[ "$status" != "ok" ]]; then
  echo "[AEGIS] ERRO: comando falhou após $tries tentativa(s)." >&2
  exit 3
fi

echo "[AEGIS] OK: comando executado com segurança local."
