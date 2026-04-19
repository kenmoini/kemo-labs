# Open WebUI - Planning

## Overview

Open WebUI is a self-hosted web interface for interacting with Large Language Models. It provides a ChatGPT-like experience that can connect to local Ollama instances for running models on-premises, or to remote API providers (OpenAI, Anthropic, etc.). It supports multi-user environments, chat history, RAG (Retrieval Augmented Generation), model management, and more.

**Purpose in this homelab:** Provide a unified LLM chat interface for the household, connecting to a local Ollama backend for private/offline inference and optionally to cloud APIs for larger models.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| Open WebUI | `ghcr.io/open-webui/open-webui` | `v0.8.10` |
| Ollama | `ollama/ollama` | `0.18.2` |

- Open WebUI publishes to GHCR. The `main` tag tracks latest dev; prefer pinned release tags like `v0.8.10`.
- Ollama publishes to Docker Hub. Use a pinned version rather than `latest`.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 8080 | TCP | Open WebUI | Web UI (internal container port) |
| 11434 | TCP | Ollama | Ollama API server |

- Traefik will reverse-proxy to Open WebUI on port 8080.
- Ollama port 11434 only needs to be accessible from the Open WebUI container (and optionally from other services on the Podman network that need LLM inference).

## Environment Variables

### Open WebUI

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `OLLAMA_BASE_URL` | URL to reach the Ollama API | `http://ollama:11434` |
| `OPENAI_API_BASE_URL` | Optional remote OpenAI-compatible API URL | `https://api.openai.com/v1` |
| `OPENAI_API_KEY` | API key for remote OpenAI-compatible provider | (secret) |
| `WEBUI_SECRET_KEY` | Secret key for session signing | (generated secret) |
| `CORS_ALLOW_ORIGIN` | CORS allowed origins | `*` |
| `FORWARDED_ALLOW_IPS` | Trusted proxy IPs for forwarded headers | `*` |
| `SCARF_NO_ANALYTICS` | Disable analytics | `true` |
| `DO_NOT_TRACK` | Disable tracking | `true` |
| `ANONYMIZED_TELEMETRY` | Disable telemetry | `false` |

### Ollama

Ollama is configured primarily through its runtime environment and model pulls. Key variables:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `OLLAMA_HOST` | Bind address | `0.0.0.0` |
| `OLLAMA_MODELS` | Custom model storage path | `/root/.ollama` (default) |
| `NVIDIA_VISIBLE_DEVICES` | GPU devices for NVIDIA runtime | `all` |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `open-webui-data` | `/app/backend/data` | WebUI config, chat history, uploaded docs, RAG vector DB | 1-10 GB |
| `ollama-data` | `/root/.ollama` | Downloaded LLM model weights | 10-200+ GB |

- Ollama model storage is the biggest concern. A single 7B parameter model is ~4 GB; a 70B model is ~40 GB. Plan for at least 100 GB if running multiple models.
- Open WebUI stores its internal SQLite database, uploaded documents for RAG, and generated embeddings in its data volume.
- Both volumes should be on fast storage (SSD/NVMe preferred, especially for Ollama model loading).

## Resource Estimates

### Open WebUI (frontend/backend)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 1 core | 2 cores |
| RAM | 512 MB | 1-2 GB |

### Ollama (inference engine)

| Resource | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| CPU | 4 cores | 8+ cores | More cores = faster CPU inference |
| RAM | 8 GB | 16-32 GB | Must fit the full model in RAM/VRAM |
| GPU VRAM | - | 8-24 GB | Dramatically faster inference with GPU |

- Running a 7B model requires ~4-8 GB RAM; a 13B model ~8-16 GB; a 70B model ~40+ GB.
- Without GPU, inference on CPU is functional but significantly slower (10-50x depending on model size).
- With 128 GB+ system RAM, CPU-only inference of even 70B models is viable, just slower.

## Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| Ollama | Co-deployed service | Runs alongside Open WebUI in the same compose stack |
| Traefik | Reverse proxy | TLS termination via StepCA ACME |
| StepCA | TLS certificates | ACME provider for Traefik |
| Podman network | Networking | Shared bridge network for inter-service communication |

- Open WebUI does NOT require PostgreSQL -- it uses an internal SQLite database.
- No shared database dependency; this stack is self-contained.

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.42.70` |
| DNS Name | `open-webui.lab.kemo.dev` |
| Container Network | Shared macvlan/bridge with static IP assignment |
| Traefik Labels | Route `open-webui.lab.kemo.dev` to container port 8080 |

### Traefik Integration

- HTTPS entrypoint with TLS certificate from StepCA ACME.
- Traefik labels on the Open WebUI container for automatic service discovery.
- Ollama does NOT need to be exposed through Traefik (internal-only), unless other services outside this compose stack need direct Ollama API access, in which case expose `ollama.lab.kemo.dev` on port 11434.

## Special Considerations

### GPU Passthrough

GPU passthrough dramatically improves LLM inference performance. Options:

1. **NVIDIA GPU** (most common for LLM workloads):
   - Install NVIDIA Container Toolkit on the Fedora host.
   - Add deploy resource reservations to the Ollama service:
     ```yaml
     deploy:
       resources:
         reservations:
           devices:
             - driver: nvidia
               count: all
               capabilities: [gpu]
     ```
   - Requires `nvidia-container-toolkit` package on host.

2. **AMD GPU (ROCm)**:
   - Use the `ollama/ollama:rocm` image tag instead.
   - Pass through `/dev/kfd` and `/dev/dri` devices.
   - Add `group_add: [video, render]` to the container.

3. **CPU-only** (no GPU):
   - No special configuration needed.
   - Set appropriate CPU and memory limits to prevent Ollama from consuming all host resources during inference.

### Model Management

- Models are pulled at runtime via the Ollama CLI or Open WebUI interface.
- Pre-pull commonly used models after deployment (e.g., `ollama pull llama3.1:8b`).
- Consider a startup script or init container to pre-pull desired models.

### Security

- The first user to register becomes the admin; set `WEBUI_SECRET_KEY` to a strong random value.
- Consider setting `ENABLE_SIGNUP=false` after initial admin creation if not using SSO.
- Open WebUI supports OAuth/OIDC for SSO integration (future consideration with Authentik or similar).

### Performance Tuning

- If running CPU-only, set `OLLAMA_NUM_PARALLEL=1` to prevent concurrent requests from exhausting RAM.
- For GPU deployments, Ollama automatically manages VRAM and will offload layers to CPU RAM if the model exceeds VRAM.
- Mount Ollama data volume on NVMe storage to reduce model load times.
