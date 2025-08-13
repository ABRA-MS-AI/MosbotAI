#!/bin/sh

echo 'Creating Python virtual environment ".venv"...'

# Check if python3 is available, otherwise use python
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
else
    echo "Error: Neither 'python3' nor 'python' command found. Please install Python."
    exit 1
fi

echo "Using Python command: $PYTHON_CMD"
$PYTHON_CMD -m venv .venv

if [ ! -d ".venv" ]; then
    echo "Error: Failed to create virtual environment"
    exit 1
fi

echo 'Installing dependencies from "app/backend/requirements.txt" into virtual environment...'
if [ -f "app/backend/requirements.txt" ]; then
    .venv/bin/python -m pip --quiet --disable-pip-version-check install -r app/backend/requirements.txt
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install dependencies"
        exit 1
    fi
    echo "Dependencies installed successfully"
else
    echo "Error: app/backend/requirements.txt not found"
    exit 1
fi
