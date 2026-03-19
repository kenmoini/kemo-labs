#\!/usr/bin/env bash
set -euo pipefail

###############################################################################
# download-talos.sh
# Downloads the Talos Linux metal ISO and talosctl binary.
###############################################################################

TALOS_VERSION="${TALOS_VERSION:-v1.9.5}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_DIR="${SCRIPT_DIR}/_downloads"
ISO_DIR="/var/lib/libvirt/images"
ISO_FILENAME="talos-${TALOS_VERSION}-metal-amd64.iso"

echo "==> Talos version: ${TALOS_VERSION}"

mkdir -p "${DOWNLOAD_DIR}"

###############################################################################
# Download talosctl
###############################################################################
if command -v talosctl &>/dev/null; then
  CURRENT="$(talosctl version --client --short 2>/dev/null || true)"
  echo "==> talosctl already installed: ${CURRENT}"
else
  echo "==> Downloading talosctl ${TALOS_VERSION} ..."
  curl -fsSL -o "${DOWNLOAD_DIR}/talosctl" \
    "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-amd64"
  chmod +x "${DOWNLOAD_DIR}/talosctl"
  echo "    Installing to /usr/local/bin/talosctl (requires sudo)"
  sudo install -m 0755 "${DOWNLOAD_DIR}/talosctl" /usr/local/bin/talosctl
  echo "    talosctl installed: $(talosctl version --client --short 2>/dev/null)"
fi

###############################################################################
# Download Talos metal ISO
###############################################################################
if [ -f "${ISO_DIR}/${ISO_FILENAME}" ]; then
  echo "==> ISO already present at ${ISO_DIR}/${ISO_FILENAME}, skipping download."
else
  echo "==> Downloading Talos metal ISO ${TALOS_VERSION} ..."
  curl -fsSL -o "${DOWNLOAD_DIR}/${ISO_FILENAME}" \
    "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/metal-amd64.iso"

  echo "    Copying ISO to ${ISO_DIR}/ (requires sudo)"
  sudo cp "${DOWNLOAD_DIR}/${ISO_FILENAME}" "${ISO_DIR}/${ISO_FILENAME}"
  echo "    ISO ready at ${ISO_DIR}/${ISO_FILENAME}"
fi

echo ""
echo "==> Download complete."
echo "    ISO:      ${ISO_DIR}/${ISO_FILENAME}"
echo "    talosctl: $(command -v talosctl)"
