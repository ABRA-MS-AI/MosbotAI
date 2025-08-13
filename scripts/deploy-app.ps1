# Deploy Application Script for Contributor-level Service Principal
# This script deploys the application to existing Azure resources
# Infrastructure must be provisioned beforehand by admin

param(
    [switch]$IndexDocuments
)

Write-Host "🚀 Starting application deployment..." -ForegroundColor Green

# Check required environment variables
$requiredVars = @(
    "AZURE_RESOURCE_GROUP",
    "AZURE_APP_SERVICE", 
    "AZURE_STORAGE_ACCOUNT",
    "AZURE_STORAGE_CONTAINER",
    "AZURE_ADLS_GEN2_STORAGE_ACCOUNT",
    "AZURE_ADLS_GEN2_FILESYSTEM",
    "AZURE_SEARCH_SERVICE",
    "AZURE_OPENAI_SERVICE"
)

foreach ($var in $requiredVars) {
    if (-not (Get-Item "env:$var" -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Error: $var environment variable is not set" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Environment variables validated" -ForegroundColor Green

# Build frontend
Write-Host "📦 Building frontend..." -ForegroundColor Blue
Set-Location app/frontend
npm install
npm run build
Set-Location ../..

# Install backend dependencies  
Write-Host "📦 Installing backend dependencies..." -ForegroundColor Blue
Set-Location app/backend
python -m pip install --upgrade pip
pip install -r requirements.txt
Set-Location ../..

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Blue
Set-Location app
Compress-Archive -Path * -DestinationPath ../app.zip -Force
Set-Location ..

# Deploy to App Service
Write-Host "🚢 Deploying to Azure App Service..." -ForegroundColor Blue
az webapp deployment source config-zip `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --name $env:AZURE_APP_SERVICE `
    --src app.zip `
    --build-remote true

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}

# Update app settings with current configuration
Write-Host "⚙️  Updating app service configuration..." -ForegroundColor Blue
$indexedContainer = if ($env:AZURE_INDEXED_STORAGE_CONTAINER) { $env:AZURE_INDEXED_STORAGE_CONTAINER } else { "indexed-files" }
$filesystemPath = if ($env:AZURE_ADLS_GEN2_FILESYSTEM_PATH) { $env:AZURE_ADLS_GEN2_FILESYSTEM_PATH } else { "/" }
$searchIndex = if ($env:AZURE_SEARCH_INDEX) { $env:AZURE_SEARCH_INDEX } else { "gptkbindex" }
$chatDeployment = if ($env:AZURE_OPENAI_CHATGPT_DEPLOYMENT) { $env:AZURE_OPENAI_CHATGPT_DEPLOYMENT } else { "gpt-4o-mini" }
$embDeployment = if ($env:AZURE_OPENAI_EMB_DEPLOYMENT) { $env:AZURE_OPENAI_EMB_DEPLOYMENT } else { "text-embedding-ada-002" }

az webapp config appsettings set `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --name $env:AZURE_APP_SERVICE `
    --settings `
    AZURE_STORAGE_ACCOUNT="$env:AZURE_STORAGE_ACCOUNT" `
    AZURE_STORAGE_CONTAINER="$env:AZURE_STORAGE_CONTAINER" `
    AZURE_STORAGE_RESOURCE_GROUP="$env:AZURE_RESOURCE_GROUP" `
    AZURE_INDEXED_STORAGE_CONTAINER="$indexedContainer" `
    AZURE_ADLS_GEN2_STORAGE_ACCOUNT="$env:AZURE_ADLS_GEN2_STORAGE_ACCOUNT" `
    AZURE_ADLS_GEN2_FILESYSTEM="$env:AZURE_ADLS_GEN2_FILESYSTEM" `
    AZURE_ADLS_GEN2_FILESYSTEM_PATH="$filesystemPath" `
    AZURE_SEARCH_SERVICE="$env:AZURE_SEARCH_SERVICE" `
    AZURE_SEARCH_INDEX="$searchIndex" `
    AZURE_OPENAI_SERVICE="$env:AZURE_OPENAI_SERVICE" `
    AZURE_OPENAI_CHATGPT_DEPLOYMENT="$chatDeployment" `
    AZURE_OPENAI_EMB_DEPLOYMENT="$embDeployment" `
    OPENAI_HOST="azure"

# Clean up
Remove-Item app.zip -Force -ErrorAction SilentlyContinue

# Optional document indexing
if ($IndexDocuments) {
    Write-Host "📚 Indexing documents from Azure Blob Storage..." -ForegroundColor Blue
    .\scripts\prepdocs.ps1
}

Write-Host "✅ Application deployment completed successfully!" -ForegroundColor Green
Write-Host "🌐 Your application is available at: https://$($env:AZURE_APP_SERVICE).azurewebsites.net" -ForegroundColor Cyan

# Check deployment status
Write-Host "🔍 Checking deployment status..." -ForegroundColor Blue
$appState = az webapp show --resource-group $env:AZURE_RESOURCE_GROUP --name $env:AZURE_APP_SERVICE --query "state" --output tsv
Write-Host "App Service State: $appState" -ForegroundColor Yellow

Write-Host "✅ Deployment completed!" -ForegroundColor Green