# Draw.io - Diagramming Tool

## Overview

Draw.io (diagrams.net) is an open-source diagramming application for creating flowcharts, network diagrams, UML diagrams, architecture diagrams, and more. It runs entirely in the browser with optional server-side export capabilities. In this homelab, Draw.io provides a self-hosted diagramming tool with no external cloud dependencies.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| Draw.io | `docker.io/jgraph/drawio` | `latest` |

The image is based on `tomcat:9-jre11-openjdk-slim`. A single container serves both the web UI and the application.

**Note**: An optional export server image (`jgraph/export-server`) exists for server-side PDF/image export, but the base image handles most use cases.

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | TCP | HTTP web UI |
| 8443 | TCP | HTTPS web UI (self-signed, not needed behind Traefik) |

Only port 8080 is needed when running behind Traefik for TLS termination.

## Environment Variables

| Variable | Description | Default | Recommended |
|----------|-------------|---------|-------------|
| `LETS_ENCRYPT_ENABLED` | Enable Let's Encrypt | `false` | `false` (Traefik handles TLS) |
| `PUBLIC_DNS` | DNS name for certificate CN | `draw.example.com` | `drawio.lab.kemo.dev` |
| `DRAWIO_SELF_CONTAINED` | Run without external dependencies | (unset) | `1` |
| `DRAWIO_BASE_URL` | Base URL for the application | (auto) | `https://drawio.lab.kemo.dev` |

### Optional DRAWIO_* Configuration Variables

Draw.io supports various `DRAWIO_*` environment variables configured via `docker-entrypoint.sh`:

| Variable | Description |
|----------|-------------|
| `DRAWIO_GOOGLE_CLIENT_ID` | Google Drive integration client ID |
| `DRAWIO_GOOGLE_APP_ID` | Google Drive app ID |
| `DRAWIO_MSFT_CLIENT_ID` | OneDrive integration client ID |
| `DRAWIO_GITLAB_ID` | GitLab integration client ID |
| `DRAWIO_GITLAB_URL` | GitLab server URL |
| `DRAWIO_CLOUD_CONVERT_APIKEY` | CloudConvert API key for file conversion |
| `DRAWIO_CACHE_DOMAIN` | Custom cache domain |
| `DRAWIO_VIEWER_URL` | Custom viewer URL |
| `DRAWIO_LIGHTBOX_URL` | Custom lightbox URL |
| `DRAWIO_CONFIG` | JSON string for custom configuration |
| `DRAWIO_CSP_HEADER` | Custom Content-Security-Policy header |

For a fully self-contained offline instance, most integrations should remain disabled.

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| None required | - | Draw.io is stateless | 0 |

Draw.io is a **stateless application**. All diagram data is stored client-side (browser local storage) or saved to external storage (Git, cloud, or downloaded as files). No server-side persistent storage is needed.

## Resource Estimates

| Service | CPU | Memory | Notes |
|---------|-----|--------|-------|
| Draw.io (Tomcat) | 0.5-1 core | 512 MB - 1 GB | Tomcat/Java overhead; mostly static file serving |
| **Total** | **0.5-1 core** | **512 MB - 1 GB** | Very lightweight workload |

The `-m1g` memory limit is recommended by the upstream documentation.

## Dependencies

### Shared Services

| Service | Purpose | Details |
|---------|---------|---------|
| Traefik | Reverse proxy + TLS | Routes `drawio.lab.kemo.dev` with StepCA ACME certificate |

Draw.io has **no database or cache dependencies**. It is entirely self-contained.

### Optional Integrations

- **GitLab/Gitea** - Save diagrams directly to Git repositories via `DRAWIO_GITLAB_*` env vars
- **Export Server** - `jgraph/export-server` for enhanced server-side PDF/image export

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.62.52` |
| DNS Zone | `lab.kemo.dev` |
| FQDN | `drawio.lab.kemo.dev` |
| Container Network | `lab-network` (macvlan/bridge) |
| Subnet | `192.168.62.0/23` |

### Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.drawio.rule=Host(`drawio.lab.kemo.dev`)"
  - "traefik.http.routers.drawio.entrypoints=websecure"
  - "traefik.http.routers.drawio.tls=true"
  - "traefik.http.routers.drawio.tls.certresolver=step-ca"
  - "traefik.http.services.drawio.loadbalancer.server.port=8080"
```

## Special Considerations

1. **Stateless by Design**: Draw.io does not persist any data on the server. Users save diagrams locally, to Git, or to cloud storage. This simplifies backup and disaster recovery -- there is nothing to back up on the server side.

2. **Offline Mode**: Access the application with `?offline=1&https=0` query parameters to disable all cloud storage features. For a fully air-gapped deployment, set `DRAWIO_SELF_CONTAINED=1`.

3. **Security - Content Security Policy**: The default CSP allows connections to diagrams.net services. For a locked-down deployment, set `DRAWIO_CSP_HEADER` to restrict external connections.

4. **Memory Limit**: The upstream recommends running with a 1 GB memory limit (`-m1g`). The Java/Tomcat runtime benefits from a defined memory ceiling.

5. **No Authentication**: Draw.io does not have built-in user authentication. If access control is needed, use Traefik middleware (basic auth, forward auth with Keycloak/Authentik, or IP allowlists).

6. **TLS Handling**: Since Traefik terminates TLS, disable the built-in Let's Encrypt (`LETS_ENCRYPT_ENABLED=false`) and only expose port 8080. Do not expose port 8443 externally.

7. **Export Capabilities**: The base image supports client-side export to PNG, SVG, and XML. For server-side PDF export (headless rendering), deploy the companion `jgraph/export-server` container alongside and configure Draw.io to use it.

8. **PlantUML Support**: For UML diagram generation, a PlantUML server can be deployed alongside. The upstream provides a compose file for this configuration.

9. **Lightweight Deployment**: This is the simplest workload in the documentation stack -- single container, no volumes, no databases. It can be started and replaced with zero data migration concerns.
