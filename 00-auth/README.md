# Authelia Authentication Stack

## 📋 Purpose

This stack deploys **Authelia**, an open-source authentication and authorization server providing two-factor authentication and single sign-on (SSO) for your applications via a web portal. It's designed to be integrated with reverse proxies like Caddy.

This setup configures Authelia to:
- Use a file-based user database (`users_database.yml`).
- Integrate with Caddy to protect other services.
- Store persistent data in a Docker volume.

---

## 📦 Services Included

- **`authelia`**: The Authelia server.

---

## ⚙️ Configuration & Setup

Configuration for Authelia is managed through:

1.  **`./docker-compose.yml`**: Defines the Authelia service, volume mounts, and network connections.
2.  **`./configuration.yml`**: The main Authelia configuration file (rules, session settings, authentication backends, etc.). This file uses environment variables (e.g., `{$DOMAIN_NAME}`, `{$AUTHELIA_JWT_SECRET}`) sourced from the root `../.env` file.
3.  **`./users_database.yml`**: Stores user definitions (usernames, hashed passwords, email, groups) for the file-based authentication backend. **You MUST populate this file manually.**
4.  **Root `../.env` File**: Contains essential variables like `AUTHELIA_DOMAIN`, `AUTHELIA_JWT_SECRET`, and `DOMAIN_NAME`.

### Initial User Setup:

1.  **Ensure Authelia is running:** `docker-compose up -d authelia` (from this directory, or via `../../start-all.sh`).
2.  **Generate a password hash:** Execute the following command from the `00-auth/` directory:
    ```bash
    docker-compose exec authelia authelia hash-password 'YourChosenStrongPassword'
    ```
    Replace `'YourChosenStrongPassword'` with a strong password.
3.  **Copy the output hash.** It will look something like `$argon2id$v=19$m=...`.
4.  **Edit `./users_database.yml`:** Add your user details, pasting the hash. Example:
    ```yaml
    users:
      yourusername:
        displayname: "Your Name"
        password: "PASTE_THE_HASH_HERE" # <-- Paste the full hash
        email: your-email@example.com
        groups:
          - admins
          - users
    ```
5.  **Restart Authelia** for changes to take effect if it was already running:
    ```bash
    docker-compose restart authelia
    ```

---

## 🌐 Usage

- Access the Authelia portal via the domain configured in your `.env` file (e.g., `https://{$AUTHELIA_DOMAIN}`).
- Services protected by Authelia (configured in `00-proxy/Caddyfile`) will redirect to this portal for login.

---

## 🔗 Key Links

- **Main Project README:** [../../README.md](../../README.md) (for overall setup, `.env` variables, Caddy integration)
- **Official Authelia Documentation:** [https://www.authelia.com/docs/](https://www.authelia.com/docs/)

---
