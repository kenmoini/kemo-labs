#!/bin/bash
set -e

# =============================================================================
# MariaDB Init Script
# =============================================================================
# Creates databases and users for all downstream services.
# Runs only on first boot (when the data volume is empty).
#
# Uses shell env vars for password injection (unlike .sql files).
# =============================================================================

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL

    -- PowerDNS Authoritative database
    CREATE DATABASE IF NOT EXISTS powerdns_auth
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    -- GitLab database
    CREATE DATABASE IF NOT EXISTS gitlab
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    -- Mailcow database
    CREATE DATABASE IF NOT EXISTS mailcow
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    -- PowerDNS Authoritative user
    CREATE USER IF NOT EXISTS 'powerdns_auth'@'%' IDENTIFIED BY '${MYSQL_POWERDNS_AUTH_PASSWORD}';
    GRANT ALL PRIVILEGES ON powerdns_auth.* TO 'powerdns_auth'@'%';

    -- GitLab user
    CREATE USER IF NOT EXISTS 'gitlab'@'%' IDENTIFIED BY '${MYSQL_GITLAB_PASSWORD}';
    GRANT ALL PRIVILEGES ON gitlab.* TO 'gitlab'@'%';

    -- Mailcow user
    CREATE USER IF NOT EXISTS 'mailcow'@'%' IDENTIFIED BY '${MYSQL_MAILCOW_PASSWORD}';
    GRANT ALL PRIVILEGES ON mailcow.* TO 'mailcow'@'%';

    FLUSH PRIVILEGES;

EOSQL

echo "=== MariaDB init complete: powerdns_auth, gitlab, and mailcow databases and users created ==="
