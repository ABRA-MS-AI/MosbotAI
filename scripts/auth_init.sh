#!/bin/sh

set -e  # Exit on any error

echo "=== Azure Authentication Setup ==="
echo "Checking if authentication should be setup..."

# Check if azd command is available
if ! command -v azd >/dev/null 2>&1; then
    echo "Error: 'azd' command not found. Please install Azure Developer CLI."
    exit 1
fi

# Get environment variables with error handling
echo "Retrieving environment variables..."
AZURE_USE_AUTHENTICATION=$(azd env get-value AZURE_USE_AUTHENTICATION 2>/dev/null || echo "")
AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS=$(azd env get-value AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS 2>/dev/null || echo "")
AZURE_ENFORCE_ACCESS_CONTROL=$(azd env get-value AZURE_ENFORCE_ACCESS_CONTROL 2>/dev/null || echo "")
USE_CHAT_HISTORY_COSMOS=$(azd env get-value USE_CHAT_HISTORY_COSMOS 2>/dev/null || echo "")

echo "Environment variables retrieved:"
echo "  AZURE_USE_AUTHENTICATION: $AZURE_USE_AUTHENTICATION"
echo "  AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS: $AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS"
echo "  AZURE_ENFORCE_ACCESS_CONTROL: $AZURE_ENFORCE_ACCESS_CONTROL"
echo "  USE_CHAT_HISTORY_COSMOS: $USE_CHAT_HISTORY_COSMOS"

# Validate environment variable combinations
if [ "$AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS" = "true" ]; then
  if [ "$AZURE_ENFORCE_ACCESS_CONTROL" != "true" ]; then
    echo "Error: AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS is set to true, but AZURE_ENFORCE_ACCESS_CONTROL is not set to true."
    echo "Please run: azd env set AZURE_ENFORCE_ACCESS_CONTROL true"
    exit 1
  fi
fi

if [ "$USE_CHAT_HISTORY_COSMOS" = "true" ]; then
  if [ "$AZURE_USE_AUTHENTICATION" != "true" ]; then
    echo "Error: USE_CHAT_HISTORY_COSMOS is set to true, but AZURE_USE_AUTHENTICATION is not set to true."
    echo "Please run: azd env set AZURE_USE_AUTHENTICATION true"
    exit 1
  fi
fi

if [ "$AZURE_USE_AUTHENTICATION" != "true" ]; then
  echo "AZURE_USE_AUTHENTICATION is not set to 'true', skipping authentication setup."
  echo "To enable authentication, run: azd env set AZURE_USE_AUTHENTICATION true"
  exit 0
fi

echo "AZURE_USE_AUTHENTICATION is enabled, proceeding with authentication setup..."

# Check if load_python_env.sh exists
if [ ! -f "./scripts/load_python_env.sh" ]; then
    echo "Error: ./scripts/load_python_env.sh not found"
    exit 1
fi

echo "Loading Python environment..."
. ./scripts/load_python_env.sh

# Check if virtual environment was created successfully
if [ ! -f "./.venv/bin/python" ]; then
    echo "Error: Python virtual environment not found at ./.venv/bin/python"
    echo "Virtual environment creation may have failed."
    exit 1
fi

# Check if auth_init.py exists
if [ ! -f "./scripts/auth_init.py" ]; then
    echo "Error: ./scripts/auth_init.py not found"
    exit 1
fi

echo "Running Azure AD application setup..."
./.venv/bin/python ./scripts/auth_init.py

echo "=== Authentication setup completed successfully ==="
