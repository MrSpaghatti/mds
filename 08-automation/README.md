# Watchtower - Automated Docker Container Updates

## 📋 Purpose

This stack deploys **Watchtower**, a service that monitors your running Docker containers and automatically updates them to the latest available image version from their respective registries (e.g., Docker Hub, GHCR).

Automating updates can help keep your services secure and up-to-date with new features, but it also carries a risk of pulling in breaking changes. **Regular backups of your persistent data are crucial when using Watchtower.**

---

## 📦 Services Included

- **`watchtower`**: The Watchtower application (`containrrr/watchtower` image).

---

## ⚙️ Configuration & Setup

Watchtower is configured primarily through environment variables set in the root `../.env` file.

1.  **`./docker-compose.yml`**:
    - Defines the `watchtower` service.
    - Mounts the Docker socket (`/var/run/docker.sock`) to allow Watchtower to interact with your Docker daemon. This is essential for its operation.
    - Sources environment variables from `../.env`.

2.  **Root `../.env` File**:
    - `WATCHTOWER_POLL_INTERVAL`: Interval in seconds for Watchtower to check for new images. Default is `86400` (24 hours). You can also use cron expressions if you prefer (e.g., `WATCHTOWER_SCHEDULE="0 0 4 * * *" ` for 4 AM daily, but then remove `WATCHTOWER_POLL_INTERVAL`).
    - `WATCHTOWER_CLEANUP`: Set to `true` (default) to have Watchtower remove old images after a successful update. Set to `false` to keep old images.
    - `WATCHTOWER_LABEL_ENABLE`:
        - If set to `false` (default in this setup), Watchtower will monitor and attempt to update ALL running containers that were started from an image with a newer version available.
        - If set to `true`, Watchtower will ONLY monitor containers that have the Docker label `com.centurylinklabs.watchtower.enable=true` explicitly set in their respective `docker-compose.yml` files. This gives you more granular control over which services are auto-updated.
    - `TZ`: Sets the timezone for correct log timestamps.
    - **Notification Variables (Optional):**
        - Watchtower can send notifications about updates or failures. The `docker-compose.yml` and `../.env.template` include commented-out examples for email and Shoutrrr (which supports many services like Gotify, Slack, Telegram, etc.).
        - To enable notifications, uncomment the relevant lines in both files and fill in your details in `../.env`. You'll need an SMTP server for email, or a configured endpoint for Shoutrrr.

---

## 🌐 Usage

1.  **Start Watchtower:**
    ```bash
    # From this directory (08-automation/):
    docker-compose up -d
    # Or via the root start-all.sh script if added there.
    ```
2.  **Operation:**
    - Watchtower will start and, after its initial polling interval, begin checking for updates for your running Docker containers.
    - It will pull new images, stop the old container, and restart it with the same configuration but using the new image.
3.  **Monitoring Watchtower:**
    - Check its logs to see its activity:
      ```bash
      docker-compose logs -f watchtower
      ```
    - Logs will indicate when it checks for updates, what containers it finds, and if any updates are performed or if errors occur.

---

## ⚠️ Important Considerations

- **Breaking Changes:** Automatic updates can sometimes introduce breaking changes if a new image version is not backward-compatible. While convenient, this is a risk.
- **Backup Strategy:** **Crucially important.** Before relying on automatic updates, ensure you have a robust backup strategy for all your services' persistent data. If an update breaks something, you'll need to be able to restore.
- **Pinning Image Versions:** For critical services where stability is paramount, you might choose to pin specific image versions (e.g., `image: myimage:1.2.3` instead of `image: myimage:latest`) in their `docker-compose.yml` files. Watchtower will typically not update images that are pinned to a specific version unless that exact version tag is updated in the registry (which is rare for fixed versions). If you use `latest` or a floating tag (like `v1.2`), Watchtower will update when those tags point to a new image hash.
- **Selective Updates (Label-Based):** If you want fine-grained control, set `WATCHTOWER_LABEL_ENABLE=true` in your `.env` and then add the label `com.centurylinklabs.watchtower.enable=true` only to the services you want Watchtower to manage.
  Example for a service in another `docker-compose.yml`:
  ```yaml
  services:
    some_service:
      image: someimage:latest
      labels:
        - "com.centurylinklabs.watchtower.enable=true"
      # ... rest of service config
  ```

---

## 🔗 Key Links

- **Main Project README:** [../../README.md](../../README.md)
- **Official Watchtower Documentation:** [https://containrrr.dev/watchtower/](https://containrrr.dev/watchtower/)

---
