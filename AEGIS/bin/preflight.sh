#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY_FILE="$REPO_ROOT/AEGIS/config/security-policy.env"

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "[AEGIS] ERRO: policy não encontrada em $POLICY_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$POLICY_FILE"

if [[ "${AEGIS_REQUIRE_SANDBOX:-1}" == "1" ]]; then
  case "$REPO_ROOT" in
    /home/runner/work/*) : ;;
    *)
      echo "[AEGIS] ERRO: ambiente fora da sandbox permitida: $REPO_ROOT" >&2
      exit 1
      ;;
  esac
fi

if [[ "${AEGIS_ALLOW_ONLY_LOCAL_INPUT:-1}" == "1" ]]; then
  if [[ -n "${http_proxy:-}" || -n "${https_proxy:-}" ]]; then
    echo "[AEGIS] ERRO: proxy detectado; execução remota não permitida." >&2
    exit 1
  fi
fi

if [[ "${AEGIS_TELEMETRY_MODE:-local-only}" != "local-only" ]]; then
  echo "[AEGIS] ERRO: telemetria deve permanecer em modo local-only." >&2
  exit 1
fi

echo "[AEGIS] preflight OK - sandbox e política validadas."
