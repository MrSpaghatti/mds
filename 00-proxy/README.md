# Caddy Reverse Proxy Stack (with Cloudflare DNS)

## 📋 Purpose

This stack deploys **Caddy v2**, a powerful, easy-to-use web server and reverse proxy with automatic HTTPS. This configuration is specifically set up to use the **Cloudflare DNS plugin**, allowing Caddy to obtain Let's Encrypt SSL certificates via the DNS-01 challenge method. This is essential for:

- Obtaining wildcard certificates (e.g., `*.yourdomain.com`).
- Getting certificates when your server is not directly reachable from the public internet on ports 80/443 (e.g., behind NAT without port forwarding).

Caddy acts as the single entry point for web traffic to your self-hosted services, routing requests to the appropriate backend containers based on hostname.

---

## 📦 Services Included

- **`caddy`**: The Caddy v2 web server/reverse proxy.
- **`ddclient`**: (Optional, but included in this stack) A client for updating dynamic DNS records with services like Cloudflare. Essential if your server's public IP address changes.

---

## Prerequisites

- **Docker & Docker Compose:** Installed on your host system.
- **Shared Docker Network (`proxy_network`):** This network must be created beforehand (`docker network create proxy_network`) as Caddy needs it to communicate with the backend services it proxies.
- **Root `.env` File:** A configured `.env` file must exist in the parent directory (`../.env`) containing necessary Cloudflare API credentials and your ACME registration email.
- **Cloudflare Account:** Your domain must be managed by Cloudflare.
- **Cloudflare API Token (for Caddy ACME):** You need a Cloudflare API token with permissions to **read zones** and **edit DNS records** for the specific zone(s) Caddy will manage certificates for.
  - Recommended permissions: `Zone:Read`, `DNS:Edit` for the relevant zone(s).
  - [Creating Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/reference/create-token/).
  - **Note:** This token *might* be different from the one used by `ddclient` if you prefer more granular permissions.
- **Cloudflare API Token (for ddclient DNS Updates):** If using `ddclient`, you'll need a separate Cloudflare API token with `Zone:DNS:Edit` permissions for the specific zone `ddclient` will manage. See `ddclient` configuration below and the root `../.env.template`.

---

## ⚙️ Configuration

### 1. Caddy

#### 1.1 Caddy Image with Cloudflare Plugin (CRITICAL)
- The standard `caddy:latest` or `caddy:<version>-alpine` images **do not** include the Cloudflare DNS plugin.
- The `docker-compose.yml` in this directory is pre-configured to use `ghcr.io/caddybuilds/caddy-cloudflare:latest`. Ensure this or a similar plugin-enabled image is used if you modify it.
- Failure to use a compatible image will result in errors during certificate acquisition when using the DNS challenge.

#### 1.2 Caddy Environment Variables (`../.env`)
- The Caddy service reads these variables from the root `.env` file:
  - `ACME_EMAIL`: Your email address for Let's Encrypt registration notifications.
  - `CLOUDFLARE_API_TOKEN`: The Cloudflare API token created specifically for Caddy's DNS challenges (with Zone:Read and DNS:Edit permissions for the relevant zone).
  - `TZ`: Sets the container timezone.
  - Domain variables like `DOMAIN_NAME`, `AUTHELIA_DOMAIN`, `TRILIUM_NOTES_DOMAIN`, `CODIUM_DOMAIN` which are used within the `Caddyfile`.

#### 1.3 `Caddyfile` Configuration
- The primary Caddy configuration lives in the `Caddyfile` located **within this directory** (`./Caddyfile`).
- This file is already set up to use environment variables for domain names and Authelia integration.
- **You must edit this file** if you add new services or change existing proxy setups.
- **Global Options Block:** The `Caddyfile` includes a global options block using environment variables:
  ```caddyfile
  {
      # Your email from .env
      email {$ACME_EMAIL}

      # Use Let's Encrypt staging for testing (optional)
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory

      # Enable Cloudflare DNS challenge using the token from .env
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
  }

  # --- Your Proxy Definitions Below ---

  your-service.yourdomain.com {
      # Proxy to a backend service running on the proxy_network
      reverse_proxy backend-service-container-name:backend-port
  }

  # Example for Syncthing if running in network_mode: host
  syncthing.yourdomain.com {
      # Proxy to localhost because it binds directly to the host port
      reverse_proxy localhost:8384
  }

  # ... other service definitions
  ```
