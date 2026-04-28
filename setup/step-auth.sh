# Aguarda Nexus, configura senha admin, desabilita acesso anônimo.
# Deve ser SOURCED (. step-auth.sh) para exportar AUTH ao shell pai.
#
# Requer: NEXUS_URL, ADMIN_PASS
# Exporta: AUTH

echo "==> [1/5] Aguardando Nexus..."
i=0
until [ "$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' "${NEXUS_URL}/service/rest/v1/status/writable")" = "200" ]; do
  i=$((i+1))
  [ $i -ge 60 ] && echo "  ERRO: timeout (10 min)" && exit 1
  echo "  [${i}/60] aguardando..."
  sleep 10
done
echo "  Nexus respondendo."

echo "==> [2/5] Configurando autenticacao admin..."
if curl -sf -u "admin:${ADMIN_PASS}" \
    "${NEXUS_URL}/service/rest/v1/security/users" -o /dev/null 2>/dev/null; then
  echo "  Senha ja configurada."
  export AUTH="admin:${ADMIN_PASS}"
elif [ -f /nexus-data/admin.password ]; then
  INITIAL_PASS=$(cat /nexus-data/admin.password)
  echo "  Alterando senha inicial..."
  http_code=$(curl -s -u "admin:${INITIAL_PASS}" -X PUT \
    "${NEXUS_URL}/service/rest/v1/security/users/admin/change-password" \
    -H "Content-Type: text/plain" \
    -d "${ADMIN_PASS}" \
    -o /dev/null -w "%{http_code}" 2>/dev/null || true)
  echo "  change-password: ${http_code}"
  if [ "${http_code}" != "204" ]; then
    echo "  ERRO: falha ao alterar senha (${http_code})"
    exit 1
  fi
  export AUTH="admin:${ADMIN_PASS}"
else
  echo "  ERRO: nao foi possivel autenticar como admin"
  exit 1
fi

echo "==> [3/5] Aceitando EULA..."
EULA_DISCLAIMER="Use of Sonatype Nexus Repository - Community Edition is governed by the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula. By returning the value from ‘accepted:false’ to ‘accepted:true’, you acknowledge that you have read and agree to the End User License Agreement at https://links.sonatype.com/products/nxrm/ce-eula."
eula_code=$(curl -s -u "${AUTH}" -X POST \
  "${NEXUS_URL}/service/rest/v1/system/eula" \
  -H "Content-Type: application/json" \
  -d "{\"accepted\":true,\"disclaimer\":\"${EULA_DISCLAIMER}\"}" \
  -o /dev/null -w "%{http_code}" || true)
echo "  eula: ${eula_code}"

echo "==> [4/5] Desabilitando acesso anonimo..."
anon_code=$(curl -s -u "${AUTH}" -X PUT \
  "${NEXUS_URL}/service/rest/v1/security/anonymous" \
  -H "Content-Type: application/json" \
  -d ‘{"enabled":false,"userId":"anonymous","realmName":"NexusAuthorizingRealm"}’ \
  -o /dev/null -w "%{http_code}" || true)
echo "  anonymous: ${anon_code}"