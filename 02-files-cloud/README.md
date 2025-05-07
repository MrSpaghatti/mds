# OwnCloud Stack (with MariaDB & Redis)

## 💡 Purpose

This stack deploys **OwnCloud Server**, a self-hosted platform for file synchronization, sharing, and content collaboration. It provides a web interface and client applications for accessing your files across devices.

This stack includes the necessary dependencies:
*   **MariaDB:** The database backend for storing OwnCloud metadata.
*   **Redis:** Used for performance improvements through caching and file locking.

It's designed to be accessed via a central reverse proxy (like Caddy) configured in a separate stack.

## 📦 Services Included

*   **`owncloud`**: The main OwnCloud Server application.
*   **`owncloud_mariadb`**: The MariaDB database service.
*   **`owncloud_redis`**: The Redis caching service.

## Prerequisites

*   **Docker & Docker Compose:** Installed on your host system.
*   **Root `.env` File:** A configured `.env` file must exist in the parent directory (`../.env`) containing necessary credentials and domain settings.
*   **Shared Docker Networks:** This stack relies on pre-created Docker networks:
    *   `proxy_network`: For exposing the OwnCloud web UI via the Caddy reverse proxy stack.
    *   `default` (or a stack-specific internal network): Used for communication between OwnCloud, MariaDB, and Redis.
    *   *(If these networks don't exist, create them: `docker network create proxy_network`, `docker network create default`)*

## ⚙️ Configuration

1.  **Environment Variables (`../.env`):**
    *   The services in this stack require the following variables defined in the root `.env` file (`../.env`):
        *   `OWNCLOUD_DOMAIN`: Your external domain for accessing OwnCloud (e.g., `cloud.yourdomain.com`). Used by OwnCloud and Caddy configuration.
        *   `OWNCLOUD_ADMIN_USERNAME`: The desired username for the initial OwnCloud admin account.
        *   `OWNCLOUD_ADMIN_PASSWORD`: The **strong** password for the initial OwnCloud admin account.
        *   `OWNCLOUD_DB_PASSWORD`: The **strong** password for the dedicated OwnCloud database user (`owncloud`). This is used by both the `owncloud` service and the `owncloud_mariadb` service.
        *   `MARIADB_ROOT_PASSWORD`: The **strong** password for the MariaDB `root` user (used for database management and healthchecks).
        *   `TZ`: Sets the timezone for the containers.

2.  **Reverse Proxy Settings (CRITICAL):**
    *   When running OwnCloud behind a reverse proxy like Caddy, it's **essential** to configure OwnCloud to correctly handle the proxy setup.
    *   The following environment variables **must** be set for the `owncloud` service within *this stack's* `docker-compose.yml`:
        ```yaml
        environment:
          # ... other variables from .env ...
          - OWNCLOUD_OVERWRITEHOST=${OWNCLOUD_DOMAIN} # Tells OwnCloud its external domain
          - OWNCLOUD_OVERWRITEPROTOCOL=https        # Tells OwnCloud external access is HTTPS (handled by Caddy)
          - OWNCLOUD_OVERWRITEWEBROOT=/             # Standard web root
          # Adjust regex if your proxy network subnet differs significantly from 172.16.0.0/12
          - OWNCLOUD_OVERWRITECONDADDR=^172\.([1-3][0-9]|4[0-4])\.0\..*$
          # Database Connection (explicitly set)
          - OWNCLOUD_DB_TYPE=mysql
          - OWNCLOUD_DB_HOST=owncloud_mariadb
          - OWNCLOUD_DB_NAME=owncloud
          - OWNCLOUD_DB_USERNAME=owncloud
          # Redis Connection (assuming Redis service name is 'owncloud_redis')
          - OWNCLOUD_REDIS_ENABLED=true
          - OWNCLOUD_REDIS_HOST=owncloud_redis
        ```
    *   Failure to set these `OWNCLOUD_OVERWRITE*` variables will likely result in OwnCloud generating incorrect URLs, leading to broken links or inaccessible resources.

3.  **Volumes:**
    *   `owncloud_files`: Docker named volume storing all user files and data uploaded to OwnCloud. **Crucial for data persistence.**
    *   `owncloud_mysql_data`: Docker named volume storing the MariaDB database files.
    *   `owncloud_redis_data`: Docker named volume storing Redis cache data.

4.  **Networking:**
    *   The `owncloud` service connects to the `proxy_network` so Caddy can reach its internal port (e.g., 8080).
    *   `owncloud`, `owncloud_mariadb`, and `owncloud_redis` connect to an internal network (e.g., `default`) for backend communication. MariaDB and Redis are *not* exposed on the proxy network.

## 🚀 Usage

1.  **Start the Stack:**
    *   Ensure the required Docker networks exist.
    *   Ensure the root `.env` file is correctly populated.
    *   Navigate to this directory (`cd path/to/02-files-cloud/`).
    *   Run: `docker-compose up -d`
    *   Wait for the services, especially MariaDB, to become healthy (the `depends_on` condition helps manage this).

2.  **Accessing OwnCloud:**
    *   Open your web browser and navigate to the domain configured in `OWNCLOUD_DOMAIN` and your Caddyfile (e.g., `https://cloud.yourdomain.com`).
    *   Log in using the `OWNCLOUD_ADMIN_USERNAME` and `OWNCLOUD_ADMIN_PASSWORD` specified in your `.env` file.

3.  **Stopping the Stack:**
    ```bash
    docker-compose down
    ```
    *To remove volumes (DATA LOSS!), use `docker-compose down -v`.*

4.  **Viewing Logs:**
    ```bash
    # View OwnCloud logs
    docker-compose logs -f owncloud

    # View MariaDB logs
    docker-compose logs -f owncloud_mariadb

    # View Redis logs
    docker-compose logs -f owncloud_redis
    ```

## 💾 Data Persistence

*   User files are stored in the `owncloud_files` volume.
*   Database contents are stored in the `owncloud_mysql_data` volume.
*   Redis cache data is in the `owncloud_redis_data` volume (less critical than files/DB).
*   **Regularly back up `owncloud_files` and `owncloud_mysql_data` volumes.**

## Troubleshooting

*   **502 Bad Gateway from Caddy:**
    *   Check Caddy logs (`docker-compose logs -f caddy` in the proxy stack directory).
    *   Check OwnCloud container logs (`docker-compose logs -f owncloud`). Is OwnCloud running and healthy?
    *   Verify both Caddy and OwnCloud are connected to the `proxy_network` (`docker network inspect proxy_network`).
*   **Database Connection Errors (in OwnCloud logs):**
    *   Verify MariaDB is running and healthy (`docker ps`, `docker-compose logs -f owncloud_mariadb`).
    *   Check that `OWNCLOUD_DB_PASSWORD` in `.env` exactly matches `MYSQL_PASSWORD` used by the MariaDB container.
    *   Ensure OwnCloud and MariaDB are on the same internal Docker network.
*   **Incorrect URLs / Broken Links within OwnCloud:**
    *   This is almost always caused by missing or incorrect `OWNCLOUD_OVERWRITE*` environment variables in the `owncloud` service definition. Double-check them.
*   **Login Failures:**
    *   Verify the `OWNCLOUD_ADMIN_USERNAME` and `OWNCLOUD_ADMIN_PASSWORD` in your `.env` file are correct. Passwords are case-sensitive.

## 📚 Official Documentation

*   [OwnCloud Server Administrator Manual](https://doc.owncloud.com/server/latest/admin_manual/)
*   [OwnCloud Docker Server Repository](https://github.com/owncloud-docker/server)
