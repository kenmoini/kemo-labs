# Paperless-AI - AI-Powered Document Processing

## Overview

Paperless-AI is an AI-powered extension for Paperless-NGX that brings automatic document classification, smart tagging, and semantic search. It uses LLM providers (OpenAI, Ollama, or other OpenAI-compatible APIs) to analyze document content and automatically assign titles, tags, document types, and correspondents. It also includes a RAG-based chat interface for natural language document queries.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| Paperless-AI | `docker.io/clusterzx/paperless-ai` | `latest` |

Single container running a Node.js application with an embedded RAG service.

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | TCP | HTTP web UI (configuration, manual processing, RAG chat) |

Traefik will proxy `paperless-ai.lab.kemo.dev` to port 3000 with TLS via StepCA ACME.

## Environment Variables

### Core Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `PAPERLESS_AI_PORT` | Application listen port | `3000` |
| `PAPERLESS_AI_INITIAL_SETUP` | Enable initial setup wizard | `yes` (first run only) |
| `PUID` | Process user ID | `1000` |
| `PGID` | Process group ID | `1000` |

### Paperless-NGX Connection

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `PAPERLESS_API_URL` | Paperless-NGX API endpoint | `https://paperless.lab.kemo.dev/api` |
| `PAPERLESS_API_TOKEN` | API token from Paperless-NGX | (generate in Paperless-NGX admin) |
| `PAPERLESS_USERNAME` | Paperless-NGX username (for some operations) | `admin` |

### AI Provider Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `AI_PROVIDER` | AI backend to use | `ollama`, `openai`, or `custom` |

#### For Ollama (local LLM):

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `OLLAMA_API_URL` | Ollama API endpoint | `http://ollama.lab.kemo.dev:11434` |
| `OLLAMA_MODEL` | Model to use | `llama3.2`, `mistral`, `phi-3`, `gemma-2` |

#### For OpenAI:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `OPENAI_API_KEY` | OpenAI API key | (your API key) |
| `OPENAI_MODEL` | Model to use | `gpt-4o`, `gpt-4o-mini` |

#### For Custom OpenAI-compatible API (DeepSeek, OpenRouter, LiteLLM, vLLM, etc.):

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `CUSTOM_BASE_URL` | API base URL | `http://open-webui.lab.kemo.dev/v1` |
| `CUSTOM_API_KEY` | API key | (your API key) |
| `CUSTOM_MODEL` | Model name | `deepseek-chat` |

### Document Processing Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `SCAN_INTERVAL` | Cron schedule for scanning new documents | `*/30 * * * *` (every 30 min) |
| `PROCESS_PREDEFINED_DOCUMENTS` | Process documents with specific tags | `yes` |
| `TAGS` | Tag(s) that trigger processing | `pre-process` |
| `ADD_AI_PROCESSED_TAG` | Add tag after AI processing | `yes` |
| `AI_PROCESSED_TAG_NAME` | Name of the "processed" tag | `ai-processed` |
| `USE_PROMPT_TAGS` | Use prompt-generated tags | `no` |
| `PROMPT_TAGS` | Specific tags for prompt-based classification | (comma-separated) |
| `USE_EXISTING_DATA` | Use existing document data in analysis | `no` |

### RAG Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `RAG_SERVICE_ENABLED` | Enable RAG-based chat | `true` |
| `RAG_SERVICE_URL` | RAG service URL | `http://localhost:8000` (internal) |

### System Prompt

| Variable | Description |
|----------|-------------|
| `SYSTEM_PROMPT` | Custom prompt instructing the AI how to analyze documents. Defines extraction rules for title, correspondent, tags, date, and language. |

The default system prompt extracts: title, correspondent, tags (max 4), document_date (YYYY-MM-DD), and language code. It can be customized for specific document types or organizational needs.

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `paperless-ai-data` | `/app/data` | Application data, RAG index, configuration | 1-5 GB |

The RAG index size depends on the number of documents indexed. For a typical homelab (hundreds to low thousands of documents), 1-5 GB is sufficient.

## Resource Estimates

