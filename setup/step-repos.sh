#!/usr/bin/env sh
set -eu

: "${AUTH:?AUTH nao configurado — execute via configure.sh ou exporte AUTH}"
: "${NEXUS_URL:?NEXUS_URL nao configurado}"

echo "==> [5/6] Criando repositorios..."
for repo in mise-java corretto-local; do
  code=$(curl -s -u "${AUTH}" -X POST \
    "${NEXUS_URL}/service/rest/v1/repositories/raw/hosted" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${repo}\",\"online\":true,\"storage\":{\"blobStoreName\":\"default\",\"strictContentTypeValidation\":false,\"writePolicy\":\"ALLOW\"}}" \
    -o /dev/null -w "%{http_code}")
  # 201 = criado, 400 = ja existe
  echo "  ${repo}: ${code}"
done
