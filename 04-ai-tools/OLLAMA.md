# Ollama Docker Stack

## 💡 Purpose

This stack deploys **Ollama**, enabling you to run large language models (LLMs) like Llama 3, Mistral, Phi-3, etc., directly on your own hardware. It provides an API endpoint that other applications (like AnythingLLM) can connect to for inference.

This component can optionally leverage NVIDIA GPUs for significantly faster performance if the host system is equipped and configured correctly.

## 📦 Services Included

*   **`ollama`**: The core Ollama server providing the API and managing downloaded models.

## Prerequisites

*   **Docker & Docker Compose:** Installed on your host system.
*   **Root `.env` File:** A configured `.env` file should exist in the parent directory (`../.env`) containing necessary global variables (like `TZ`, `OLLAMA_KEEP_ALIVE`).
*   **(Optional) NVIDIA GPU Support:**
    *   Compatible NVIDIA GPU installed on the host.
    *   Appropriate NVIDIA drivers installed.
    *   [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed and configured.
*   **(Optional) Shared Docker Networks:** If Ollama needs to communicate with other stacks (like AnythingLLM), ensure necessary shared networks (e.g., `default`) are created (`docker network create default`).

## ⚙️ Configuration

1.  **Environment Variables (`../.env`):**
    *   `TZ`: Set your timezone (e.g., `America/New_York`). Defaults to `Etc/UTC`.
    *   `OLLAMA_KEEP_ALIVE`: (Optional) Controls how long models stay loaded in memory after use (e.g., `24h`, `1h`, `0` to unload immediately). Useful for performance vs. memory usage. Defaults to `24h`.

2.  **GPU Acceleration (Optional):**
    *   To enable GPU support, you **must** uncomment the `deploy` section within the `ollama` service definition in `docker-compose.yml`.
    *   Ensure your host meets the NVIDIA prerequisites listed above.
    *   The `count: all` directive allows Ollama to use all available GPUs. Adjust if needed (`count: 1`).

3.  **Volumes:**
    *   `ollama_data` (or `ollama_gpu_data`): A Docker named volume is automatically created to store downloaded models and Ollama's internal state. **Do not delete this volume unless you intend to re-download all models.** Its default location is `/root/.ollama` inside the container.

4.  **Networking:**
    *   Exposes port `11434` for API access. This can be accessed directly from the host (`http://localhost:11434`) or by other containers on the same Docker network (e.g., `http://ollama:11434` from AnythingLLM if both are on the `default` network).
    *   Attached to a network (e.g., `default_ollama` or `default`) to allow communication with other services.

## 🚀 Usage

1.  **Start the Stack:**
    *   Navigate to this directory (`cd path/to/ollama-stack/`).
    *   Run: `docker-compose up -d`

2.  **Interacting with Ollama:**
    *   **Pulling Models:** Use the Ollama CLI (if installed on host) or `curl`:
        ```bash
        # From host, if port 11434 is mapped
        curl http://localhost:11434/api/pull -d '{ "name": "llama3" }'

        # Or exec into the container
        docker exec -it ollama ollama pull llama3
        ```
    *   **Running Models (via API):** Use `curl` or API clients:
        ```bash
        curl http://localhost:11434/api/generate -d '{
          "model": "llama3",
          "prompt": "Why is the sky blue?",
          "stream": false
        }'
        ```
    *   **Listing Models:**
        ```bash
        curl http://localhost:11434/api/tags
        # Or
        docker exec -it ollama ollama list
        ```

3.  **Verifying GPU Usage (If Enabled):**
    *   On the host: `nvidia-smi` (Look for `ollama` processes using GPU memory).
    *   Inside the container: `docker exec -it ollama nvidia-smi`

4.  **Stopping the Stack:**
    ```bash
    docker-compose down
    ```

5.  **Viewing Logs:**
    ```bash
    docker-compose logs -f ollama
    ```

## 💾 Data Persistence

*   All downloaded models and Ollama configurations are stored in the Docker named volume specified in `docker-compose.yml` (e.g., `ollama_data`, `ollama_gpu_data`).

## Troubleshooting

*   **GPU Not Detected:**
    *   Verify NVIDIA drivers and Container Toolkit installation on the host.
    *   Ensure the `deploy` section in `docker-compose.yml` is correctly uncommented.
    *   Check `docker logs ollama` for errors related to GPU initialization.
    *   Run `docker exec -it ollama nvidia-smi` - does it show the GPU?
*   **Connection Refused (Port 11434):**
    *   Ensure the container is running (`docker ps`).
    *   Check the port mapping in `docker-compose.yml` matches what you're trying to connect to.
    *   Look for errors in `docker logs ollama`.
*   **Model Download Issues:** Check container logs and ensure the container has internet access.

## 📚 Official Documentation

*   [Ollama GitHub Repository](https://github.com/ollama/ollama)
*   [Ollama Docker Hub](https://hub.docker.com/r/ollama/ollama)
*   [Ollama Model Library](https://ollama.com/library)
