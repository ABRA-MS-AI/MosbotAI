# Configure Azure Storage for replacing local data folder
Write-Host "Setting up Azure Storage configuration..."

# Set the existing blob storage account for raw files
azd env set AZURE_STORAGE_RESOURCE_GROUP AI-PROD
azd env set AZURE_STORAGE_ACCOUNT avivistaiblob
azd env set AZURE_STORAGE_CONTAINER main
azd env set AZURE_STORAGE_SKU Standard_LRS

# Configure Azure Data Lake Gen2 for file ingestion (points to same storage account)
azd env set AZURE_ADLS_GEN2_STORAGE_ACCOUNT avivistaiblob
azd env set AZURE_ADLS_GEN2_FILESYSTEM main
azd env set AZURE_ADLS_GEN2_FILESYSTEM_PATH "/"

# Create a new parameter for indexed files container
azd env set AZURE_INDEXED_STORAGE_CONTAINER indexed-files

Write-Host "Azure Storage configuration completed!"
Write-Host ""
Write-Host "Current storage configuration:"
Write-Host "- Raw files: avivistaiblob/main"
Write-Host "- Indexed files: avivistaiblob/indexed-files"
Write-Host ""
Write-Host "You can now run .\scripts\prepdocs.ps1 to index files from Azure Blob Storage"