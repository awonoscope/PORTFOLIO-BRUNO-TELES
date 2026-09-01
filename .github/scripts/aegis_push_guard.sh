#!/usr/bin/env bash
set -euo pipefail

AUTHORIZED_FILE="${AEGIS_AUTHORIZED_ACCOUNTS_FILE:-.github/security/authorized_accounts.txt}"
AUDIT_FILE="${AEGIS_AUDIT_FILE:-aegis-audit/audit.json}"
ACTOR="${GITHUB_ACTOR:-unknown}"
REF="${GITHUB_REF_NAME:-unknown}"
SHA="${GITHUB_SHA:-unknown}"
RUN_ID="${GITHUB_RUN_ID:-unknown}"
REPOSITORY="${GITHUB_REPOSITORY:-unknown}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$(dirname "$AUDIT_FILE")"

if [[ ! -f "$AUTHORIZED_FILE" ]]; then
  cat > "$AUDIT_FILE" <<EOF
{"timestamp":"$TIMESTAMP","repository":"$REPOSITORY","run_id":"$RUN_ID","actor":"$ACTOR","ref":"$REF","sha":"$SHA","authorized":false,"reason":"authorized_accounts_file_missing"}
EOF
  echo "Arquivo de autorização não encontrado: $AUTHORIZED_FILE"
  exit 1
fi

is_authorized=false
while IFS= read -r line; do
  account="$(echo "$line" | xargs)"
  [[ -z "$account" || "$account" == \#* ]] && continue
  if [[ "$account" == "$ACTOR" ]]; then
    is_authorized=true
    break
  fi
done < "$AUTHORIZED_FILE"

if [[ "$is_authorized" == true ]]; then
  cat > "$AUDIT_FILE" <<EOF
{"timestamp":"$TIMESTAMP","repository":"$REPOSITORY","run_id":"$RUN_ID","actor":"$ACTOR","ref":"$REF","sha":"$SHA","authorized":true,"reason":"authorized_account"}
EOF
  echo "AEGIS guard: conta autorizada ($ACTOR)."
  exit 0
fi

cat > "$AUDIT_FILE" <<EOF
{"timestamp":"$TIMESTAMP","repository":"$REPOSITORY","run_id":"$RUN_ID","actor":"$ACTOR","ref":"$REF","sha":"$SHA","authorized":false,"reason":"unauthorized_account"}
EOF

echo "AEGIS guard: conta não autorizada ($ACTOR). Acesso negado."
exit 1
