# Codium (VS Code Server) Stack

## 📋 Purpose

This stack deploys **Codium (via `linuxserver/code-server`)**, providing a web-based instance of VS Code (specifically, the Codium fork) accessible from your browser. This allows you to code from anywhere and have a consistent development environment.

Features of this setup:
- Uses the `linuxserver/code-server` Docker image.
- Configuration and user data (settings, extensions) persistence via a Docker volume or bind mount.
- Integration with Caddy for reverse proxying and HTTPS.
- Protected by Authelia for authentication.

---

## 📦 Services Included

- **`codium`**: The `linuxserver/code-server` application.

---

## ⚙️ Configuration & Setup

Configuration for Codium is managed through:

1.  **`./docker-compose.yml`**:
    - Defines the `codium` service.
    - Mounts `${CODIUM_CONFIG_DIR:-./data/codium_config}:/config` for Codium's configuration, extensions, and user settings.
    - **Important:** You should also mount your actual project/code directories into the container (e.g., under `/config/workspace/`) to make them accessible within Codium. Example:
      ```yaml
      volumes:
        - ${CODIUM_CONFIG_DIR:-./data/codium_config}:/config
        - /path/to/your/host/projects:/config/workspace/my_projects
        # Or mount the entire monorepo for this project:
        # - ../../:/config/workspace/mds_repo
      ```
    - Connects to the `proxy_network`.
    - Uses environment variables from `../.env` for `PUID`, `PGID`, `TZ`.
2.  **Root `../.env` File**:
    - `CODIUM_DOMAIN`: Sets the domain/subdomain for accessing Codium (e.g., `code.yourdomain.com`). This is used by Caddy.
    - `CODIUM_CONFIG_DIR` (Optional): Allows you to specify a custom host path for Codium's configuration data. If not set, data is stored in `./data/codium_config/` within this `07-code-server/` directory.
    - `DEFAULT_PUID`, `DEFAULT_PGID`, `TZ`: Standard user/group ID and timezone settings.
    - `VSCODING_PASSWORD` (Optional): You can set a password directly in `code-server` via this environment variable if you want an additional layer of password protection on top of Authelia, or if you temporarily disable Authelia for Codium.
3.  **Caddy & Authelia Configuration**:
    - Access to Codium is proxied by Caddy (configured in `00-proxy/Caddyfile`).
    - Authentication is handled by Authelia (configured in `00-auth/` and `00-proxy/Caddyfile`).

---

## 🌐 Usage

- Access Codium via the domain configured in your `../.env` file (e.g., `https://{$CODIUM_DOMAIN}`).
- You will be prompted to log in via Authelia.
- Once logged in, the VS Code interface will load. You can open folders that you've mounted into the container (e.g., `/config/workspace/my_projects`).

---

## Shell History Persistence

To ensure your terminal command history persists across Codium sessions:

The `linuxserver/code-server` container runs as the `abc` user, and its home directory is `/app`. Shell history files (like `.bash_history`) need to be stored within the persistent `/config` volume.

**For Bash (common default shell in the terminal):**

1.  Open a terminal within Codium.
2.  Add the following lines to your Bash configuration file. The `linuxserver/code-server` image should pick up `~/.bashrc` (which is `/app/.bashrc`):
    ```bash
    echo '' >> /app/.bashrc # Ensure a newline before adding commands
    echo '# Persistent History Config' >> /app/.bashrc
    echo 'export HISTFILE=/config/.bash_history' >> /app/.bashrc
    echo 'export HISTSIZE=10000' >> /app/.bashrc
    echo 'export HISTFILESIZE=20000' >> /app/.bashrc
    echo 'PROMPT_COMMAND="history -a; $PROMPT_COMMAND"' >> /app/.bashrc
    ```
    *   `HISTFILE` tells Bash where to save the history.
    *   `HISTSIZE` and `HISTFILESIZE` control the number of lines stored.
    *   `PROMPT_COMMAND="history -a; $PROMPT_COMMAND"` ensures history is appended to the file after each command, rather than only on shell exit.
3.  **Apply the changes:**
    ```bash
    source /app/.bashrc
    ```
    Or simply close and reopen the terminal.

**For other shells (e.g., Zsh, Fish):**

-   You'll need to configure the equivalent history file variable for your chosen shell to point to a path within `/config`.
    -   **Zsh:** Set `HISTFILE` in your `~/.zshrc` (e.g., `export HISTFILE=/config/.zsh_history`).
    -   **Fish:** Fish history (`fish_history`) is typically at `~/.local/share/fish/fish_history`. You might need to symlink this path or the `~/.local/share/fish` directory into `/config/fish/` and then ensure `~/.local/share/fish` points there, or configure Fish's history path if possible. Consult Fish shell documentation for managing history file locations. A simpler approach might be to symlink:
        ```bash
        # In Codium terminal, if you use fish:
        mkdir -p /config/.local/share/fish
        # If /app/.local/share/fish/fish_history exists, move it first:
        # mv /app/.local/share/fish/fish_history /config/.local/share/fish/fish_history
        rm -rf /app/.local/share/fish # Remove if it's a dir
        ln -s /config/.local/share/fish /app/.local/share/fish
        ```
        This makes `/app/.local/share/fish` a symlink to a persistent location.

Ensure that any custom shell configuration files (like `.bashrc`, `.zshrc`) are themselves located or symlinked into a persistent part of `/config` if they are not by default. The `linuxserver/code-server` image aims to make common user configs persistent under `/config`.

---

## 💾 Data Persistence

- Codium's application configuration, user settings, extensions, and cached data are stored in the path specified by the volume mount for `/config` in `./docker-compose.yml`.
  - By default: `${CODIUM_CONFIG_DIR:-./data/codium_config}`, meaning a `data/codium_config` subdirectory will be created here (`07-code-server/data/codium_config/`) if `CODIUM_CONFIG_DIR` is not set in your `../.env` file.
- **Project files/workspaces are NOT stored here by default.** You must mount your project directories separately into the container as shown in the Configuration section.
- **Ensure your `/config` volume and any project volumes are backed up regularly.**

---

## 🔗 Key Links

- **Main Project README:** [../../README.md](../../README.md) (for overall setup, `.env` variables, Caddy & Authelia integration)
- **LinuxServer.io `code-server` Documentation:** [https://docs.linuxserver.io/images/docker-code-server](https://docs.linuxserver.io/images/docker-code-server)
- **VS Code / Codium Documentation:** [https://code.visualstudio.com/docs](https://code.visualstudio.com/docs) (for general editor features)

---
