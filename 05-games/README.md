# Minecraft Server Stack

## 📋 Purpose
Deploy a GPU-enabled **Minecraft Server for Java Edition** using the [`itzg/minecraft-server`](https://github.com/itzg/docker-minecraft-server) Docker image.

This setup leverages your NVIDIA GPU for enhanced performance and integrates with your modular Docker Compose repository.

---

## 🚀 Usage

### 1. Start the Minecraft Server
1. Navigate to this directory:
   ```bash
   cd path/to/05-games-minecraft/
   ```
2. Start the server:
   ```bash
   docker-compose up -d
   ```

### 2. Access the Minecraft Server
- Players can connect to the server using your public IP or domain name (if a reverse proxy like Caddy is configured), on port `25565`.

---

## 🛠️ Configuration

### Environment Variables
Customize server settings in the `.env` file:
- **Basic Settings**:
  - `MINECRAFT_RCON_PASSWORD`: Password for remote console access.
  - `MAX_PLAYERS`: Maximum number of players (default: `20`).
  - `DIFFICULTY`: Server difficulty level (e.g., `easy`, `normal`, `hard`).

- **Advanced Settings**:
  - Add any other [Minecraft server properties](https://minecraft.fandom.com/wiki/Server.properties) as environment variables.

### GPU Configuration
- Ensure the NVIDIA Container Toolkit is installed and configured on your system.
- The container will utilize one GPU by default. Adjust the `count` value under `reservations.devices` in the `docker-compose.yml` file if needed.

### Persistence
- All server data (world, configs, etc.) is stored in the `minecraft_data` volume.

---

## 📈 Resource Allocation
- **Memory**: Allocated 6GB by default. Adjust the `MEMORY` environment variable in `.env` as needed.
- **GPU**: Utilizes one NVIDIA GPU.

---

## 🔗 Useful Links
- [itzg/minecraft-server Documentation](https://github.com/itzg/docker-minecraft-server)
- [Minecraft Server Properties](https://minecraft.fandom.com/wiki/Server.properties)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

---

## ⚠️ Troubleshooting
### Server Not Starting
- Ensure you have accepted the Mojang EULA by setting `EULA=TRUE` in `.env`.
- Verify that the NVIDIA Container Toolkit is correctly installed.

### High Resource Usage
- Reduce `MAX_PLAYERS` or lower the `MEMORY` allocation.

### Logs
- View logs using:
  ```bash
  docker-compose logs -f minecraft
  ```

---

## 🛡️ Security
- Always set a strong `RCON_PASSWORD` in the `.env` file.
- Use a reverse proxy (e.g., Caddy) for secure external access.
