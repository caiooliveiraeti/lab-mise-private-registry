#!/usr/bin/env bash
set -euo pipefail

# Necessário em scripts não-interativos: ~/.bashrc não é carregado automaticamente
eval "$(mise activate bash)"

echo "========================================"
echo " mise + Nexus OSS — usuário: ${NEXUS_USER}"
echo "========================================"
echo ""

# ── Instalação via mise (mostra URLs substituídas) ────────────────────────────
for version in "${CORRETTO_8}" "${CORRETTO_17}" "${CORRETTO_21}"; do
  echo "----------------------------------------"
  echo " Instalando java@corretto-${version}"
  echo "----------------------------------------"
  mise_log=$(MISE_LOG_LEVEL=debug mise install "java@corretto-${version}" 2>&1)
  echo "${mise_log}" | grep -E '(Downloading|http://nexus|url_replacement|installing|installed)' || true
  "$(mise where "java@corretto-${version}")/bin/java" -version
  echo ""
done

echo "========================================"
echo " Versões instaladas"
echo "========================================"
mise list java
