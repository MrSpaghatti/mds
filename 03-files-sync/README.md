# SyncThing Stack

## 📋 Purpose

This stack deploys **SyncThing**, an open-source, continuous, and decentralized file synchronization application. It allows you to securely sync files directly between your devices (servers, laptops, phones) without relying on a central cloud server.

This configuration uses `network_mode: host` for potentially better peer discovery and NAT traversal. It also relies on **bind mounts** to link directly to configuration and data directories on your host machine.

The Web UI is accessible locally (via `localhost:8384`) but is not exposed externally for security reasons.

---

## 📦 Services Included

- **`syncthing`**: The main SyncThing synchronization service and Web UI.

---

## Prerequisites

- **Docker & Docker Compose:** Installed on your host system.
- **Root `.env` File:** A configured `.env` file must exist in the parent directory (`../.env`) containing necessary PUID/PGID and TZ settings.
- **Host Directories:** You **must** create specific directories on your host machine *before* starting the stack to store SyncThing's configuration and the data you intend to sync.

---

## ⚙️ Configuration

### 1. Environment Variables (`../.env`)
- The SyncThing service requires the following variables defined in the root `.env` file (`../.env`):
  - `SYNCTHING_PUID`: The **User ID** of the user on your **host machine** that owns the configuration and data directories. Find using `id -u <your_username>`. **CRITICAL for correct permissions.**
  - `SYNCTHING_PGID`: The **Group ID** of the user on your **host machine** that owns the configuration and data directories. Find using `id -g <your_username>`. **CRITICAL for correct permissions.**
  - `TZ`: Sets the timezone for the container logs/timestamps.

### 2. Host Directories & Bind Mounts (CRITICAL)
- SyncThing requires directories on your host system for its configuration and for the actual data folders it will manage.
- **Before starting**, create these directories relative to this stack's `docker-compose.yml` file (or specify absolute paths in the compose file if preferred):
  ```bash
  # Create the configuration directory
  mkdir -p ./syncthing_config

  # Create the main data directory SyncThing will manage internally
  # The compose file maps this to /var/syncthing/Sync inside the container
  mkdir -p ./syncthing_data
  ```
- **Ownership:** Ensure the user/group specified by `SYNCTHING_PUID`/`SYNCTHING_PGID` in your `.env` file **owns** these created directories (`./syncthing_config`, `./syncthing_data`). Use `chown` if necessary:
  ```bash
  # Example: chown 1000:1000 ./syncthing_config ./syncthing_data
  sudo chown ${SYNCTHING_PUID}:${SYNCTHING_PGID} ./syncthing_config ./syncthing_data
  ```
- **Compose File Mapping:**
  ```yaml
  volumes:
    - ./syncthing_config:/var/syncthing/config # Host config -> Container config
    - ./syncthing_data:/var/syncthing/Sync   # Host data root -> Container data root
  ```
  *You can add more `- ./host/path:/var/syncthing/FolderName` lines if you want SyncThing to manage multiple distinct host directories.*

### 3. Networking (`network_mode: host`)
- This configuration sets `network_mode: host` in `docker-compose.yml`.
- **Implications:**
  - The SyncThing container shares the host's network stack directly.
  - It binds directly to host ports: `8384` (Web UI), `22000` (TCP/UDP Sync), `21027` (UDP Discovery). Ensure these ports are free on your host.
  - The Web UI can be accessed locally via `http://localhost:8384`.

---

## 🚀 Usage

1. **Prepare Host**
   - Create the host directories (`./syncthing_config`, `./syncthing_data`) as described above.
   - Set correct ownership for these directories.
   - Ensure `SYNCTHING_PUID`/`SYNCTHING_PGID` are set correctly in `../.env`.

2. **Start the Stack**
   - Navigate to this directory:
     ```bash
     cd path/to/03-files-sync/
     ```
   - Start the stack:
     ```bash
     docker-compose up -d
     ```

3. **Accessing SyncThing Web UI**
   - Open your web browser and navigate to `http://localhost:8384`.
   - **(First Run):** SyncThing may prompt you to set up authentication (username/password) for the Web UI. It's highly recommended to do this. Access `Settings` -> `GUI`.

4. **Configuring SyncThing**
   - **Add Remote Devices:** Get the Device ID from SyncThing instances on your other computers/phones and add them via `Actions` -> `Show ID` and `Add Remote Device`.
   - **Share Folders:**
     - Click `Add Folder`.
     - **Folder Path:** This path is *inside the container*. The default data volume (`./syncthing_data` on host) is mapped to `/var/syncthing/Sync` inside the container.
     - Give the folder a Label (e.g., "My Documents").
     - Go to the `Sharing` tab and select the remote devices you want to share this folder with.
     - Accept the shared folder on your other devices.

5. **Stopping the Stack**
   ```bash
   docker-compose down
   ```

6. **Viewing Logs**
   ```bash
   docker-compose logs -f syncthing
   ```

---

## 💾 Data Persistence

- **Configuration:** Stored directly on the host in the `./syncthing_config` directory (or the path you configured).
- **Synced Data:** Stored directly on the host in the `./syncthing_data` directory (or other paths you explicitly mapped).
- **Crucially, back up these host directories regularly!** Docker named volumes are not used for primary config/data in this setup.

---

## 🔗 Useful Links

- [Back to Overview](../README.md)
- [Caddy Reverse Proxy Stack](../00-proxy/README.md)
- [OwnCloud Stack](../02-files-cloud/README.md)
- [Minecraft Server Stack](../05-games/README.md)
- [SyncThing Documentation](https://docs.syncthing.net/)
- [SyncThing Docker Guide](https://docs.syncthing.net/users/docker.html)
- [SyncThing Forum](https://forum.syncthing.net/)

---

## Troubleshooting

### Permission Denied Errors (in Logs or UI)
- Almost always caused by incorrect ownership of the host directories (`./syncthing_config`, `./syncthing_data`).
- Verify the `SYNCTHING_PUID` and `SYNCTHING_PGID` in `.env` match the actual owner of these directories on the host (`ls -l`). Use `sudo chown PUID:PGID ...` to fix.

### Cannot Access Web UI
- Is SyncThing running (`docker ps`)? Check SyncThing logs (`docker-compose logs -f syncthing`).
- Is port `8384` blocked by a host firewall?

### Devices Not Connecting
- Check host firewall rules (allow ports `22000` TCP/UDP, `21027` UDP).
- Verify Device IDs are correct on both ends.
- Check SyncThing logs on both devices for connection errors.
- Ensure global discovery and relaying are enabled (in SyncThing settings) if needed for NAT traversal, or configure direct port forwarding on your router if possible.

---

This version ensures SyncThing remains secure and local. Let me know if you’d like to adjust anything else!
