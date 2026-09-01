# AEGIS - Repositório Local de Segurança Operacional

AEGIS aplica controles defensivos para execução local com foco em:
- evitar riscos de upload/download indevido,
- manter funções já em execução com fallback seguro,
- rastrear ações em trilha de auditoria,
- validar ambiente sandbox antes de qualquer operação.

## Estrutura
- `config/security-policy.env`: política central de segurança
- `bin/preflight.sh`: valida sandbox e políticas locais
- `bin/secure-run.sh`: wrapper para execução segura com allowlist e bloqueio de rede/URLs
- `bin/check-integrity.sh`: baseline e verificação de integridade dos arquivos AEGIS
- `bin/create-checkpoint.sh`: cria checkpoint seguro do AEGIS
- `bin/restore-checkpoint.sh`: restaura checkpoint validado por hash
- `bin/aegis-guard.sh`: guarda contínua com telemetria local e auto-recuperação
- `logs/aegis-audit.jsonl`: auditoria estruturada das execuções
- `logs/telemetry-local.jsonl`: telemetria local (sem envio remoto)

## Execução didática (terminal ChromeOS)
No terminal, execute exatamente nesta ordem:

```bash
cd /home/runner/work/PORTFOLIO-BRUNO-TELES/PORTFOLIO-BRUNO-TELES
chmod +x AEGIS/bin/*.sh
AEGIS/bin/preflight.sh
AEGIS_REBASELINE_APPROVED=yes AEGIS/bin/check-integrity.sh --init
AEGIS/bin/secure-run.sh echo verificacao-local-ativa
AEGIS/bin/create-checkpoint.sh
AEGIS/bin/secure-run.sh wget https://example.com   # deve bloquear (rede/URL)
AEGIS/bin/check-integrity.sh
AEGIS/bin/restore-checkpoint.sh                     # restaura último checkpoint válido
```

## Regras de segurança implementadas
1. **Sandbox first**: execução permitida apenas em caminho sandbox esperado.
2. **Sem upload/download**: bloqueio de comandos comuns de transferência (`curl`, `wget`, `scp`, etc.).
3. **Entrada local**: política para evitar execução acoplada a proxies remotos.
4. **Execução sem shell inline**: comando roda por argumentos, reduzindo bypass por expansão de shell.
5. **Bloqueio de URL remota**: argumentos `http(s)://`, `ftp://` e `s3://` são negados.
6. **Timeout + retry**: cada comando tem timeout e retentativas controladas.
7. **Auditoria obrigatória**: cada ação é registrada com `timestamp`, `action`, `status` e `retries`.
8. **Integridade com bloqueio de rebaseline**: baseline só é recriada com autorização explícita.
9. **Checkpoint + auto-restore**: ambiente pode retornar automaticamente ao último estado íntegro.

## Guarda contínua e auto-recuperação

Para operação contínua:
```bash
AEGIS/bin/aegis-guard.sh
```

Comportamento:
1. executa verificação de integridade em loop;
2. grava heartbeat local em `logs/telemetry-local.jsonl`;
3. em falha de integridade, tenta restore automático do último checkpoint íntegro;
4. mantém trilha de auditoria local para investigação e requalificação da rota.

## Política de fronteira (sem dependência externa)

Este AEGIS está configurado para **não requisitar informações fora deste chat/máquina** e para manter telemetria **local-only**.
Integrações externas (incluindo endpoints remotos) não são ativadas por padrão para evitar risco operacional.

## Estratégia de agentes Copilot (sem duplicação)
Use agentes distintos com responsabilidades separadas:
1. **security-review**: revisar risco de exposição e abuso de comando.
2. **explore**: mapear acoplamentos e sugerir hardening por componente.
3. **task**: executar checklist operacional e reportar saídas.

Recomendação: cada agente recebe escopo próprio para evitar repetir comandos/estratégias.
