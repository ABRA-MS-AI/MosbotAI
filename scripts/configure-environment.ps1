# Environment Configuration Script
# Sets up environment variables for deployment with contributor-level permissions

Write-Host "🔧 Configuring environment for Azure deployment..." -ForegroundColor Green

# Required resource names (provided by admin)
$env:AZURE_RESOURCE_GROUP = "AI-PROD"
$env:AZURE_LOCATION = "westeurope"

# Storage configuration  
$env:AZURE_STORAGE_ACCOUNT = "avivistaiblob"
$env:AZURE_STORAGE_CONTAINER = "main"
$env:AZURE_STORAGE_RESOURCE_GROUP = "AI-PROD"
$env:AZURE_STORAGE_SKU = "Standard_LRS"
$env:AZURE_INDEXED_STORAGE_CONTAINER = "indexed-files"

# Data Lake Gen2 configuration for smart indexing
$env:AZURE_ADLS_GEN2_STORAGE_ACCOUNT = "avivistaiblob"
$env:AZURE_ADLS_GEN2_FILESYSTEM = "main" 
$env:AZURE_ADLS_GEN2_FILESYSTEM_PATH = "/"

# Azure services (set by admin during provisioning)
$env:AZURE_APP_SERVICE = "avivistai-app-service"
$env:AZURE_SEARCH_SERVICE = "avivistai-search"
$env:AZURE_SEARCH_INDEX = "gptkbindex"
$env:AZURE_SEARCH_SERVICE_RESOURCE_GROUP = "AI-PROD"
$env:AZURE_SEARCH_SERVICE_LOCATION = "eastus"
$env:AZURE_SEARCH_SERVICE_SKU = "basic"
$env:AZURE_SEARCH_QUERY_LANGUAGE = "he-IL"
$env:AZURE_OPENAI_SERVICE = "AvivistAI-LLM"
$env:AZURE_OPENAI_RESOURCE_GROUP = "AI-PROD"
$env:AZURE_OPENAI_LOCATION = "eastus"

# OpenAI model deployments
$env:AZURE_OPENAI_CHATGPT_DEPLOYMENT = "avivistai-gpt-4.1-mini-wolf"
$env:AZURE_OPENAI_CHATGPT_MODEL = "gpt-4.1-mini"
$env:AZURE_OPENAI_CHATGPT_DEPLOYMENT_VERSION = "2025-04-14"
$env:AZURE_OPENAI_EMB_DEPLOYMENT = "avivistai-text-embedding-3-small-wolf"
$env:AZURE_OPENAI_EMB_MODEL_NAME = "text-embedding-3-small"
$env:AZURE_OPENAI_EMB_DIMENSIONS = "text-embedding-3-small"
$env:AZURE_OPENAI_EMB_DEPLOYMENT_VERSION = "1"
$env:OPENAI_HOST = "azure"

# Authentication configuration
$env:AZURE_USE_AUTHENTICATION = "true"
$env:USE_CHAT_HISTORY_COSMOS = "true"
$env:AZURE_AD_APP_CLIENT_ID = "b8d47396-29d8-4df3-8265-215c73a7035b"
$env:AZURE_AD_APP_TENANT_ID = "17e2b5bf-da3a-4721-8c55-197b765c567f"
$env:AZURE_SERVER_APP_ID = "98c78307-f965-494f-8567-0c035f6356ee"

# Service Principal configuration (for GitHub Actions)
# These should be set in GitHub repository variables/secrets
# $env:AZURE_CLIENT_ID = "your-service-principal-client-id"
# $env:AZURE_TENANT_ID = "your-tenant-id"
# $env:AZURE_SUBSCRIPTION_ID = "your-subscription-id"

Write-Host "✅ Environment configured for deployment" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Current configuration:" -ForegroundColor Cyan
Write-Host "Resource Group: $env:AZURE_RESOURCE_GROUP" -ForegroundColor Yellow
Write-Host "Storage Account: $env:AZURE_STORAGE_ACCOUNT" -ForegroundColor Yellow
Write-Host "Search Service: $env:AZURE_SEARCH_SERVICE" -ForegroundColor Yellow
Write-Host "OpenAI Service: $env:AZURE_OPENAI_SERVICE" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 To customize these values, edit this script before running deployment" -ForegroundColor Blue
Write-Host ""
Write-Host "📖 Next steps:" -ForegroundColor Cyan
Write-Host "1. Run '.\scripts\deploy-app.ps1' to deploy the application" -ForegroundColor White
Write-Host "2. Run '.\scripts\prepdocs.ps1' to index documents from blob storage" -ForegroundColor White
Write-Host "3. Visit your application at: https://$($env:AZURE_APP_SERVICE).azurewebsites.net" -ForegroundColor White