| Service | CPU | Memory | Notes |
|---------|-----|--------|-------|
| Paperless-AI | 0.5-1 core | 512 MB - 1 GB | Node.js app + RAG indexing. AI inference is offloaded to the configured provider. |
| **Total** | **0.5-1 core** | **512 MB - 1 GB** | Lightweight when using external AI provider |

If using Ollama locally, the LLM inference resource cost is borne by the Ollama instance, not Paperless-AI.

## Dependencies

### Required Services

| Service | Purpose | Details |
|---------|---------|---------|
| Paperless-NGX | Source document system | Must be running and accessible via API at `192.168.62.53`. Requires a valid API token. |
| AI Provider | LLM inference | One of: Ollama (local), OpenAI (cloud), or any OpenAI-compatible API (Open WebUI, vLLM, etc.) |
| Traefik | Reverse proxy + TLS | Routes `paperless-ai.lab.kemo.dev` with StepCA ACME certificate |

### No Database Dependencies

Paperless-AI does **not** require PostgreSQL or Redis/Valkey. It stores its data in a local SQLite database and file-based RAG index within the `/app/data` volume.

### Integration Architecture

```
Paperless-AI (192.168.62.54)
    |
    |--> Paperless-NGX API (192.168.62.53:8000) -- document retrieval and tagging
    |
    |--> AI Provider (Ollama / OpenAI / Custom) -- document analysis
```

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.62.54` |
| DNS Zone | `lab.kemo.dev` |
| FQDN | `paperless-ai.lab.kemo.dev` |
| Container Network | `lab-network` (macvlan/bridge) |
| Subnet | `192.168.62.0/23` |

### Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.paperless-ai.rule=Host(`paperless-ai.lab.kemo.dev`)"
  - "traefik.http.routers.paperless-ai.entrypoints=websecure"
  - "traefik.http.routers.paperless-ai.tls=true"
  - "traefik.http.routers.paperless-ai.tls.certresolver=step-ca"
  - "traefik.http.services.paperless-ai.loadbalancer.server.port=3000"
```

## Special Considerations

1. **Deployment Order**: Paperless-NGX must be fully operational before deploying Paperless-AI. An API token must be created in Paperless-NGX first, then configured in Paperless-AI's environment.

2. **Initial Setup Wizard**: On first run with `PAPERLESS_AI_INITIAL_SETUP=yes`, the web UI presents a setup wizard for configuring the AI provider and Paperless-NGX connection. After completing setup, restart the container to build the RAG index.

3. **RAG Index Rebuild**: After initial setup or when adding many documents, the RAG index needs to be built. This happens automatically on container restart after setup completion. For large document collections, this may take significant time.

4. **Security**: The container drops all Linux capabilities (`cap_drop: ALL`) and enables `no-new-privileges`. This is a good security posture that should be maintained.

5. **AI Provider Selection**: For a fully self-hosted setup, use Ollama with a local model (e.g., `llama3.2` or `mistral`). For better accuracy with less local resource usage, use an OpenAI-compatible API. The `custom` provider type works with Open WebUI, vLLM, LiteLLM, and similar backends.

6. **Scan Interval**: The default `*/30 * * * *` cron expression checks for new documents every 30 minutes. Adjust based on document ingestion frequency. More frequent scanning increases API calls to Paperless-NGX.

7. **Tag-Based Processing**: The recommended workflow is to tag documents in Paperless-NGX with a `pre-process` tag, which Paperless-AI picks up and processes. After processing, it can optionally add an `ai-processed` tag.

8. **System Prompt Customization**: The default system prompt works well for general documents. For specialized use cases (e.g., medical records, legal documents), customize the `SYSTEM_PROMPT` to extract domain-specific metadata.

9. **Paperless-NGX API URL**: Use the internal Podman network URL (`http://192.168.62.53:8000/api`) or the Traefik URL (`https://paperless.lab.kemo.dev/api`). The internal URL avoids TLS overhead but requires network connectivity between containers.

10. **No Authentication Built-in**: Paperless-AI does not have its own authentication system. Protect the web UI using Traefik middleware (forward auth with Keycloak/Authentik) or restrict access via network policy.
