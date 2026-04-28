#!/usr/bin/env sh
set -eu

: "${AUTH:?AUTH nao configurado — execute via configure.sh ou exporte AUTH}"
: "${NEXUS_URL:?NEXUS_URL nao configurado}"

ROLE_PAYLOAD='{"id":"developers","name":"developers","description":"Lab developers","privileges":["nx-repository-view-raw-mise-java-read","nx-repository-view-raw-mise-java-browse","nx-repository-view-raw-corretto-local-read","nx-repository-view-raw-corretto-local-browse"],"roles":[]}'

echo "==> [6/6] Criando role e usuarios..."

put_code=$(curl -s -u "${AUTH}" -X PUT \
  "${NEXUS_URL}/service/rest/v1/security/roles/developers" \
  -H "Content-Type: application/json" \
  -d "${ROLE_PAYLOAD}" \
  -o /dev/null -w "%{http_code}")
if [ "${put_code}" = "404" ]; then
  curl -s -u "${AUTH}" -X POST \
    "${NEXUS_URL}/service/rest/v1/security/roles" \
    -H "Content-Type: application/json" \
    -d "${ROLE_PAYLOAD}" \
    -o /dev/null -w "  developers (criado): %{http_code}\n"
else
  echo "  developers (atualizado): ${put_code}"
fi

for i in 1 2; do
  case $i in
    1) pass="${DEV1_PASSWORD:-dev1pass}" ;;
    2) pass="${DEV2_PASSWORD:-dev2pass}" ;;
  esac
  code=$(curl -s -u "${AUTH}" -X POST \
    "${NEXUS_URL}/service/rest/v1/security/users" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"dev${i}\",\"firstName\":\"Dev\",\"lastName\":\"${i}\",\"emailAddress\":\"dev${i}@lab.local\",\"password\":\"${pass}\",\"status\":\"active\",\"roles\":[\"developers\"]}" \
    -o /dev/null -w "%{http_code}" || true)
  echo "  dev${i}: ${code}"
done
