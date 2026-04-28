#!/usr/bin/env sh
set -eu

export NEXUS_URL="${NEXUS_URL:-http://nexus:8081}"
export ADMIN_PASS="${NEXUS_ADMIN_PASSWORD:-admin}"
export CORRETTO_8="${CORRETTO_8:-8.492.09.1}"
export CORRETTO_17="${CORRETTO_17:-17.0.19.10.1}"
export CORRETTO_21="${CORRETTO_21:-21.0.11.10.1}"

# auth.sh é sourced para que AUTH fique disponível como variável de ambiente
# para os scripts subsequentes executados como subprocessos
. /step-auth.sh

/step-repos.sh
/step-users.sh
/step-metadata.sh
/step-tarballs.sh

echo ""
echo "Setup concluido."
