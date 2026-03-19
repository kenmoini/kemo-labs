-- =============================================================================
-- MariaDB Init Script
-- =============================================================================
-- Creates databases and users for all downstream services.
-- Runs only on first boot (when the data volume is empty).
--
-- NOTE: This .sql file cannot perform env var substitution for passwords.
-- The databases are created here. Users are created with placeholder passwords
-- that MUST be updated after first boot. See the companion note below.
--
-- To update passwords after first boot:
--   docker exec -i shared-mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" \
--     -e "ALTER USER 'gitlab'@'%' IDENTIFIED BY 'REAL_PASSWORD';"
--   docker exec -i shared-mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" \
--     -e "ALTER USER 'mailcow'@'%' IDENTIFIED BY 'REAL_PASSWORD';"
-- =============================================================================

-- GitLab database
CREATE DATABASE IF NOT EXISTS gitlab
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Mailcow database
CREATE DATABASE IF NOT EXISTS mailcow
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- GitLab user (password must be updated after first boot)
CREATE USER IF NOT EXISTS 'gitlab'@'%' IDENTIFIED BY 'changeme_gitlab';
GRANT ALL PRIVILEGES ON gitlab.* TO 'gitlab'@'%';

-- Mailcow user (password must be updated after first boot)
CREATE USER IF NOT EXISTS 'mailcow'@'%' IDENTIFIED BY 'changeme_mailcow';
GRANT ALL PRIVILEGES ON mailcow.* TO 'mailcow'@'%';

FLUSH PRIVILEGES;
