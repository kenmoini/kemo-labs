# Open WebUI + Ollama - LLM Chat Interface

Open WebUI provides a ChatGPT-like web interface for interacting with Large Language Models. It connects to a co-deployed Ollama instance for local/private inference and optionally to remote API providers (OpenAI, Anthropic).

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set WEBUI_SECRET_KEY

docker compose up -d

# First user to register becomes the admin
# Access at: https://open-webui.lab.kemo.network

# Pull a model
docker exec ollama ollama pull llama3.1:8b
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `WEBUI_SECRET_KEY` | Session signing secret (set to strong random value) |
| `OLLAMA_BASE_URL` | Ollama API URL (default: `http://ollama:11434`) |
| `OPENAI_API_BASE_URL` | Optional remote OpenAI-compatible API |
| `OPENAI_API_KEY` | API key for remote provider |

## Access

| URL | Purpose |
|-----|---------|
| `https://open-webui.lab.kemo.network` | Chat interface |
| `https://ollama.lab.kemo.network` | Ollama API (for other services) |

**Open WebUI Static IP:** 192.168.62.70 | **Ollama Static IP:** 192.168.62.73

## Dependencies

- **Ollama** -- co-deployed LLM inference engine
- **Traefik** -- reverse proxy with TLS

No external database required -- Open WebUI uses internal SQLite. This stack is self-contained.

## Maintenance

```bash
# View logs
docker compose logs -f open-webui ollama

# Pull new models
docker exec ollama ollama pull mistral
docker exec ollama ollama pull llama3.2

# List downloaded models
docker exec ollama ollama list

# Update images (pin to specific versions)
docker compose pull && docker compose up -d

# Back up Open WebUI data (chat history, RAG docs, settings)
# Volume: open-webui-data

# Ollama model storage can be 10-200+ GB
# Volume: ollama-data (use fast SSD/NVMe storage)
```

GPU passthrough is configured in docker-compose.yml. `/dev/dri` is mounted by default for Intel/AMD. For NVIDIA, uncomment the `deploy.resources.reservations.devices` section. A 7B model requires ~4-8 GB RAM; a 70B model requires ~40+ GB.
