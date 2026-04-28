#!/usr/bin/env bash
set -euo pipefail

# Credenciais para o Nexus (usadas pelo mise via .netrc)
cat > ~/.netrc << EOF
machine nexus
login ${NEXUS_USER}
password ${NEXUS_PASSWORD}
EOF
chmod 600 ~/.netrc

# URL replacements no config global do mise para valer em qualquer diretório
mkdir -p ~/.config/mise
cat > ~/.config/mise/config.toml << 'EOF'
[settings.url_replacements]
"https://mise-java.jdx.dev" = "http://nexus:8081/repository/mise-java"
EOF

# Bloqueia acesso direto à origem — tráfego deve passar pelo Nexus via mise url_replacements
cat >> /etc/hosts << 'EOF'
127.0.0.1 mise-java.jdx.dev
EOF

exec "$@"
