# NextTrilium (Trilium Notes) Stack

## 📋 Purpose

This stack deploys **NextTrilium (Trilium Notes)**, a hierarchical note-taking application with a focus on building a personal knowledge base. This setup uses the `triliumnext/notes` Docker image.

Features of this setup:
- Data persistence via a Docker volume or bind mount.
- Integration with Caddy for reverse proxying and HTTPS.
- Protected by Authelia for authentication.

---

## 📦 Services Included

- **`trilium_notes`**: The NextTrilium application server.

---

## ⚙️ Configuration & Setup

Configuration for NextTrilium is managed through:

1.  **`./docker-compose.yml`**: Defines the `trilium_notes` service, volume mounts for data (`${TRILIUM_NOTES_DATA_DIR:-./data}`), network connections, and environment variables (like `TZ`).
2.  **Root `../.env` File**:
    - `TRILIUM_NOTES_DOMAIN`: Sets the domain/subdomain for accessing Trilium (e.g., `notes.yourdomain.com`). This is used by Caddy.
    - `TRILIUM_NOTES_DATA_DIR` (Optional): Allows you to specify a custom host path for Trilium's data. If not set, data is stored in `./data/` within this `06-notes/` directory.
    - `TZ`: Sets the timezone for the container.
3.  **Caddy & Authelia Configuration**:
    - Access to Trilium is proxied by Caddy (configured in `00-proxy/Caddyfile`).
    - Authentication is handled by Authelia (configured in `00-auth/` and `00-proxy/Caddyfile`).

---

## 🌐 Usage

- Access NextTrilium via the domain configured in your `../.env` file (e.g., `https://{$TRILIUM_NOTES_DOMAIN}`).
- You will be prompted to log in via Authelia.
- On first launch, Trilium may guide you through its own setup process (e.g., choosing server instance type, creating an initial admin user within Trilium itself if it has its own user management separate from Authelia's protection layer).

---

## 💾 Data Persistence

- Trilium's application data (notes, attachments, settings) is stored in the path specified by the volume mount in `./docker-compose.yml`.
- By default, this is `${TRILIUM_NOTES_DATA_DIR:-./data}`, meaning a `data` subdirectory will be created here (`06-notes/data/`) if `TRILIUM_NOTES_DATA_DIR` is not set in your `../.env` file.
- **Ensure this data is backed up regularly.**

---

## 🔗 Key Links

- **Main Project README:** [../../README.md](../../README.md) (for overall setup, `.env` variables, Caddy & Authelia integration)
- **Official Trilium Wiki:** [https://github.com/zadam/trilium/wiki](https://github.com/zadam/trilium/wiki) (for application-specific features and documentation)

---
