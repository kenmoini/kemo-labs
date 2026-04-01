# Mailcow - Full Email Stack

Mailcow is a fully-featured, self-hosted email server bundling Postfix (SMTP), Dovecot (IMAP), SOGo (webmail/calendar/contacts), ClamAV (antivirus), Rspamd (spam filtering), and a web admin UI. It manages ~15 containers internally and uses its own bundled MariaDB and Redis.

## Quick Start

```bash
# Clone the mailcow repository
git clone https://github.com/mailcow/mailcow-dockerized.git
cd mailcow-dockerized

# Generate configuration
./generate_config.sh
# Set MAILCOW_HOSTNAME=mail.lab.kemo.dev

# Edit mailcow.conf:
#   SKIP_LETS_ENCRYPT=y
#   HTTP_BIND=192.168.62.80
#   HTTPS_BIND=192.168.62.80

# Create docker-compose.override.yml for IP binding (see PLANNING.md)

# Or use the provided setup script:
# ./setup.sh

docker compose up -d
```

## Configuration

Mailcow uses `mailcow.conf` (not a standard `.env` file). Key settings:

| Setting | Purpose |
|---------|---------|
| `MAILCOW_HOSTNAME` | FQDN of the mail server (`mail.lab.kemo.dev`) |
| `SKIP_LETS_ENCRYPT` | Set to `y` (use StepCA instead) |
| `HTTP_BIND` / `HTTPS_BIND` | Bind to static IP `192.168.62.80` |
| `SKIP_CLAMD` | Set to `n` (enable antivirus with 128 GB+ RAM) |

## Access

| URL | Purpose |
|-----|---------|
| `https://mail.lab.kemo.dev` | Admin UI and SOGo webmail |
| `192.168.62.80:25/465/587` | SMTP |
| `192.168.62.80:143/993` | IMAP |

**Default credentials:** admin / moohoo (CHANGE IMMEDIATELY)

**Static IP:** 192.168.62.80

## Dependencies

- **DNS** -- MX, SPF, DKIM, DMARC records required (see PLANNING.md)
- All databases are **bundled** -- does NOT use shared PostgreSQL/Valkey

SMTP/IMAP ports bind directly to the host IP. They cannot be proxied through Traefik.

## Maintenance

```bash
# View logs
docker compose logs -f

# Update mailcow (use its built-in update script)
./update.sh

# Back up critical data:
# 1. vmail-vol-1 (all email data)
# 2. mysql-vol-1 (database)
# 3. crypt-vol-1 (encryption keys -- CRITICAL)
# 4. ./data/ directory (all configuration)

# Database dump
docker compose exec mysql-mailcow mysqldump --all-databases > backup.sql
```

Mailcow requires 6-10 GB RAM (ClamAV alone uses 2-3 GB). Disable Fedora's built-in Postfix (`systemctl disable postfix`) to avoid port conflicts. DKIM records are generated after first run -- add them to DNS.
