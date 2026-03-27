#!/usr/bin/env bash
# Generates directory-scoped development environment variables so
# multiple worktrees / checkouts can run side-by-side without port or
# database name collisions.
#
# Sourced automatically by mise via mise.toml.

set -euo pipefail

if [ -n "${BASH_SOURCE[0]:-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  SCRIPT_PATH="${(%):-%x}"
else
  SCRIPT_PATH="$0"
fi

PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"
INSTANCE_FILE="${PROJECT_ROOT}/.carta-dev-instance"

# Allow explicit override via environment variable.
if [ -z "${CARTA_DEV_INSTANCE:-}" ]; then
  if [ -f "$INSTANCE_FILE" ]; then
    CARTA_DEV_INSTANCE="$(cat "$INSTANCE_FILE" 2>/dev/null || true)"
  fi

  # Validate: must be a number between 100 and 999.
  if ! [[ "${CARTA_DEV_INSTANCE:-}" =~ ^[1-9][0-9]{2}$ ]]; then
    # Generate a deterministic suffix from the project root path.
    CARTA_DEV_INSTANCE=$(( ( $(printf '%s' "$PROJECT_ROOT" | cksum | cut -d' ' -f1) % 900 ) + 100 ))
    echo "$CARTA_DEV_INSTANCE" > "$INSTANCE_FILE"
  fi
fi

export CARTA_DEV_INSTANCE

# App ports (scoped)
export CARTA_SERVER_PORT=$(( 4500 + CARTA_DEV_INSTANCE ))
export CARTA_SERVER_URL="http://localhost:${CARTA_SERVER_PORT}"
export CARTA_TEST_PORT=$(( 4600 + CARTA_DEV_INSTANCE ))

# Database names (scoped)
export CARTA_DB_SUFFIX="${CARTA_DEV_INSTANCE}"
