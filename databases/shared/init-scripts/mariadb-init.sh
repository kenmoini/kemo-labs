#\!/bin/bash
set -e

# =============================================================================
# MariaDB Init Script
# =============================================================================
# Creates databases and users for all downstream services.
# Runs only on first boot (when the data volume is empty).
#
# Uses shell env vars for password injection (unlike .sql files).
# =============================================================================

mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<-EOSQL

    -- GitLab database
    CREATE DATABASE IF NOT EXISTS gitlab
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    -- Mailcow database
    CREATE DATABASE IF NOT EXISTS mailcow
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;

    -- GitLab user
    CREATE USER IF NOT EXISTS 'gitlab'@'%' IDENTIFIED BY '${MARIADB_GITLAB_PASSWORD}';
    GRANT ALL PRIVILEGES ON gitlab.* TO 'gitlab'@'%';

    -- Mailcow user
    CREATE USER IF NOT EXISTS 'mailcow'@'%' IDENTIFIED BY '${MARIADB_MAILCOW_PASSWORD}';
    GRANT ALL PRIVILEGES ON mailcow.* TO 'mailcow'@'%';

    FLUSH PRIVILEGES;

EOSQL

echo "=== MariaDB init complete: gitlab and mailcow databases and users created ==="
