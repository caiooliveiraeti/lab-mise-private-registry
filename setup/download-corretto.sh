#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

if [ -f "${ROOT_DIR}/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

CORRETTO_8="${CORRETTO_8:-8.492.09.1}"
CORRETTO_17="${CORRETTO_17:-17.0.19.10.1}"
CORRETTO_21="${CORRETTO_21:-21.0.11.10.1}"

mkdir -p "${ROOT_DIR}/downloads"

for version in "${CORRETTO_8}" "${CORRETTO_17}" "${CORRETTO_21}"; do
  for arch in linux-x64 linux-aarch64; do
    out="${ROOT_DIR}/downloads/amazon-corretto-${version}-${arch}.tar.gz"
    if [ -f "${out}" ]; then
      echo "Já existe: $(basename "${out}")"
      continue
    fi
    url="https://corretto.aws/downloads/resources/${version}/amazon-corretto-${version}-${arch}.tar.gz"
    echo "Baixando Corretto ${version} ${arch}..."
    curl -fL --progress-bar "${url}" -o "${out}"
    echo "  → $(du -sh "${out}" | cut -f1)"
  done
done

echo "Downloads concluídos em ${ROOT_DIR}/downloads/"
ls -lh "${ROOT_DIR}/downloads/"*.tar.gz
