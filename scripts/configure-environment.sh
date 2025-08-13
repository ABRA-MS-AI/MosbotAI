#!/bin/bash

# Environment Configuration Script
# Sets up environment variables for deployment with contributor-level permissions

echo "🔧 Configuring environment for Azure deployment..."

# Required resource names (provided by admin)
export AZURE_RESOURCE_GROUP="AI-PROD"
export AZURE_LOCATION="westeurope"

# Storage configuration
export AZURE_STORAGE_ACCOUNT="avivistaiblob"
export AZURE_STORAGE_CONTAINER="main"
export AZURE_STORAGE_RESOURCE_GROUP="AI-PROD"
export AZURE_STORAGE_SKU="Standard_LRS"
export AZURE_INDEXED_STORAGE_CONTAINER="indexed-files"

# Data Lake Gen2 configuration for smart indexing
export AZURE_ADLS_GEN2_STORAGE_ACCOUNT="avivistaiblob"
export AZURE_ADLS_GEN2_FILESYSTEM="main"
export AZURE_ADLS_GEN2_FILESYSTEM_PATH="/"

# Azure services (set by admin during provisioning)
export AZURE_APP_SERVICE="avivistai-app-service"
export AZURE_SEARCH_SERVICE="avivistai-search"
export AZURE_SEARCH_INDEX="gptkbindex"
export AZURE_SEARCH_SERVICE_RESOURCE_GROUP="AI-PROD"
export AZURE_SEARCH_SERVICE_LOCATION="eastus"
export AZURE_SEARCH_SERVICE_SKU="basic"
export AZURE_SEARCH_QUERY_LANGUAGE="he-IL"
export AZURE_OPENAI_SERVICE="AvivistAI-LLM"
export AZURE_OPENAI_RESOURCE_GROUP="AI-PROD"
export AZURE_OPENAI_LOCATION="eastus"

# OpenAI model deployments
export AZURE_OPENAI_CHATGPT_DEPLOYMENT="avivistai-gpt-4.1-mini-wolf"
export AZURE_OPENAI_CHATGPT_MODEL="gpt-4.1-mini"
export AZURE_OPENAI_CHATGPT_DEPLOYMENT_VERSION="2025-04-14"
export AZURE_OPENAI_EMB_DEPLOYMENT="avivistai-text-embedding-3-small-wolf"
export AZURE_OPENAI_EMB_MODEL_NAME="text-embedding-3-small"
export AZURE_OPENAI_EMB_DIMENSIONS="text-embedding-3-small"
export AZURE_OPENAI_EMB_DEPLOYMENT_VERSION="1"
export OPENAI_HOST="azure"

# Authentication configuration
export AZURE_USE_AUTHENTICATION="true"
export USE_CHAT_HISTORY_COSMOS="true"
export AZURE_AD_APP_CLIENT_ID="b8d47396-29d8-4df3-8265-215c73a7035b"
export AZURE_AD_APP_TENANT_ID="17e2b5bf-da3a-4721-8c55-197b765c567f"
export AZURE_SERVER_APP_ID="98c78307-f965-494f-8567-0c035f6356ee"

# Service Principal configuration (for GitHub Actions)
# These should be set in GitHub repository variables/secrets
# export AZURE_CLIENT_ID="your-service-principal-client-id"
# export AZURE_TENANT_ID="your-tenant-id" 
# export AZURE_SUBSCRIPTION_ID="your-subscription-id"

echo "✅ Environment configured for deployment"
echo ""
echo "📋 Current configuration:"
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo "Storage Account: $AZURE_STORAGE_ACCOUNT"
echo "Search Service: $AZURE_SEARCH_SERVICE"
echo "OpenAI Service: $AZURE_OPENAI_SERVICE"
echo ""
echo "🔧 To customize these values, edit this script before running deployment"
echo ""
echo "📖 Next steps:"
echo "1. Run './scripts/deploy-app.sh' to deploy the application"
echo "2. Run './scripts/prepdocs.sh' to index documents from blob storage" 
echo "3. Visit your application at: https://$AZURE_APP_SERVICE.azurewebsites.net"