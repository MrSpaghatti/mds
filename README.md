      
# Modular Docker Stacks for Self-Hosting

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## TODO
- [ ] [netshoot](https://github.com/nicolaka/netshoot)
- [ ] [trillium server?](https://github.com/zadam/trilium/wiki/Server-installation)
- [ ] [online vscode](https://github.com/coder/code-server) [docker version?](https://github.com/ahmadnassri/docker-vscode-server/blob/master/docker-compose.yml) [another one](https://github.com/gitpod-io/openvscode-server)
- [ ] owncloud vs nextcloud
- [ ] [gitea?](https://gittea.dev/)
- [ ] [doc2dash](https://github.com/hynek/doc2dash)/dash/customized docsets as llm context

## 👋 Introduction

Welcome! This repository provides a collection of curated, modular Docker Compose stacks designed for easy deployment and management of common self-hosted services. The philosophy is "one stack, one directory," promoting separation of concerns and making it simple to add, remove, or update individual service groups.

This setup leverages:

*   **Docker & Docker Compose:** For container orchestration.
*   **Caddy:** As a central reverse proxy handling automatic HTTPS via Let's Encrypt (using Cloudflare DNS challenge by default).
*   **Modular Structure:** Each core service or service group resides in its own directory.
*   **Centralized Configuration:** A root `.env` file manages shared secrets and settings.
*   **Shared Networking:** A `proxy_network` allows Caddy to communicate with backend services.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Docker:** [Install Docker](https://docs.docker.com/engine/install/)
2.  **Docker Compose:** [Install Docker Compose](https://docs.docker.com/compose/install/) (v2.x recommended)
3.  **Git:** For cloning this repository and managing versions. [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
4.  **Domain Name:** A domain pointed to your server's public IP address (required for Caddy HTTPS).
5.  **Cloudflare Account:** Your domain should be managed by Cloudflare if using the default Caddy/ddclient configurations.
6.  **Cloudflare API Tokens:**
    *   One token for **Caddy** (needs Zone:Read, DNS:Edit permissions for ACME DNS challenge).
    *   One token for **ddclient** (needs Zone:DNS:Edit permissions for dynamic DNS updates). *Separate tokens are recommended for better security scoping.*
7.  **Basic Command-Line Familiarity.**

## 🏗️ Project Structure

```plaintext
.
├── .env.template           # Template for environment variables (COMMIT THIS)
├── .gitignore              # Files for Git to ignore (like .env)
├── docker-networks.sh      # Script to create required shared Docker networks
├── start-all.sh            # Script to start all service stacks (optional)
├── README.md               # This file
│
├── 00-proxy/               # Caddy Reverse Proxy Stack
│   ├── docker-compose.yml
│   ├── Caddyfile
│   └── README.md
│
├── 01-management/          # Portainer Management UI Stack
│   ├── docker-compose.yml
│   └── README.md
│
├── 02-files-cloud/         # OwnCloud File Hosting Stack (OwnCloud, MariaDB, Redis)
│   ├── docker-compose.yml
│   └── README.md
│
├── 03-files-sync/          # SyncThing File Sync Stack
│   ├── docker-compose.yml
│   ├── syncthing_config/   # (Created by user) Host config dir
│   └── syncthing_data/     # (Created by user) Host data dir
│   └── README.md
│
├── 04-ai-tools/            # AI Tools Stack (Ollama, AnythingLLM)
│   ├── docker-compose.yml
│   └── README.md
│
└── # Add more stack directories here following the pattern...
```
## ⚙️ One-Time Setup
Follow these steps carefully to prepare your environment

1. **Clone Repository:**
	```bash
	git clone https://www.github.com/mrspaghatti/mds
	cd mds/
	```
2. **Create Shared Docker Networks:**
	- The Caddy proxy and backend services need to communicate over shared networks. Run the provided script or create the manually:
	```bash
	chmod +x ./docker-networks.sh
	./docker-networks.sh
	# Alternatively, manually:
	# docker network create proxy_network
	# docker network create default # If used by multiple stacks, otherwise stack-specific is fine
	```
	*(See `docker-networks.sh` to confirm/add networks needed by your specific stacks)*

3. **Configure Environment Variables (`.env`):**
	- **This is the most critical configuration step.**
	- Copy the template:
	```bash
	cp .env.template .env
	```
	- **Edit the `.env` file** using a text editor (`nano .env`, `vim .env`, `micro .env`, etc.).
	- **Carefully replace ALL placeholder values** with your actual information (domains, strong passwords, API keys, user/group IDs, timezone).
	- **Security:**
		- Usa a password manager to generate and store strong passwords.
		- Ensure API tokens have the minimum required permissions.
		- The `.gitignore` file prevents `.env` from being committed, but double-check.
	- **User/Group IDs (PUID/PGID):**
		- Find your user's IDs on Linux/macOS using `id -u` (for PUID) and `id -g` (for PGID).
	
	    These are essential for services using bind mounts (like SyncThing) to have correct file permissions on the host directories. Set `DEFAULT_PUID`, `DEFAULT_PGID`, `SYNCTHING_PUID`, `SYNCTHING_PGID` accordingly.
	- **Referenced Variables (Check `.env.template` for the full list): `TZ`, `DEFAULT_PUID`, `DEFAULT_PGID`, `ACME_EMAIL`, `CLOUDFLARE_API_TOKEN` (for Caddy), `DDCLIENT_*` variables (for ddclient), `OWNCLOUD_*` variables, `MARIADB_ROOT_PASSWORD`, `SYNCTHING_PUID`, `SYNCTHING_PGID`, `OLLAMA_KEEP_ALIVE`.
4. **Prepare Host Directories (if required):
	- Some stacks (like SyncThing) use **bind mounts**. You **must** create the specified directories on your host machine before starting those stacks.
	- **Crucially, ensure these host directories are owned by the PUID/PGID** specified in your `.env` file.	
	- Example for SyncThing (`03-files-sync/`):
	```bash
	cd 03-files-sync
	mkdir -p ./syncthing_config ./syncthing_data
	# Example: sudo chown 1000:1000 ./syncthing_config ./syncthing_data
	# Use your actual PUID/PGID from .env:
	sudo chown $(grep '^SYNCTHING_PUID=' ../.env | cut -d= -f2):$(grep '^SYNCTHING_PGID=' ../.env | cut -d= -f2) ./syncthing_config ./syncthing_data
	cd .. # Go back to root
	```
	- Refer to individual stack `README.md` files for specific directory requirements.
5. **Configure Caddy (`00-proxy/Caddyfile`):**
	- Edit the `00-proxy/Caddyfile`.
	- Replace placeholder domains (`your-service.yourdomain.com`) with your actual domains (which should match records in your `DDCLIENT_CLOUDFLARE_RECORDS` in `.env`).
	- Ensure the reverse_proxy directives point to the correct service names and ports (e.g., `portainer:9443`, `owncloud_server:8080`, `localhost:8384` for SyncThing).
	- Verify the acme_dns cloudflare `{$CLOUDFLARE_API_TOKEN}` directive is present if using the DNS challenge.
## 🚦 Managing Port Conflicts
Docker maps ports from your host machine to containers. Conflicts occur if multiple containers or host processes try to use the same host port.
- **How this Setup Mitigates Conflicts:**
   	- Most services are **not** mapped directly to host ports. They expose ports internally (e.g., `ports: - "8080"`) and are accessed only via the Caddy reverse proxy.
    - Caddy (`00-proxy`) requires exclusive use of host ports `80` and `443`. Ensure no other web server (`Apache`, `Nginx`) is running on the host using these ports.
    - SyncThing (`03-files-sync`), using `network_mode: host`, directly uses host ports `8384`, `22000`, `21027`. Ensure these are free.
- **Checking for Conflicts:**
   	- Before starting stacks, check for listening ports:
    	- Linux: `sudo ss -tulnp | grep LISTEN or sudo netstat -tulnp | grep LISTEN`
        - macOS: `sudo lsof -i -P | grep LISTEN`
    - After starting, see mapped ports: `docker ps` (look at the `PORTS` column).
- **Resolving Conflicts:**
	- Stop the conflicting service on the host.
    - If a Docker container needs a conflicting port mapped to the host, change the host side of the mapping in its `docker-compose.yml` (e.g., change `- "8080:80"` to `- "8081:80"`). Remember to update any dependent configurations (like Caddyfile).
## 📚 Available Service Stacks
Each directory contains a specific service stack. See the linked README.md in each directory for detailed configuration and usage instructions for that stack.
- `00-proxy/`: Caddy Reverse Proxy (Handles HTTPS, routes traffic)
- `01-management/`: Portainer CE (Docker Management UI)
- `02-files-cloud/`: OwnCloud Server (File Hosting/Sync Cloud)
- `03-files-sync/`: SyncThing (Decentralized File Sync)
- `04-ai-tools/`: AI Tools (Ollama, AnythingLLM)
- Add links to other stacks as you create them.
## ▶️ Usage: Running Stacks
You typically manage stacks individually:
1. Navigate: `cd <stack-directory-name>` (e.g., `cd 01-management`)
2. Start/Create: `docker-compose up -d`
3. Stop: `docker-compose down`
4. View Logs: `docker-compose logs -f` (or `docker-compose logs -f <service-name>`)
5. Update: See "Updating Services" section below.
6. Startup Order: While `depends_on` handles dependencies within a stack, there's no built-in cross-stack dependency management. Generally, start `00-proxy` first or last. Use the `start-all.sh` script for a simple sequential startup.
## 🚀 Automated Startup Script (start-all.sh)
A simple script is provided to start all defined stacks sequentially.

**Purpose:** Convenience script to bring up all services defined in the standard stack directories.
**Limitations:** Starts stacks in a fixed order defined in the script. Does not handle complex inter-stack dependencies beyond simple ordering. Error handling is basic (stops on first error).

**The Script:**
```bash
#!/bin/sh
# Start all Docker Compose stacks in a predefined order.
# Assumes this script is run from the repository root.
# Stops on the first error encountered.

# Ensure script exits immediately if a command fails.
set -e

echo "Starting Docker Stacks..."
echo "========================="

# --- Define Stack Directories in desired startup order ---
# List the relative paths to your stack directories.
# Proxy often good first or last. Stacks with dependencies later.
STACKS="
00-proxy
01-management
02-files-cloud
03-files-sync
04-ai-tools
"
# Add other stack directory names here as you create them
# Example:
# 05-monitoring
# 06-media
# --- End Configuration ---

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "Script location: ${SCRIPT_DIR}"
echo "Looking for stacks relative to this directory."
echo ""

for stack_dir in $STACKS; do
  full_path="${SCRIPT_DIR}/${stack_dir}"
  compose_file="${full_path}/docker-compose.yml"

  # Check if the directory and compose file exist
  if [ -d "${full_path}" ] && [ -f "${compose_file}" ]; then
    echo "--- Starting Stack: ${stack_dir} ---"
    # Navigate to the stack directory
    cd "${full_path}" || { echo "ERROR: Failed to cd into ${full_path}. Aborting."; exit 1; }

    # Run docker-compose up
    echo "Running 'docker-compose up -d' in $(pwd)"
    docker-compose up -d

    # Navigate back to the root directory
    cd "${SCRIPT_DIR}" || { echo "ERROR: Failed to cd back to ${SCRIPT_DIR}. Aborting."; exit 1; }
    echo "--- Started ${stack_dir} ---"
    echo ""
  else
    echo "--- Skipping: ${stack_dir} (directory or docker-compose.yml not found at ${compose_file}) ---"
    echo ""
  fi
done

echo "========================="
echo "All specified stacks processed."
exit 0
```

**How to Use the Script:**

1. **Save:** Ensure the script content above is saved as `start-all.sh` in the root directory.
2. **Make Executable:** `chmod +x start-all.sh`
3. **Run:** `./start-all.sh`
## 🌐 Networking Overview
- **`proxy_network`:** A shared Docker bridge network (created externally). Caddy connects to this to reach backend services. Backend services that need external access via Caddy also connect here.
- **Stack-Internal Networks (e.g., `cloud_default`, `ai_default`):** Bridge networks created within a stack's `docker-compose.yml`. Used for communication between services only within that stack (e.g., OwnCloud -> MariaDB).
- **`network_mode: host`:** Used by SyncThing (and optionally ddclient). Bypasses Docker networking, uses host ports directly. Requires Caddy to proxy via `localhost:<port>`.
## 💾 Data Persistence & Backups
- **Named Volumes:** Most services use Docker named volumes (e.g., `portainer_data`, `owncloud_files`) managed by Docker. Find their location on the host using `docker volume inspect <volume_name>`.
- **Bind Mounts:** Some services (SyncThing config/data, Caddyfile) use bind mounts linking directly to directories/files within the stack directories on the host.
- **BACKUP STRATEGY IS ESSENTIAL:**
	- Regularly back up Docker named volumes (using tools like `docker run --rm -v <volume_name>:/volume -v /path/to/host/backups:/backup busybox tar cvf /backup/<volume_name>.tar /volume`).
	- Regularly back up host directories used for bind mounts.
	- Back up your root `.env` file securely.
## 🔄 Updating Services
- **Check for New Image Versions:** Periodically review the Docker Hub pages or release notes for the services you use.
- **Backup: ALWAYS back up relevant volumes/bind mounts before updating.**
- **Update `docker-compose.yml`:** Change the image tag in the relevant stack's `docker-compose.yml` file to the desired new version (e.g., `image: portainer/portainer-ce:2.21.0`).
- **Pull New Image:** Navigate to the stack directory (`cd <stack-dir>`) and run `docker-compose pull <service-name>` (e.g., `docker-compose pull portainer`).
- **Recreate Container:** Run `docker-compose up -d --remove-orphans`. Docker Compose will stop the old container, remove it, and start a new one using the updated image and existing volumes.
- **Check Logs & Test.**
## ✨ Standards for Adding New Stacks
To maintain consistency:
1. **Directory:** Create a new numbered directory (e.g., `06-new-service/`).
2. **`docker-compose.yml`:**
	- Use a pinned image version.
	- Use `env_file: ../.env` for shared variables (`TZ`, `PUID/PGID`, relevant secrets).
	- Define necessary named volumes. Use bind mounts only when essential (like config files).
	- Network appropriately: Connect to `proxy_network` (as external) if Caddy needs access. Use a stack-specific internal network (e.g., `new-service_default`) for communication within the new stack.
	- Add healthchecks if applicable.
3. **`.env.template`:** Add any new required environment variables to the root .env.template with clear comments.
README.md: Create a README.md inside the new stack directory following the template used by existing stacks (Purpose, Services, Prerequisites, Configuration, Usage, Data Persistence, Troubleshooting).
Root README: Add a link to the new stack's README in the "Available Service Stacks" section of this file.
start-all.sh: Add the new stack directory name to the STACKS variable in the script, placing it in a logical startup order.
Caddyfile: Update 00-proxy/Caddyfile to add a reverse proxy block if the new service needs external access.
## ⁉️ Troubleshooting
- Check individual container logs first: cd <stack-dir> && docker-compose logs -f <service-name>.
- Check Caddy logs for proxy issues: cd 00-proxy && docker-compose logs -f caddy.
- Verify network connectivity: docker network inspect <network_name>. Ensure containers that need to communicate are attached.
- Check port conflicts on the host (ss, netstat).
- Verify file/directory permissions for bind mounts (PUID/PGID ownership).
- Double-check your .env file for typos or missing values.
- Consult the specific stack's README.md and official documentation.
