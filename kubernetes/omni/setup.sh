#!/bin/bash

SECRET_DIR="/opt/workdir/caas/omni/secrets"
ETCD_GPG_EMAIL="omni@internal.local"

if ! command -v gpg &> /dev/null; then
  echo "Error: gpg is not installed. Please install GPG to generate keys."
  exit 1
fi

if [[ ! -d "$SECRET_DIR" ]]; then
  echo "Creating directory: $SECRET_DIR"
  mkdir -p "$SECRET_DIR"
fi

if [[ -f "$SECRET_DIR/omni.asc" ]]; then
  echo "omni.asc already exists. Skipping key generation."
else
  echo "Generating GPG key pair for omni.asc..."

  if gpg --list-keys "$ETCD_GPG_EMAIL" &> /dev/null; then
    echo "GPG key for $ETCD_GPG_EMAIL already exists..."
  else
    echo "No existing GPG key found for $ETCD_GPG_EMAIL. Generating new key..."

    gpg --batch --passphrase '' \
      --quick-generate-key \
      "Omni (Used for etcd data encryption) $ETCD_GPG_EMAIL" \
      rsa4096 cert never
  fi

  if gpg --list-secret-keys "$ETCD_GPG_EMAIL" &> /dev/null; then
    echo "GPG private key for $ETCD_GPG_EMAIL already exists..."
  else

    FINGERPRINT=$(gpg --with-colons --list-keys "$ETCD_GPG_EMAIL" \
      | awk -F: '$1 == "fpr" {print $10; exit}')

    gpg --batch --passphrase '' \
      --quick-add-key ${FINGERPRINT} rsa4096 encr never

    gpg --export-secret-key --armor "$ETCD_GPG_EMAIL" > "$SECRET_DIR/omni.asc"
  fi

fi
