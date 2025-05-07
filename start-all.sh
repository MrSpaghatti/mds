
## Startup Script (`start-all.sh`)

```bash
#!/bin/sh
# Start all Docker Compose stacks in a predefined order.
# Assumes this script is run from the repository root.
# Stops on the first error encountered.

# Ensure script exits immediately if a command fails.
set -e

echo "Starting Docker Stacks..."
echo "========================="

# --- Define Stack Directories in desired startup order ---
# List the relative paths to your stack directories.
# Proxy often good first or last. Stacks with dependencies later.
STACKS="
00-proxy
01-management
02-files-cloud
03-files-sync
04-ai-tools
"
# Add other stack directory names here as you create them
# Example:
# 05-monitoring
# 06-media
# --- End Configuration ---

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "Script location: ${SCRIPT_DIR}"
echo "Looking for stacks relative to this directory."
echo ""

for stack_dir in $STACKS; do
  full_path="${SCRIPT_DIR}/${stack_dir}"
  compose_file="${full_path}/docker-compose.yml"

  # Check if the directory and compose file exist
  if [ -d "${full_path}" ] && [ -f "${compose_file}" ]; then
    echo "--- Starting Stack: ${stack_dir} ---"
    # Navigate to the stack directory
    cd "${full_path}" || { echo "ERROR: Failed to cd into ${full_path}. Aborting."; exit 1; }

    # Run docker-compose up
    echo "Running 'docker-compose up -d' in $(pwd)"
    docker-compose up -d

    # Navigate back to the root directory
    cd "${SCRIPT_DIR}" || { echo "ERROR: Failed to cd back to ${SCRIPT_DIR}. Aborting."; exit 1; }
    echo "--- Started ${stack_dir} ---"
    echo ""
  else
    echo "--- Skipping: ${stack_dir} (directory or docker-compose.yml not found at ${compose_file}) ---"
    echo ""
  fi
done

echo "========================="
echo "All specified stacks processed."
exit 0
