#\!/usr/bin/env bash
set -euo pipefail

# Mailcow Deployment Setup Script
# This script clones the mailcow-dockerized repo, generates configuration,
# and creates the necessary overrides for this homelab environment.

MAILCOW_HOSTNAME="mail.lab.kemo.dev"
MAILCOW_TZ="America/New_York"
MAILCOW_IP="192.168.62.80"
STEPCA_ACME_URL="https://stepca.lab.kemo.dev:9000/acme/acme/directory"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mailcow-dockerized"

echo "=== Mailcow Deployment Setup ==="
echo ""

# -------------------------------------------------------
# Step 1: Clone mailcow-dockerized
# -------------------------------------------------------
if [ -d "$INSTALL_DIR" ]; then
    echo "[INFO] mailcow-dockerized directory already exists at $INSTALL_DIR"
    echo "[INFO] Pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull
else
    echo "[INFO] Cloning mailcow-dockerized..."
    git clone https://github.com/mailcow/mailcow-dockerized.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# -------------------------------------------------------
# Step 2: Run generate_config.sh
# -------------------------------------------------------
echo ""
echo "[INFO] Running generate_config.sh..."
echo "[INFO] When prompted:"
echo "  - Hostname: ${MAILCOW_HOSTNAME}"
echo "  - Timezone: ${MAILCOW_TZ}"
echo "  - Accept defaults for other options"
echo ""

if [ \! -f mailcow.conf ]; then
    ./generate_config.sh
else
    echo "[INFO] mailcow.conf already exists, skipping generate_config.sh"
    echo "[INFO] Delete mailcow.conf and re-run this script to regenerate."
fi

# -------------------------------------------------------
# Step 3: Patch mailcow.conf with lab-specific settings
# -------------------------------------------------------
echo ""
echo "[INFO] Applying lab-specific settings to mailcow.conf..."

# Skip Let's Encrypt -- we use StepCA
sed -i 's/^SKIP_LETS_ENCRYPT=.*/SKIP_LETS_ENCRYPT=y/' mailcow.conf

# Set ACME directory to StepCA
if grep -q "^DIRECTORY_URL=" mailcow.conf; then
    sed -i "s|^DIRECTORY_URL=.*|DIRECTORY_URL=${STEPCA_ACME_URL}|" mailcow.conf
else
    echo "DIRECTORY_URL=${STEPCA_ACME_URL}" >> mailcow.conf
fi

# Bind HTTP/S to the static IP
sed -i "s/^HTTP_BIND=.*/HTTP_BIND=${MAILCOW_IP}/" mailcow.conf
sed -i "s/^HTTPS_BIND=.*/HTTPS_BIND=${MAILCOW_IP}/" mailcow.conf

# Additional SANs for autodiscover/autoconfig
sed -i 's/^ADDITIONAL_SAN=.*/ADDITIONAL_SAN=imap.*,smtp.*,autodiscover.*,autoconfig.*/' mailcow.conf

# Enable watchdog
sed -i 's/^USE_WATCHDOG=.*/USE_WATCHDOG=y/' mailcow.conf

# Enable ClamAV (we have plenty of RAM)
sed -i 's/^SKIP_CLAMD=.*/SKIP_CLAMD=n/' mailcow.conf

echo "[OK] mailcow.conf updated."

# -------------------------------------------------------
# Step 4: Create docker-compose.override.yml
# -------------------------------------------------------
echo ""
echo "[INFO] Creating docker-compose.override.yml for IP binding..."

cat > docker-compose.override.yml << 'EOF'
# Mailcow Docker Compose Override
# Binds all external ports to the dedicated static IP 192.168.62.80

services:
  postfix-mailcow:
    ports:
      - "192.168.62.80:25:25"
      - "192.168.62.80:465:465"
      - "192.168.62.80:587:587"

  dovecot-mailcow:
    ports:
      - "192.168.62.80:143:143"
      - "192.168.62.80:993:993"
      - "192.168.62.80:110:110"
      - "192.168.62.80:995:995"
      - "192.168.62.80:4190:4190"

  nginx-mailcow:
    ports:
      - "192.168.62.80:80:80"
      - "192.168.62.80:443:443"
EOF

echo "[OK] docker-compose.override.yml created."

# -------------------------------------------------------
# Step 5: Summary and DNS Notes
# -------------------------------------------------------
echo ""
echo "==========================================="
echo "  Mailcow Setup Complete"
echo "==========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Assign 192.168.62.80 as a secondary IP on the host:"
echo "   sudo ip addr add 192.168.62.80/23 dev <your-lan-interface>"
echo "   (or configure it permanently via NetworkManager/systemd-networkd)"
echo ""
echo "2. Disable host Postfix if running:"
echo "   sudo systemctl disable --now postfix"
echo ""
echo "3. Start mailcow:"
echo "   cd $INSTALL_DIR"
echo "   docker compose up -d"
echo ""
echo "4. Access the admin UI:"
echo "   https://mail.lab.kemo.dev"
echo "   Default login: admin / moohoo (CHANGE IMMEDIATELY)"
echo ""
echo "5. Configure the following DNS records:"
echo ""
echo "   ; A record for mail server"
echo "   mail.lab.kemo.dev.              IN A     192.168.62.80"
echo ""
echo "   ; MX record"
echo "   lab.kemo.dev.                   IN MX    10 mail.lab.kemo.dev."
echo ""
echo "   ; Autodiscover / Autoconfig"
echo "   autodiscover.lab.kemo.dev.      IN CNAME mail.lab.kemo.dev."
echo "   autoconfig.lab.kemo.dev.        IN CNAME mail.lab.kemo.dev."
echo ""
echo "   ; SPF"
echo "   lab.kemo.dev.                   IN TXT   \"v=spf1 mx a:mail.lab.kemo.dev -all\""
echo ""
echo "   ; DKIM (generated after first run -- get from Mailcow admin UI)"
echo "   ; dkim._domainkey.lab.kemo.dev. IN TXT   \"v=DKIM1; k=rsa; p=...\""
echo ""
echo "   ; DMARC"
echo "   _dmarc.lab.kemo.dev.            IN TXT   \"v=DMARC1; p=quarantine; rua=mailto:postmaster@lab.kemo.dev\""
echo ""
echo "   ; Reverse DNS (PTR) -- set at your ISP/hosting provider"
echo "   ; 80.62.168.192.in-addr.arpa.       IN PTR   mail.lab.kemo.dev."
echo ""
echo "6. After first run, generate DKIM keys from the Mailcow admin UI"
echo "   (Configuration -> ARC/DKIM keys) and add the TXT record to DNS."
echo ""
