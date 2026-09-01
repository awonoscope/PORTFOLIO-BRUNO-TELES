# AEGIS - Repositório Local de Segurança Operacional

AEGIS aplica controles defensivos para execução local com foco em:
- evitar riscos de upload/download indevido,
- manter funções já em execução com fallback seguro,
- rastrear ações em trilha de auditoria,
- validar ambiente sandbox antes de qualquer operação.

## Estrutura
- `config/security-policy.env`: política central de segurança
- `bin/preflight.sh`: valida sandbox e políticas locais
- `bin/secure-run.sh`: wrapper para execução segura com bloqueio de comandos de rede
- `bin/check-integrity.sh`: baseline e verificação de integridade dos arquivos AEGIS
- `logs/aegis-audit.jsonl`: auditoria estruturada das execuções

## Execução didática (terminal ChromeOS)
No terminal, execute exatamente nesta ordem:

```bash
cd /home/runner/work/PORTFOLIO-BRUNO-TELES/PORTFOLIO-BRUNO-TELES
chmod +x AEGIS/bin/*.sh
AEGIS/bin/preflight.sh
AEGIS/bin/check-integrity.sh --init
AEGIS/bin/secure-run.sh "echo 'verificacao local ativa'"
AEGIS/bin/secure-run.sh "wget https://example.com"   # deve bloquear
AEGIS/bin/check-integrity.sh
```

## Regras de segurança implementadas
1. **Sandbox first**: execução permitida apenas em caminho sandbox esperado.
2. **Sem upload/download**: bloqueio de comandos comuns de transferência (`curl`, `wget`, `scp`, etc.).
3. **Entrada local**: política para evitar execução acoplada a proxies remotos.
4. **Timeout + retry**: cada comando tem timeout e retentativas controladas.
5. **Auditoria obrigatória**: cada ação é registrada com `timestamp`, `action`, `status` e `retries`.
6. **Integridade**: valida se arquivos AEGIS foram alterados fora do esperado.

## Estratégia de agentes Copilot (sem duplicação)
Use agentes distintos com responsabilidades separadas:
1. **security-review**: revisar risco de exposição e abuso de comando.
2. **explore**: mapear acoplamentos e sugerir hardening por componente.
3. **task**: executar checklist operacional e reportar saídas.

Recomendação: cada agente recebe escopo próprio para evitar repetir comandos/estratégias.
