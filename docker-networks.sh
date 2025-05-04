#!/bin/sh
# Creates required shared Docker networks if they don't already exist.
# This script is designed to be compatible with various shells (sh, bash, zsh, fish).

# --- Configuration ---
# List the names of the shared Docker networks your stacks require.
# These typically connect services across different docker-compose files.
# Example: A network for the reverse proxy to connect to various backend services.
SHARED_NETWORKS="proxy_network"

# Add more network names here, separated by spaces, if needed:
# SHARED_NETWORKS="proxy_network monitoring_network another_shared_network"
# --- End Configuration ---

echo "Attempting to create required shared Docker networks..."
echo "----------------------------------------------------"

# Loop through the defined network names
# Using a simple 'for' loop compatible with basic sh
for network_name in $SHARED_NETWORKS; do
  echo "Checking/Creating network: ${network_name}"

  # Attempt to create the network.
  # 'docker network create' will print an error if the network exists,
  # but the '|| true' part ensures the script continues regardless.
  # The 'true' command always exits with status 0 (success).
  # Error messages from Docker might still print to stderr.
  docker network create "${network_name}" || true

  # Optional: Add a small delay if experiencing issues in rapid succession
  # sleep 1
done

echo "----------------------------------------------------"
echo "Shared network check/creation process complete."

# Exit with a success code
exit 0
