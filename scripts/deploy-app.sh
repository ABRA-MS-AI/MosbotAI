#!/bin/bash

# Deploy Application Script for Contributor-level Service Principal
# This script deploys the application to existing Azure resources
# Infrastructure must be provisioned beforehand by admin

set -e

echo "🚀 Starting application deployment..."

# Check required environment variables
required_vars=(
    "AZURE_RESOURCE_GROUP"
    "AZURE_APP_SERVICE"
    "AZURE_STORAGE_ACCOUNT" 
    "AZURE_STORAGE_CONTAINER"
    "AZURE_ADLS_GEN2_STORAGE_ACCOUNT"
    "AZURE_ADLS_GEN2_FILESYSTEM"
    "AZURE_SEARCH_SERVICE"
    "AZURE_OPENAI_SERVICE"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var environment variable is not set"
        exit 1
    fi
done

echo "✅ Environment variables validated"

# Build frontend
echo "📦 Building frontend..."
cd app/frontend
npm install
npm run build
cd ../..

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd app/backend
python -m pip install --upgrade pip
pip install -r requirements.txt
cd ../..

# Deploy to App Service
echo "🚢 Deploying to Azure App Service..."
az webapp deployment source config-zip \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "$AZURE_APP_SERVICE" \
    --src app.zip \
    --build-remote true

# Create deployment package
echo "📦 Creating deployment package..."
cd app
zip -r ../app.zip . -x "node_modules/*" "__pycache__/*" "*.pyc" ".env*"
cd ..

# Update app settings with current configuration
echo "⚙️  Updating app service configuration..."
az webapp config appsettings set \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "$AZURE_APP_SERVICE" \
    --settings \
    AZURE_STORAGE_ACCOUNT="$AZURE_STORAGE_ACCOUNT" \
    AZURE_STORAGE_CONTAINER="$AZURE_STORAGE_CONTAINER" \
    AZURE_STORAGE_RESOURCE_GROUP="$AZURE_RESOURCE_GROUP" \
    AZURE_INDEXED_STORAGE_CONTAINER="${AZURE_INDEXED_STORAGE_CONTAINER:-indexed-files}" \
    AZURE_ADLS_GEN2_STORAGE_ACCOUNT="$AZURE_ADLS_GEN2_STORAGE_ACCOUNT" \
    AZURE_ADLS_GEN2_FILESYSTEM="$AZURE_ADLS_GEN2_FILESYSTEM" \
    AZURE_ADLS_GEN2_FILESYSTEM_PATH="${AZURE_ADLS_GEN2_FILESYSTEM_PATH:-/}" \
    AZURE_SEARCH_SERVICE="$AZURE_SEARCH_SERVICE" \
    AZURE_SEARCH_INDEX="${AZURE_SEARCH_INDEX:-gptkbindex}" \
    AZURE_OPENAI_SERVICE="$AZURE_OPENAI_SERVICE" \
    AZURE_OPENAI_CHATGPT_DEPLOYMENT="${AZURE_OPENAI_CHATGPT_DEPLOYMENT:-gpt-4o-mini}" \
    AZURE_OPENAI_EMB_DEPLOYMENT="${AZURE_OPENAI_EMB_DEPLOYMENT:-text-embedding-ada-002}" \
    OPENAI_HOST="azure"

# Clean up
rm -f app.zip

echo "✅ Application deployment completed successfully!"
echo "🌐 Your application is available at: https://$AZURE_APP_SERVICE.azurewebsites.net"

# Optional: Check deployment status
echo "🔍 Checking deployment status..."
az webapp show \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "$AZURE_APP_SERVICE" \
    --query "state" \
    --output tsv

echo "✅ Deployment completed!"