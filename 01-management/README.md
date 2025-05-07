# Portainer CE Stack

## 💡 Purpose

This stack deploys **Portainer Community Edition (CE)**, a lightweight and powerful management UI for Docker, Docker Swarm, Kubernetes, and Nomad environments. It provides an easy-to-use web interface to view, manage, and deploy containers, images, volumes, networks, and more.

This stack is typically exposed via a central reverse proxy (like Caddy).

## 📦 Services Included

*   **`portainer`**: The Portainer CE web application and backend server.

## Prerequisites

*   **Docker & Docker Compose:** Installed on your host system.
*   **Root `.env` File:** A configured `.env` file should exist in the parent directory (`../.env`) containing necessary global variables (like `TZ`).
*   **Shared Docker Network (`proxy_network`):** This network must be created beforehand (`docker network create proxy_network`) as Portainer is intended to be accessed via the Caddy reverse proxy stack connected to this network.
*   **Docker Socket Access:** The host's Docker socket (`/var/run/docker.sock`) must be accessible to be mounted into the container.

## ⚙️ Configuration

1.  **Environment Variables (`../.env`):**
    *   `TZ`: (Optional) Set your timezone in the root `.env` file for consistent time display within Portainer logs/events if needed. Defaults to `Etc/UTC`.

2.  **Docker Socket Mount:**
    *   The `docker-compose.yml` file mounts the host's Docker socket (`/var/run/docker.sock`) into the container. This is **required** for Portainer to manage your local Docker environment.
    *   **Security Note:** Access to the Docker socket effectively grants root-level privileges over the host system. The provided configuration mounts it read-only (`:ro`) as a hardening measure, which is sufficient for most viewing and management tasks. Remove `:ro` only if specific Portainer features require write access to the socket (less common).

3.  **Volumes:**
    *   `portainer_data`: A Docker named volume is automatically created to store Portainer's configuration, user database, and settings. **Do not delete this volume unless you want to reset Portainer completely.**

4.  **Networking:**
    *   The Portainer container connects to the `proxy_network`.
    *   It listens internally on port `9443` (HTTPS), which the Caddy reverse proxy connects to.

## 🚀 Usage

1.  **Start the Stack:**
    *   Ensure the `proxy_network` exists.
    *   Navigate to this directory (`cd path/to/01-management/`).
    *   Run: `docker-compose up -d`

2.  **Accessing Portainer UI:**
    *   Open your web browser and navigate to the domain configured for Portainer in your Caddyfile (e.g., `https://portainer.yourdomain.com`).

3.  **Initial Setup (First Run Only):**
    *   On your first visit, Portainer will prompt you to create an administrator user account. Choose a strong, unique password.
    *   You will then be asked which environment you want to manage. Select "Docker" (Manage the local Docker environment) and click "Connect".

4.  **Managing Docker:**
    *   You can now use the Portainer interface to explore and manage your Docker containers, images, volumes, networks, etc.

5.  **Stopping the Stack:**
    ```bash
    docker-compose down
    ```

6.  **Viewing Logs:**
    ```bash
    docker-compose logs -f portainer
    ```

## 💾 Data Persistence

*   All Portainer settings, user accounts, and configurations are stored in the `portainer_data` Docker named volume.

## Troubleshooting

*   **Cannot Access UI / 502 Bad Gateway:**
    *   Check Caddy logs (`docker-compose logs -f caddy` in the proxy stack directory). Is Caddy proxying correctly to `portainer:9443`?
    *   Check Portainer logs (`docker-compose logs -f portainer`). Is the Portainer container running and healthy?
    *   Verify both Caddy and Portainer are connected to the `proxy_network` (`docker network inspect proxy_network`).
*   **"Unable to connect to the Docker environment" (Inside Portainer):**
    *   Verify the Docker socket (`/var/run/docker.sock`) is correctly mounted in the `docker-compose.yml` file for the Portainer service.
    *   Check Portainer logs for errors related to socket access. Ensure Docker daemon is running on the host.

## 📚 Official Documentation

*   [Portainer CE Documentation](https://docs.portainer.io/start/install-ce)
*   [Portainer CE Docker Hub](https://hub.docker.com/r/portainer/portainer-ce)
