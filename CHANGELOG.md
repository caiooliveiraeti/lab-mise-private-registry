# Changelog

## [1.0.0] — 2026-04-28

### Added

- Stack Docker Compose com Nexus OSS, container de setup one-shot e containers dev1/dev2
- Setup automatizado e idempotente: auth, EULA, repositórios, usuários, metadata JVM e tarballs Corretto
- Container dev com mise configurado para instalar Java exclusivamente via Nexus local
- Script `download-corretto.sh` para pré-download dos tarballs
- Script `test-java.sh` para validar instalação das 3 versões do Corretto

### Fixed

- Aceite de EULA via REST API — Nexus 3.70+ retorna 403 em todos os uploads sem isso
- `writePolicy` em maiúsculas (`ALLOW`) — valor em minúsculas era ignorado pelo Nexus
- Upload de metadata via `-d` em vez de pipe para `-T -` — chunked encoding causava 403
- Exit code de `step-tarballs.sh` e `step-auth.sh`: padrão `[ cond ] && ... && exit 1` retornava 1 em execução bem-sucedida, abortando o `configure.sh` com `set -eu`
- URLs no metadata apontam para `corretto-local` no Nexus em vez de `corretto.aws`
