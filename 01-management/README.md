# Komodo Management Stack

## 📋 Purpose
This stack deploys **Komodo**, a modern alternative to Portainer for managing Docker stacks and deployments.

Komodo provides a web interface for:
- Managing Docker containers, images, volumes, and networks.
- Deploying and configuring stacks using Docker Compose.

## 🚀 Usage

### Start the Stack
1. Navigate to this directory:
   ```bash
   cd path/to/01-management/
   ```
2. Start the Komodo service:
   ```bash
   docker-compose up -d
   ```

### Access the Komodo UI
1. Open your web browser and navigate to the domain configured in your reverse proxy (e.g., `https://komodo.yourdomain.com`).
2. Follow the setup wizard to configure Komodo.

### Stopping the Stack
To stop Komodo, run:
```bash
docker-compose down
```

## 🛠️ Configuration
- The `komodo_data` volume stores all Komodo settings and data.
- The `proxy_network` is used to connect Komodo to the reverse proxy (e.g., Caddy).

## 🔗 Additional Resources
- [Komodo Documentation](https://komo.do/docs/docker-compose)
