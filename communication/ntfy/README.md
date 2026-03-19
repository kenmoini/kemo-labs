# Ntfy - Push Notification Service

Ntfy is a self-hosted HTTP-based pub-sub notification service. Services publish messages to topics via simple HTTP requests, and clients (mobile apps, browsers, scripts) subscribe to receive them in real time.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env

# Start the service
docker compose up -d

# Create an admin user for authentication
docker exec ntfy ntfy user add --role=admin admin

# Grant admin read-write access to all topics
docker exec ntfy ntfy access admin '*' rw

# Create a service account for publishing (optional)
docker exec ntfy ntfy user add publisher
docker exec ntfy ntfy access publisher '*' write-only
```

## Configuration

Configuration is managed via `server.yml`, not environment variables.

| Setting | File | Purpose |
|---------|------|---------|
| `base-url` | `server.yml` | External URL (`https://ntfy.lab.kemo.network`) |
| `auth-default-access` | `server.yml` | Default topic access (`deny-all` or `read-write`) |
| `cache-duration` | `server.yml` | How long messages are retained (default: `12h`) |
| `attachment-file-size-limit` | `server.yml` | Max attachment size (default: `15M`) |
| `TZ` | `.env` | Timezone |

## Access

| URL | Purpose |
|-----|---------|
| `https://ntfy.lab.kemo.network` | Web UI and API endpoint |

**Static IP:** 192.168.62.82

## Integration Examples

Services in the lab publish notifications to ntfy topics using HTTP POST/PUT:

```bash
# Uptime Kuma - configure ntfy as a notification provider
# Server URL: https://ntfy.lab.kemo.network
# Topic: uptime

# Grafana - add ntfy as a contact point (webhook type)
# URL: https://ntfy.lab.kemo.network/grafana

# Scrutiny - configure ntfy notifications for disk alerts
# Topic: disks

# WUD (What's Up Docker) - ntfy trigger for image updates
# Topic: docker-updates

# Home Assistant - via REST notifications
# Topic: homeassistant

# Manual test from command line
curl -u publisher:PASSWORD \
  -H "Title: Test Notification" \
  -H "Priority: default" \
  -H "Tags: test" \
  -d "This is a test message from the lab" \
  https://ntfy.lab.kemo.network/test
```

## Mobile App

Install the ntfy app (Android via F-Droid/Play Store, iOS via App Store) and add
the self-hosted server: `https://ntfy.lab.kemo.network`. Log in with your user
credentials, then subscribe to topics.

## Dependencies

- **Traefik** -- TLS termination via StepCA ACME
- No external database required (uses embedded SQLite)

## Maintenance

```bash
# View logs
docker compose logs -f ntfy

# Update image
docker compose pull && docker compose up -d

# List users
docker exec ntfy ntfy user list

# Add a user
docker exec ntfy ntfy user add USERNAME

# Grant topic access
docker exec ntfy ntfy access USERNAME TOPIC rw

# Change a user password
docker exec ntfy ntfy user change-pass USERNAME

# Health check
curl https://ntfy.lab.kemo.network/v1/health

# Back up auth database (if using authentication)
docker cp ntfy:/var/lib/ntfy/user.db ./user.db.bak
```

Ntfy uses roughly 64MB of RAM and minimal CPU. The message cache is ephemeral
and auto-expires. The only file worth backing up is the auth database if user
accounts have been configured.
