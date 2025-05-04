# AnythingLLM Docker Stack

## 💡 Purpose

This stack deploys **AnythingLLM**, a powerful open-source RAG (Retrieval-Augmented Generation) solution. It allows you to chat with your documents, using a local Large Language Model (LLM) provided by Ollama.

This component is designed to work as part of a larger Docker-based self-hosted environment, relying on a separate Ollama service and typically exposed via a central reverse proxy like Caddy.

## 📦 Services Included

*   **`anythingllm`**: The main AnythingLLM web application and backend service.

## Prerequisites

*   **Docker & Docker Compose:** Must be installed on your host system.
*   **Running Ollama Service:** AnythingLLM requires a connection to a running Ollama instance. Ensure the Ollama stack (or container) is running and healthy *before* starting this stack.
*   **Shared Docker Networks:** This stack assumes the existence of pre-created Docker networks:
    *   `default`: For internal communication with the Ollama service.
    *   `proxy_network`: For exposure via the Caddy reverse proxy stack.
    *   *(If these networks don't exist, create them: `docker network create default`, `docker network create proxy_network`)*
*   **Root `.env` File:** A configured `.env` file should exist in the parent directory (`../.env`) containing necessary global variables (like `TZ`).

## ⚙️ Configuration

1.  **Environment Variables (`../.env`):**
    *   Ensure the `TZ` (Timezone) variable is set correctly in the root `.env` file.
    *   The `OLLAMA_BASE_URL` is typically set *directly* in this stack's `docker-compose.yml` file (e.g., `http://ollama:11434`) to ensure connection via Docker's internal DNS. Verify this setting in `docker-compose.yml`.

2.  **Volumes:**
    *   `anythingllm_storage`: A Docker named volume used to persist AnythingLLM's database, vector stores, configuration, and uploaded documents. **Do not delete this volume unless you want to lose all data.**
    *   `anythingllm_hotdir`: A Docker named volume mapped to the `/app/collector/hotdir` directory inside the container. Any documents placed here (e.g., via another container or host mount if configured) can potentially be automatically ingested by AnythingLLM document collectors.

3.  **Networking:**
    *   Connects to the `default` network to communicate with the `ollama` service.
    *   Connects to the `proxy_network` so the Caddy reverse proxy can reach it on its internal port (usually `3001`).

## 🚀 Usage

1.  **Start the Stack:**
    *   Ensure the Ollama service is running and healthy.
    *   Navigate to this directory (`cd path/to/04-ai-tools/`).
    *   Run: `docker-compose up -d`

2.  **Accessing the UI:**
    *   AnythingLLM should be accessible via the URL configured in your Caddy reverse proxy stack (e.g., `https://anythingllm.yourdomain.com`).

3.  **Initial Setup (Inside AnythingLLM UI):**
    *   Navigate to `Settings` -> `LLM Preference`.
    *   Select `Ollama` as the LLM Provider.
    *   Verify the `Ollama Base URL` is set correctly to reach your Ollama container (typically `http://ollama:11434`). Test the connection.
    *   Select the desired Embedding Model and Chat Model (these must be pulled within your Ollama instance).
    *   Create a Workspace.
    *   Upload documents via the UI or configure collectors (potentially using the `hotdir` volume).

4.  **Stopping the Stack:**
    ```bash
    docker-compose down
    ```

5.  **Viewing Logs:**
    ```bash
    docker-compose logs -f
    ```

## 💾 Data Persistence

*   All core application data, configurations, and vector embeddings are stored in the `anythingllm_storage` named volume.
*   The `anythingllm_hotdir` volume is primarily for document ingestion workflows.

## Troubleshooting

*   **Cannot Connect to Ollama:** Ensure the Ollama container is running, healthy, and accessible from the AnythingLLM container (check `docker logs anythingllm` for connection errors). Verify the `OLLAMA_BASE_URL` in the service definition and the AnythingLLM UI settings. Check that both containers are on the same `default` Docker network.
*   **502 Bad Gateway Error:** Check your Caddy configuration to ensure it's correctly proxying to `anythingllm:3001` (or the correct internal port) on the `proxy_network`. Verify `anythingllm` is running (`docker ps`). Check Caddy logs.
*   **Permission Issues:** Less common with named volumes, but ensure Docker has appropriate permissions if interacting with bind mounts (though not used by default here).

## 📚 Official Documentation

For more detailed information on using AnythingLLM features:
*   [AnythingLLM Documentation](https://docs.anythingllm.com/)
