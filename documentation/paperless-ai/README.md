# Paperless-AI - AI-Powered Document Processing

Paperless-AI extends Paperless-NGX with automatic document classification, smart tagging, and a RAG-based chat interface. It uses LLM providers (Ollama, OpenAI, or any OpenAI-compatible API) to analyze document content and assign titles, tags, document types, and correspondents.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set PAPERLESS_API_TOKEN (from Paperless-NGX admin),
#   AI_PROVIDER, OLLAMA_MODEL or OPENAI_API_KEY

docker compose up -d

# Complete initial setup wizard at:
# https://paperless-ai.lab.kemo.dev
# Then restart container to build RAG index
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `PAPERLESS_API_URL` | Paperless-NGX API endpoint |
| `PAPERLESS_API_TOKEN` | API token from Paperless-NGX admin panel |
| `AI_PROVIDER` | Backend: `ollama`, `openai`, or `custom` |
| `OLLAMA_API_URL` | Ollama endpoint (default: `http://192.168.62.70:11434`) |
| `OLLAMA_MODEL` | Model name (default: `llama3.2`) |
| `SCAN_INTERVAL` | Cron schedule for scanning new documents (default: `*/30 * * * *`) |
| `TAGS` | Tag(s) that trigger processing (default: `pre-process`) |

## Access

| URL | Purpose |
|-----|---------|
| `https://paperless-ai.lab.kemo.dev` | Configuration UI and RAG chat |

**Static IP:** 192.168.62.54

## Dependencies

- **Paperless-NGX** -- must be running with a valid API token
- **AI Provider** -- Ollama (local), OpenAI, or OpenAI-compatible API
- **Traefik** -- reverse proxy with TLS

No PostgreSQL or Valkey required -- uses internal SQLite and file-based RAG index.

## Maintenance

```bash
# View logs
docker compose logs -f paperless-ai

# Update image
docker compose pull && docker compose up -d

# Rebuild RAG index (restart container after setup)
docker compose restart paperless-ai

# Back up data volume (contains RAG index and config)
```

Deploy Paperless-NGX first, create an API token, then configure Paperless-AI. The recommended workflow: tag documents with `pre-process` in Paperless-NGX, and Paperless-AI picks them up automatically. Has no built-in authentication -- protect with Traefik middleware.
