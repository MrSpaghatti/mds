      
# Core Self-Hosted Services with Docker

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## 👋 Introduction

Welcome! This repository provides a focused collection of Docker Compose stacks for essential self-hosted services, prioritizing security and ease of use. The core services are:

*   **Caddy:** Secure reverse proxy with automatic HTTPS.
*   **Authelia:** Single Sign-On (SSO) and Two-Factor Authentication (2FA) provider.
*   **NextTrilium (Trilium Notes):** Hierarchical note-taking application.
*   **Codium (VS Code Server):** Web-based VS Code IDE.

The philosophy is "one stack, one directory," promoting separation of concerns and making it simple to manage individual service groups.

This setup leverages:

*   **Docker & Docker Compose:** For container orchestration.
*   **Caddy:** As a central reverse proxy handling automatic HTTPS via Let's Encrypt (using Cloudflare DNS challenge by default).
*   **Authelia:** To protect services with robust authentication.
*   **Modular Structure:** Each core service or service group resides in its own directory.
*   **Centralized Configuration:** A root `.env` file manages shared secrets and settings.
*   **Shared Networking:** A `proxy_network` allows Caddy and Authelia to communicate with backend services.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Docker:** [Install Docker](https://docs.docker.com/engine/install/)
2.  **Docker Compose:** [Install Docker Compose](https://docs.docker.com/compose/install/) (v2.x recommended)
3.  **Git:** For cloning this repository and managing versions. [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
4.  **Domain Name:** A domain pointed to your server's public IP address (required for Caddy HTTPS and Authelia).
5.  **Cloudflare Account:** Your domain should be managed by Cloudflare if using the default Caddy configurations for DNS challenges.
6.  **Cloudflare API Token for Caddy:** (Needs Zone:Read, DNS:Edit permissions for ACME DNS challenge).
7.  **Basic Command-Line Familiarity.**
8.  **(Optional but Recommended) Dynamic DNS with `ddclient`:** If your server has a dynamic IP address, the `ddclient` service (included within the `00-proxy` stack) should be configured. This will keep your Cloudflare DNS records pointing to your server's changing IP. See the `DDCLIENT_*` variables in `.env.template` and the `00-proxy/README.md` for setup details.

## 🏗️ Project Structure

```plaintext
.
├── .env.template           # Template for environment variables (COMMIT THIS)
├── .gitignore              # Files for Git to ignore (like .env)
├── docker-networks.sh      # Script to create required shared Docker networks
├── start-all.sh            # Script to start all core service stacks
├── README.md               # This file
│
├── 00-proxy/               # Caddy Reverse Proxy Stack
│   ├── docker-compose.yml
│   ├── Caddyfile
│   └── README.md           # Contains info on ddclient setup too
│
├── 00-auth/                # Authelia Authentication Stack
│   ├── docker-compose.yml
│   ├── configuration.yml
│   └── users_database.yml  # You will populate this
│
├── 06-notes/               # NextTrilium (Trilium Notes) Stack
│   ├── docker-compose.yml
│   └── data/               # (Created by service) Trilium data (default location)
│
├── 07-code-server/         # Codium (VS Code Server) Stack
│   ├── docker-compose.yml
│   └── data/               # (Created by service) Codium config (default location)
│
├── 08-automation/          # Watchtower (Automatic Updates) Stack
│   ├── docker-compose.yml
│   └── README.md
│
└── # Other service directories (currently de-prioritized, can be re-added)
# ├── 01-management/        # Example: Portainer
# ├── 02-files-cloud/       # Example: OwnCloud
# ├── 03-files-sync/        # Example: SyncThing
# ├── 04-ai-tools/          # Example: Ollama
# ├── 05-games/             # Example: Game servers
```

## ⚙️ One-Time Setup
Follow these steps carefully to prepare your environment:

1.  **Clone Repository:**
    ```bash
    git clone https://www.github.com/mrspaghatti/mds # Or your fork
    cd mds/
    ```
2.  **Create Shared Docker Networks:**
    The Caddy proxy, Authelia, and backend services need to communicate over shared networks.
    ```bash
    chmod +x ./docker-networks.sh
    ./docker-networks.sh
    # This typically creates 'proxy_network'. Verify in docker-networks.sh.
    ```
3.  **Configure Environment Variables (`.env`):**
    *   **This is the most critical configuration step.**
    *   Copy the template: `cp .env.template .env`
    *   **Edit the `.env` file** (`nano .env`, `vim .env`, etc.).
    *   **Carefully replace ALL placeholder values** with your actual information:
        *   `TZ`: Your timezone.
        *   `DEFAULT_PUID`, `DEFAULT_PGID`: Your user/group IDs (`id -u`, `id -g`).
        *   `DOMAIN_NAME`: Your root domain (e.g., `example.com`).
        *   `ACME_EMAIL`: Your email for Let's Encrypt.
        *   `CLOUDFLARE_API_TOKEN`: For Caddy's DNS challenge.
        *   `AUTHELIA_DOMAIN`: Subdomain for Authelia (e.g., `auth.example.com`). This is `${AUTHELIA_DOMAIN}` in Caddy/Authelia configs.
        *   `AUTHELIA_JWT_SECRET`: **Generate a strong random string** (e.g., `openssl rand -hex 32`).
        *   `TRILIUM_NOTES_DOMAIN`: Subdomain for Trilium Notes (e.g., `notes.example.com`).
        *   `CODIUM_DOMAIN`: Subdomain for Codium (e.g., `code.example.com`).
        *   Review other variables like `DDCLIENT_*` if using dynamic DNS.
    *   **Security:** Use a password manager. Ensure API tokens have minimum required permissions. `.gitignore` prevents `.env` commit.
4.  **Configure Authelia Users:**
    *   After starting Authelia (e.g., `cd 00-auth && docker-compose up -d authelia`), you need to create users.
    *   Edit `00-auth/users_database.yml`. Follow the instructions within that file.
    *   You'll typically run: `docker-compose exec authelia authelia hash-password 'YourStrongPassword'` from the `00-auth` directory.
    *   Then, copy the complete hashed password output into `00-auth/users_database.yml` for your user.
5.  **Configure Caddy (`00-proxy/Caddyfile`):**
    *   The Caddyfile is mostly configured by environment variables from `.env`.
    *   Ensure your DNS records for `{$DOMAIN_NAME}` (if Caddy serves anything on it directly), `{$AUTHELIA_DOMAIN}`, `{$TRILIUM_NOTES_DOMAIN}`, and `{$CODIUM_DOMAIN}` are created in Cloudflare and point to your server's IP address.
6.  **Prepare Host Directories (if customizing data paths):**
    *   Services like Trilium and Codium will store data in subdirectories within their respective stack folders (e.g., `06-notes/data/`, `07-code-server/data/codium_config/`) by default if you don't override `TRILIUM_NOTES_DATA_DIR` or `CODIUM_CONFIG_DIR` in your `.env`.
    *   If you set these variables to custom paths in `.env`, ensure those host directories exist and have correct permissions for the `DEFAULT_PUID`/`DEFAULT_PGID`.

## 🚦 Managing Port Conflicts
*   Most services are **not** mapped directly to host ports. They are accessed via the Caddy reverse proxy.
*   Caddy (`00-proxy`) requires exclusive use of host ports `80` and `443`. Ensure no other web server (`Apache`, `Nginx`) is running on the host using these ports.

## 📚 Available Service Stacks

Each directory contains a specific service stack.
*   `00-proxy/`: Caddy Reverse Proxy (Handles HTTPS, routes traffic). See its README for `ddclient` info.
*   `00-auth/`: Authelia (Authentication and SSO).
*   `06-notes/`: NextTrilium (Trilium Notes - Hierarchical note-taking).
*   `07-code-server/`: Codium (VS Code in the browser).
*   `08-automation/`: Watchtower (Automatic Docker image updates).
*   *(Other services like Portainer, OwnCloud, SyncThing, AI-Tools, Games are currently de-prioritized but their directories might still exist as a reference or can be re-added by uncommenting them in `start-all.sh` and ensuring their configs are present).*

## ▶️ Usage: Running Stacks

You typically manage stacks individually or use the `start-all.sh` script for the core setup.

1.  **To start all core services:**
    ```bash
    chmod +x ./start-all.sh
    ./start-all.sh
    ```
2.  **To manage individual stacks:**
    *   Navigate: `cd <stack-directory-name>` (e.g., `cd 00-auth`)
    *   Start/Create: `docker-compose up -d`
    *   Stop: `docker-compose down`
    *   View Logs: `docker-compose logs -f` (or `docker-compose logs -f <service-name>`)
3.  **Startup Order:**
    *   The `start-all.sh` script attempts a sensible order (proxy and auth first).
    *   Generally, start `00-proxy/` and `00-auth/` before other services that depend on them.

## 🚀 Automated Startup Script (start-all.sh)
A simple script is provided to start the core focused stacks sequentially.

**Purpose:** Convenience script to bring up Caddy, Authelia, NextTrilium, and Codium.
**Limitations:** Starts stacks in a fixed order. Error handling is basic.

**The Script (ensure it's up-to-date with current focused stacks):**
```bash
#!/bin/sh
# Start core Docker Compose stacks in a predefined order.
# Assumes this script is run from the repository root.
# Stops on the first error encountered.

set -e

echo "Starting Core Docker Stacks..."
echo "=============================="

# --- Define Core Stack Directories in desired startup order ---
STACKS="
00-proxy
00-auth
06-notes
07-code-server
"
# Add other stack directory names here as you create them
# Example:
# 01-management # Portainer
# --- End Configuration ---

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "Script location: ${SCRIPT_DIR}"
echo "Looking for stacks relative to this directory."
echo ""

for stack_dir in $STACKS; do
  full_path="${SCRIPT_DIR}/${stack_dir}"
  compose_file="${full_path}/docker-compose.yml"

  if [ -d "${full_path}" ] && [ -f "${compose_file}" ]; then
    echo "--- Starting Stack: ${stack_dir} ---"
    cd "${full_path}" || { echo "ERROR: Failed to cd into ${full_path}. Aborting."; exit 1; }
    echo "Running 'docker-compose up -d' in $(pwd)"
    docker-compose up -d
    cd "${SCRIPT_DIR}" || { echo "ERROR: Failed to cd back to ${SCRIPT_DIR}. Aborting."; exit 1; }
    echo "--- Started ${stack_dir} ---"
    echo ""
  else
    echo "--- Skipping: ${stack_dir} (directory or docker-compose.yml not found at ${compose_file}) ---"
    echo ""
  fi
done

echo "=============================="
echo "All specified core stacks processed."
exit 0
```

**How to Use the Script:**
1.  **Save:** Ensure the script content is saved as `start-all.sh` in the root directory.
2.  **Make Executable:** `chmod +x start-all.sh`
3.  **Run:** `./start-all.sh`

## 🌐 Networking Overview
*   **`proxy_network`:** A shared Docker bridge network. Caddy, Authelia, and other services connect to this.
*   Services expose ports internally to this network; Caddy handles external access.

## 💾 Data Persistence & Backups
*   **Named Volumes & Bind Mounts:** Services use a mix of named volumes (managed by Docker) and bind mounts (direct links to host paths).
    *   Authelia: `authelia_data` named volume. Config files are bind-mounted from `00-auth/`.
    *   NextTrilium: Data stored in `${TRILIUM_NOTES_DATA_DIR:-./data}` within `06-notes/` by default.
    *   Codium: Config stored in `${CODIUM_CONFIG_DIR:-./data/codium_config}` within `07-code-server/` by default. Workspace should be mounted by user.
*   **BACKUP STRATEGY IS ESSENTIAL:**
    *   Regularly back up Docker named volumes.
    *   Regularly back up host directories used for bind mounts (especially your notes, Codium configs, and any project workspaces).
    *   Back up your root `.env` file securely.

## 🔄 Updating Services
*   **Check for New Image Versions:** Periodically review Docker Hub pages or release notes.
*   **Backup: ALWAYS back up relevant volumes/bind mounts before updating.**
*   **Update `docker-compose.yml`:** Change the image tag (e.g., `image: authelia/authelia:latest` to `image: authelia/authelia:v4.38.0`). Pinning versions is recommended for stability.
*   **Pull New Image & Recreate:**
    ```bash
    cd <stack-dir> # e.g., cd 00-auth
    docker-compose pull <service-name> # e.g., docker-compose pull authelia
    docker-compose up -d --remove-orphans
    ```
*   **Check Logs & Test.**

## ✨ Standards for Adding New Stacks (If Expanding)
If you add more services:
1.  **Directory:** Create a new numbered directory (e.g., `08-new-service/`).
2.  **`docker-compose.yml`:** Use `env_file: ../.env`, connect to `proxy_network` if Caddy/Authelia access is needed.
3.  **`.env.template`:** Add new environment variables.
4.  **README.md:** Create a README for the new stack. Update this root README.
5.  **`start-all.sh`:** Add the new stack if it's core or part of your regular startup.
6.  **Caddyfile & Authelia Config:** Update `00-proxy/Caddyfile` and `00-auth/configuration.yml` if the service needs proxying and protection.

## ⁉️ Troubleshooting
*   Check individual container logs: `cd <stack-dir> && docker-compose logs -f <service-name>`.
*   Check Caddy logs: `cd 00-proxy && docker-compose logs -f caddy`.
*   Check Authelia logs: `cd 00-auth && docker-compose logs -f authelia`.
*   Check `ddclient` logs (if used): `cd 00-proxy && docker-compose logs -f ddclient`.
*   Verify network connectivity (`docker network inspect proxy_network`). Ensure services that need to talk (e.g., Caddy to Authelia, Caddy to backend apps) are on this network.
*   **Double-check your `.env` file:** Typos in domain names, secrets, or API keys are very common. Ensure `DOMAIN_NAME` is just the root domain (e.g., `example.com`) and subdomains are correctly derived or set (e.g., `AUTHELIA_DOMAIN=auth.example.com`).
*   **DNS Records:** Verify that A or CNAME records for `{$AUTHELIA_DOMAIN}`, `{$TRILIUM_NOTES_DOMAIN}`, `{$CODIUM_DOMAIN}` (and any other services) are correctly pointing to your server's public IP in your DNS provider (e.g., Cloudflare). If using `ddclient`, check its logs to ensure it's updating IPs correctly.
*   **Cloudflare Specifics:**
    *   Ensure Cloudflare SSL/TLS mode is set to "Full (strict)" for best security once Caddy is issuing certs. "Flexible" can cause redirect loops.
    *   Temporarily pause Cloudflare (set DNS to "DNS Only" instead of "Proxied") if you suspect Cloudflare's proxying is causing issues during initial Caddy setup, then re-enable once Caddy gets certs.
    *   Check Cloudflare API token permissions for both Caddy (DNS challenge) and `ddclient` (DNS updates). They need appropriate Zone-level permissions.
*   **Authelia Login Issues:**
    *   **"Cannot GET /" on Authelia domain:** Caddy might not be proxying correctly to Authelia, or Authelia isn't running. Check Caddy and Authelia logs.
    *   **Redirect Loops:** Often caused by incorrect `X-Forwarded-Proto` or `X-Forwarded-Host` headers if the proxy setup is complex, or Cloudflare SSL mode. The provided Caddy config usually handles this well. Also, ensure Authelia's `session.domain` in `00-auth/configuration.yml` (derived from `DOMAIN_NAME` in `.env`) is set to your main second-level domain (e.g., `example.com`, not `auth.example.com`).
    *   **User Not Found / Incorrect Password:** Double-check `00-auth/users_database.yml` for correct username and hashed password. Ensure you restarted Authelia after changes.
    *   **"Invalid Target URL" or similar errors:** Ensure the service you're trying to access (e.g., Trilium, Codium) has a corresponding rule in Authelia's `00-auth/configuration.yml` under `access_control.rules`.
*   **Caddy Certificate Issues:**
    *   Logs will show errors related to ACME challenges.
    *   Ensure `CLOUDFLARE_API_TOKEN` in `.env` is correct and has `Zone:Read`, `DNS:Edit` permissions for the domain.
    *   Ensure `ACME_EMAIL` in `.env` is set.
    *   If you hit Let's Encrypt rate limits, you can temporarily use the staging CA by uncommenting `acme_ca https://acme-staging-v02.api.letsencrypt.org/directory` in `00-proxy/Caddyfile`'s global options, then switch back.
*   **"502 Bad Gateway" from Caddy:**
    *   Caddy can reach the network but the backend service (e.g., `trilium_notes`, `codium`) is not responding or not found at the specified internal address/port.
    *   Check if the backend service container is running (`docker ps -a`).
    *   Check logs of the backend service (`cd 06-notes && docker-compose logs -f trilium_notes`).
    *   Ensure the service name in Caddy's `reverse_proxy` directive matches the service name in the backend's `docker-compose.yml` and that it's on the `proxy_network`.
*   **Permission Issues with Volumes:**
    *   If a service fails to start or write data, it might be due to incorrect ownership of bind-mounted host directories. Ensure `DEFAULT_PUID`/`DEFAULT_PGID` in `.env` match your user's `id -u` / `id -g`, and that any custom data directories you created on the host are owned by this PUID/PGID.
*   Consult official documentation for Caddy, Authelia, NextTrilium (Trilium Wiki), and LinuxServer.io Code-Server.
*   The `TODO` section at the top of this README (if still present) may contain items previously considered or future ideas, which are not part of the current core setup.

_Previously considered services (can be re-added if desired, check old commits for configs): Portainer, OwnCloud, SyncThing, Ollama, Homarr, etc._
