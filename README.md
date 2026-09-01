# PORTFOLIO-BRUNO-TELES

## AEGIS Push Guard (ChromeOS + GitHub)

Este repositório inclui uma camada de proteção para validar pushes e registrar auditoria.

### Link direto para criar chave (PAT Fine-grained)

https://github.com/settings/personal-access-tokens/new

> Nunca commite tokens/chaves no repositório.

## O que foi automatizado

- Workflow em `push` para validar conta autorizada.
- Falha automática do workflow para conta não autorizada.
- Auditoria com artefato (`aegis-audit`) por execução.
- Hook local de `pre-push` para uso no ChromeOS (opcional, porém recomendado).

## 1) Autorizar contas formalmente

Edite:

- `/home/runner/work/PORTFOLIO-BRUNO-TELES/PORTFOLIO-BRUNO-TELES/.github/security/authorized_accounts.txt`

Inclua um usuário GitHub por linha.

## 2) Ativar proteção em push no GitHub

O workflow está em:

- `/home/runner/work/PORTFOLIO-BRUNO-TELES/PORTFOLIO-BRUNO-TELES/.github/workflows/aegis-push-guard.yml`

Recomendação: marque esse workflow como **Required status check** na branch protegida.

## 3) Ativar proteção local no ChromeOS

No terminal do seu ChromeOS (Crostini):

1. Configure o hook versionado:
   - `git config core.hooksPath .githooks`
2. Crie uma senha forte para fingerprint local:
   - `export AEGIS_DEVICE_SECRET="defina-uma-chave-forte"`
3. Gere o fingerprint esperado:
   - `export AEGIS_ALLOWED_DEVICE_HASH="$(cat /etc/machine-id | sha256sum | awk '{print $1}')"`
4. Para persistir, mova variáveis para seu arquivo de perfil shell (`~/.bashrc` ou `~/.zshrc`).

Sem essas variáveis, o `pre-push` bloqueia o envio.

## 4) Requisitos de conta (2FA e e-mail)

Para cumprir a política descrita:

- Contas autorizadas devem ter 2FA ativo.
- E-mail da conta deve estar verificado.
- Revogue token imediatamente em caso de incidente.

Esses requisitos devem ser mantidos na conta GitHub, além desta automação no repositório.