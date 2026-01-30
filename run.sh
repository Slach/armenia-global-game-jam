#!/bin/bash
CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load environment variables from .env file
if [ -f "${CUR_DIR}/.env" ]; then
    source "${CUR_DIR}/.env"
else
    echo "Error: .env file not found"
    exit 1
fi

# Run PipeDream GUI with PyTrek command
"${CUR_DIR}/.venv/bin/pipedream-gui" --art-style "StarTrek sci-fi game, orange monochrome" bash -c "${CUR_DIR}/pytrek-9000.sh"
