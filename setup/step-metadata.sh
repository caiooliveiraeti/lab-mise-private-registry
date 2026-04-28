#!/usr/bin/env sh
set -eu

: "${AUTH:?AUTH nao configurado — execute via configure.sh ou exporte AUTH}"
: "${NEXUS_URL:?NEXUS_URL nao configurado}"
: "${CORRETTO_8:?CORRETTO_8 nao configurado}"
: "${CORRETTO_17:?CORRETTO_17 nao configurado}"
: "${CORRETTO_21:?CORRETTO_21 nao configurado}"

echo "==> Gerando e publicando metadata mise-java..."

make_entry() {
  version="$1" arch_suffix="$2" checksum="$3"
  printf '{"checksum":"%s","created_at":"2025-01-01T00:00:00.000000","features":[],"file_type":"tar.gz","image_type":"jdk","java_version":"%s","jvm_impl":"hotspot","url":"%s/repository/corretto-local/%s/amazon-corretto-%s-%s.tar.gz","vendor":"corretto","version":"%s"}' \
    "${checksum}" "${version}" "${NEXUS_URL}" "${version}" "${version}" "${arch_suffix}" "${version}"
}

for arch_suffix in "linux-x64" "linux-aarch64"; do
  case "${arch_suffix}" in
    linux-x64)     nexus_arch="x86_64"  ;;
    linux-aarch64) nexus_arch="aarch64" ;;
  esac

  entries=""
  for version in "${CORRETTO_8}" "${CORRETTO_17}" "${CORRETTO_21}"; do
    tarball="/downloads/amazon-corretto-${version}-${arch_suffix}.tar.gz"
    if [ ! -f "${tarball}" ]; then
      echo "  AVISO: ${tarball} nao encontrado, checksum vazio"
      checksum=""
    else
      checksum="sha256:$(sha256sum "${tarball}" | cut -d' ' -f1)"
    fi
    entry=$(make_entry "${version}" "${arch_suffix}" "${checksum}")
    entries="${entries:+${entries},}${entry}"
  done

  body=$(printf '[%s]' "${entries}")
  curl -s -u "${AUTH}" \
    -X PUT "${NEXUS_URL}/repository/mise-java/jvm/ga/linux/${nexus_arch}.json" \
    -H "Content-Type: application/json" \
    -d "${body}" -o /dev/null -w "  jvm/ga/linux/${nexus_arch}.json: %{http_code}\n"
done
