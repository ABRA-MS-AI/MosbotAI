#!/bin/bash

# Load environment variables from .env.local
set -a
source app/.env.local
set +a

# Run prepdocs with environment variables
python app/backend/prepdocs.py \
  --storageaccount "$AZURE_STORAGE_ACCOUNT" \
  --storagekey "$AZURE_STORAGE_KEY" \
  --container "$AZURE_STORAGE_CONTAINER" \
  --searchservice "$AZURE_SEARCH_SERVICE" \
  --searchkey "$AZURE_SEARCH_KEY" \
  --index "$AZURE_SEARCH_INDEX" \
  --openaiservice "${AZURE_OPENAI_ENDPOINT%/}" \
  --openaikey "$AZURE_OPENAI_API_KEY" \
  --openaideployment "$AZURE_OPENAI_EMB_DEPLOYMENT" \
  --remove-all \
  --verbose \
  "$@"