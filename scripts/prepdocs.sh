 #!/bin/sh

. ./scripts/load_python_env.sh

echo 'Running "prepdocs.py"'

additionalArgs=""
if [ $# -gt 0 ]; then
  additionalArgs="$@"
fi

# Use Azure Data Lake Gen2 instead of local data folder
./.venv/bin/python ./app/backend/prepdocs.py --verbose $additionalArgs