- Refer to the [Caddyfile Documentation](https://caddyserver.com/docs/caddyfile) for syntax and directives.

#### 1.4 Caddy Networking
- The Caddy container is attached to the external `proxy_network`.
- It listens on host ports `80` and `443`.
- It communicates with backend services using their container names and ports *over the `proxy_network`* (unless the backend uses `network_mode: host`, in which case Caddy connects via `localhost:<port>`).

### 2. ddclient (Dynamic DNS Updater)

The `ddclient` service is included in this stack's `docker-compose.yml` to automatically update your Cloudflare DNS records if your server has a dynamic public IP address.

#### 2.1 ddclient Configuration (`../.env`)
- `ddclient` is configured primarily through environment variables set in the root `../.env` file. The `linuxserver/ddclient` image uses these to generate its internal `ddclient.conf`.
- Key variables:
  - `DDCLIENT_PUID` & `DDCLIENT_PGID`: User/Group IDs for the `ddclient` process (usually `DEFAULT_PUID`/`DEFAULT_PGID`).
  - `TZ`: Timezone.
  - `DDCLIENT_CLOUDFLARE_EMAIL`: Your Cloudflare login email (may sometimes be optional with token auth, but good to set).
  - `DDCLIENT_CLOUDFLARE_API_TOKEN`: **Crucial.** A Cloudflare API token with **`Zone:DNS:Edit`** permissions for the *specific zone* defined in `DDCLIENT_CLOUDFLARE_ZONE`. This token tells Cloudflare that `ddclient` is authorized to change DNS records.
  - `DDCLIENT_CLOUDFLARE_ZONE`: Your root domain name that is managed in Cloudflare (e.g., `yourdomain.com`). This must match one of your Cloudflare zones.
  - `DDCLIENT_CLOUDFLARE_RECORDS`: A comma-separated list of DNS records (hostnames) within the specified zone that `ddclient` should update. Example: `@,auth,notes,code` (this would update `yourdomain.com`, `auth.yourdomain.com`, etc.). **These records must already exist in Cloudflare as A or AAAA records.** `ddclient` updates their IP; it doesn't create them.
- Refer to the `../.env.template` for the exact variable names and detailed comments.

#### 2.2 ddclient Operation
- On startup and at regular intervals, `ddclient` checks your server's current public IP address.
- If the IP has changed from what Cloudflare has for your specified records, `ddclient` uses the API token to update those DNS records in Cloudflare to point to the new IP.
- Logs for `ddclient` can be viewed with `docker-compose logs -f ddclient`. Check these logs for successful updates or any errors.

---

## 🚀 Usage

1. **Start the Stack**
   - Navigate to this directory:
     ```bash
     cd path/to/00-proxy/
     ```
   - Start the stack:
     ```bash
     docker-compose up -d
     ```

2. **How It Works**
   - Once started, Caddy reads the `Caddyfile`.
   - For each domain defined, it attempts to acquire an SSL certificate from Let's Encrypt using the Cloudflare DNS challenge (it temporarily creates TXT records in your Cloudflare zone using the API).
   - After obtaining certificates, Caddy listens for HTTPS traffic on port 443 (and redirects HTTP on port 80).
   - Incoming requests are matched against the domains in the `Caddyfile` and proxied to the appropriate backend service according to the `reverse_proxy` directives.

3. **Stopping the Stack**
   ```bash
   docker-compose down
   ```

4. **Viewing Logs (Essential for Troubleshooting)**
   ```bash
   docker-compose logs -f caddy
   ```
   *Look for messages about certificate acquisition, proxy errors, etc.*

---

## 💾 Data Persistence

- **`caddy_data`:** A Docker named volume storing acquired SSL certificates, OCSP staples, and other Caddy operational state. **Crucial for persistence.**
- **`caddy_config`:** A Docker named volume storing backups of Caddy's configuration (though the primary `Caddyfile` is a bind mount).
- **`./Caddyfile`:** The primary Caddy configuration file is bind-mounted directly from the host into the Caddy container.
- **`./ddclient_config`:** This directory (bind-mounted as `/config` into the `ddclient` container) will store `ddclient`'s runtime configuration and cache. The `linuxserver/ddclient` image typically generates `ddclient.conf` here based on your `.env` variables.

---

## 🔗 Useful Links

- [Back to Overview](../README.md)
- [Minecraft Server Stack](../05-games/README.md)
- [OwnCloud Stack](../02-files-cloud/README.md)
- [SyncThing Stack](../03-files-sync/README.md)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddyfile Directives](https://caddyserver.com/docs/caddyfile/directives)
- [Caddy Cloudflare DNS Plugin Info](https://github.com/caddyserver/cloudflare-dns)

---

## Troubleshooting

### Certificate Errors (Check Logs First!)
- **Incorrect API Token/Permissions:** Verify the `CLOUDFLARE_API_TOKEN` is correct and has the required `Zone:Read`, `DNS:Edit` permissions in Cloudflare for the relevant zone. Regenerate if needed.
- **Wrong Caddy Image:** Double-check you are using an image *with* the Cloudflare plugin built-in. The standard image will fail DNS challenges.
- **ACME CA Rate Limits:** If testing frequently, uncomment the `acme_ca` directive in `Caddyfile` to use Let's Encrypt's staging environment. Remove it for production certificates.
- **DNS Propagation:** Although usually fast with Cloudflare, allow a minute or two for DNS changes if issues persist immediately after startup.
- **Incorrect `acme_dns` Directive:** Ensure the directive in your `Caddyfile` global block is present and correct.

### 502 Bad Gateway Errors
- This means Caddy reached the network but could not connect successfully to the backend service specified in `reverse_proxy`.
  - **Is the backend service running?** (`docker ps`, check logs of the backend service).
  - **Is the backend service on the `proxy_network`?** (`docker network inspect proxy_network`).
  - **Is the hostname/port in `reverse_proxy` correct?** (e.g., `backend-container-name:backend-port`). Typos are common.
  - **If backend uses `network_mode: host`:** Did you use `localhost:<port>` in `reverse_proxy`?

---
