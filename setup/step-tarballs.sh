#!/usr/bin/env sh
set -eu

: "${AUTH:?AUTH nao configurado — execute via configure.sh ou exporte AUTH}"
: "${NEXUS_URL:?NEXUS_URL nao configurado}"

echo "==> Publicando tarballs Corretto..."

found=0
for f in /downloads/*.tar.gz; do
  [ -f "${f}" ] || continue
  found=1
  filename=$(basename "${f}")
  version=$(echo "${filename}" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)+' | head -1)
  if [ -z "${version}" ]; then
    echo "  AVISO: versao nao encontrada em ${filename}, ignorando"
    continue
  fi
  echo "  ${filename} (${version})..."
  curl -s -u "${AUTH}" \
    -X PUT "${NEXUS_URL}/repository/corretto-local/${version}/${filename}" \
    -H "Content-Type: application/octet-stream" \
    -T "${f}" -o /dev/null -w "  -> %{http_code}\n"
done

if [ "${found}" = "0" ]; then
  echo "  ERRO: nenhum tarball em /downloads/. Rode setup/download-corretto.sh primeiro."
  exit 1
fi
