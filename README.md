# lab-mise

Laboratório que simula um ambiente corporativo com acesso à internet bloqueado, onde desenvolvedores instalam ferramentas Java exclusivamente através de um repositório interno Nexus OSS provisionado automaticamente.

O objetivo é demonstrar e testar o uso do [mise](https://mise.jdx.dev/) com `url_replacements` para redirecionar downloads do Amazon Corretto para um servidor Nexus local — sem nenhuma dependência de rede externa no momento do uso.

---

## Visão geral da arquitetura

```
┌─────────────────────────────────────────────────────────┐
│  docker-compose                                          │
│                                                          │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │  nexus   │◄───│    setup     │    │  dev1 / dev2  │  │
│  │ :8081    │    │ (one-shot)   │    │  (lab devs)   │  │
│  └──────────┘    └──────────────┘    └───────────────┘  │
│       ▲                                     │            │
│       └─────────────────────────────────────┘            │
│              mise url_replacement                        │
└─────────────────────────────────────────────────────────┘
```

### Serviços

| Serviço | Imagem | Função |
|---------|--------|--------|
| `nexus` | `sonatype/nexus3` | Repositório de artefatos. Exposto em `localhost:8081`. |
| `setup` | Alpine (build local) | Provisiona o Nexus: cria repos, usuários, publica metadata e tarballs. Roda uma vez e encerra. |
| `dev1`, `dev2` | Ubuntu (build local) | Simula estações de desenvolvedores. mise instalado, Java obtido exclusivamente do Nexus. |

### Repositórios criados no Nexus

| Repositório | Conteúdo |
|-------------|----------|
| `mise-java` | JSON de metadata no formato do mise (`jvm/ga/linux/{x86_64,aarch64}.json`) |
| `corretto-local` | Tarballs do Amazon Corretto 8, 17 e 21 |

---

## Pré-requisitos

- Docker e Docker Compose (v2 recomendado)
- ~3 GB livres em disco (tarballs do Corretto)
- Acesso à internet apenas para o passo de download inicial

---

## Como rodar

### 1. Clone o repositório e configure o ambiente

```bash
cp .env.example .env
```

Edite o `.env` conforme necessário (as senhas padrão funcionam para o lab):

```env
NEXUS_ADMIN_PASSWORD=admin123

DEV1_PASSWORD=dev1pass
DEV2_PASSWORD=dev2pass

CORRETTO_8=8.492.09.1
CORRETTO_17=17.0.19.10.1
CORRETTO_21=21.0.11.10.1
```

> **Atenção:** O arquivo `.env` está no `.gitignore` e não é versionado. Nunca comite credenciais.

---

### 2. Baixe os tarballs do Corretto

Este é o único passo que requer acesso à internet. Os arquivos são baixados para `downloads/` e ficam disponíveis offline para o Nexus.

```bash
./setup/download-corretto.sh
```

O script baixa 6 arquivos (Corretto 8, 17 e 21 para `linux-x64` e `linux-aarch64`) e pula os que já existem. Tamanho total: ~900 MB.

---

### 3. Suba o stack completo

```bash
docker-compose up --build
```

O Docker Compose executa os serviços na ordem correta:

1. **nexus** — sobe e aguarda o healthcheck (`/service/rest/v1/status/writable`)
2. **setup** — executa o pipeline de provisionamento (detalhado abaixo) e encerra com código 0
3. **dev1**, **dev2** — sobem após o setup completar com sucesso

Para verificar que o setup concluiu corretamente:

```bash
docker-compose logs setup
```

A última linha deve ser `Setup concluido.`

---

### 4. Acesse os containers de desenvolvimento

Em terminais separados:

```bash
docker-compose exec dev1 /bin/bash
docker-compose exec dev2 /bin/bash
```

Ou rode o script de validação diretamente:

```bash
docker-compose exec dev1 /workspace/test-java.sh
```

---

### 5. Verifique a interface do Nexus (opcional)

Acesse `http://localhost:8081` com as credenciais:

- **Usuário:** `admin` / **Senha:** `NEXUS_ADMIN_PASSWORD`
- **Desenvolvedores:** `dev1` / `DEV1_PASSWORD`, `dev2` / `DEV2_PASSWORD`

---

## O que o container `setup` faz

O pipeline é executado pelos scripts em `setup/`, orquestrados por `configure.sh`:

```
[1/6] Aguarda Nexus ficar saudável
[2/6] Configura senha do admin
        └─ lê /nexus-data/admin.password (senha inicial gerada pelo Nexus)
        └─ troca pela senha definida em NEXUS_ADMIN_PASSWORD
[3/6] Aceita a EULA do Nexus Community Edition
        └─ obrigatório na versão 3.70+; sem isso todos os uploads retornam 403
[4/6] Desabilita acesso anônimo
[5/6] Cria os repositórios mise-java e corretto-local
[6/6] Cria a role developers e os usuários dev1/dev2

[sem número] Gera e publica o metadata JVM em mise-java
[sem número] Publica os tarballs Corretto em corretto-local
```

Todos os passos são **idempotentes**: rodar o setup duas vezes não gera erro.

---

## Como o `mise` funciona nos containers dev

O `entrypoint.sh` configura dois mecanismos antes de qualquer comando:

**1. Credenciais via `.netrc`**

```
machine nexus
login dev1
password dev1pass
```

O mise usa as credenciais do `.netrc` automaticamente ao fazer requests HTTP ao Nexus.

**2. Redirecionamento de URL via mise**

```toml
# ~/.config/mise/config.toml
[settings.url_replacements]
"https://mise-java.jdx.dev" = "http://nexus:8081/repository/mise-java"
```

Quando o desenvolvedor executa `mise install java@corretto-21.0.11.10.1`, o mise:

1. Busca o metadata em `https://mise-java.jdx.dev/jvm/ga/linux/x86_64.json` → redirecionado para o Nexus
2. Lê a URL do tarball no metadata — que já aponta para `http://nexus:8081/repository/corretto-local/...`
3. Faz o download do Nexus sem tocar na internet

O acesso direto a `mise-java.jdx.dev` é bloqueado via `/etc/hosts` (`127.0.0.1`) para simular o ambiente sem internet.

---

## Estrutura do projeto

```
lab-mise/
├── .env.example              # Template de variáveis de ambiente
├── .gitignore
├── docker-compose.yml        # Orquestração dos serviços
│
├── downloads/                # Tarballs do Corretto (gitignored)
│   └── .gitkeep
│
├── setup/
│   ├── Dockerfile            # Imagem Alpine com curl e jq
│   ├── configure.sh          # Orquestrador do pipeline de setup
│   ├── step-auth.sh          # [1-4/6] Auth, EULA, acesso anônimo
│   ├── step-repos.sh         # [5/6] Criação de repositórios
│   ├── step-users.sh         # [6/6] Role e usuários
│   ├── step-metadata.sh      # Publicação do metadata JVM
│   ├── step-tarballs.sh      # Publicação dos tarballs
│   └── download-corretto.sh  # Helper: baixa tarballs do Corretto
│
└── dev/
    ├── Dockerfile            # Imagem Ubuntu com mise
    ├── entrypoint.sh         # Configura .netrc e url_replacements
    ├── test-java.sh          # Valida instalação das 3 versões Java
    └── .mise.toml            # Configuração do mise (sem ferramentas fixas)
```

---

## Re-executar o setup

Se precisar re-provisionar o Nexus (ex: após apagar o volume):

```bash
# Remove o container de setup para que o compose o recrie
docker-compose rm -f setup

# Sobe tudo novamente
docker-compose up --build
```

Para resetar completamente (apaga todos os dados do Nexus):

```bash
docker-compose down -v
docker-compose up --build
```

---

## Variáveis de ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `NEXUS_ADMIN_PASSWORD` | — | Senha do usuário `admin` no Nexus |
| `DEV1_PASSWORD` | `dev1pass` | Senha do usuário `dev1` |
| `DEV2_PASSWORD` | `dev2pass` | Senha do usuário `dev2` |
| `CORRETTO_8` | `8.492.09.1` | Versão do Corretto 8 a provisionar |
| `CORRETTO_17` | `17.0.19.10.1` | Versão do Corretto 17 a provisionar |
| `CORRETTO_21` | `21.0.11.10.1` | Versão do Corretto 21 a provisionar |
