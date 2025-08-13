# Smart Indexing with Azure Blob Storage

This document explains how to use the enhanced smart indexing feature that utilizes Azure Blob Storage folder structure for better organization and searchability.

## Overview

The system has been modified to:
1. **Preserve folder structure**: File paths from Azure Blob Storage are maintained throughout the indexing process
2. **Smart categorization**: Files are automatically categorized by their folder location
3. **Enhanced search**: Users can search and filter by folder names and full file paths

## Configuration

### Step 1: Set up Azure Storage Environment Variables

Run one of the setup scripts to configure your environment:

**For Bash/Linux/macOS:**
```bash
./scripts/setup-azure-storage.sh
```

**For PowerShell/Windows:**
```powershell
.\scripts\setup-azure-storage.ps1
```

This will set up:
- `AZURE_STORAGE_ACCOUNT=avivistaiblob`
- `AZURE_STORAGE_CONTAINER=main` (for raw files)
- `AZURE_ADLS_GEN2_STORAGE_ACCOUNT=avivistaiblob`
- `AZURE_ADLS_GEN2_FILESYSTEM=main`
- `AZURE_INDEXED_STORAGE_CONTAINER=indexed-files` (for processed files)

### Step 2: Organize Your Blob Storage

Structure your files in Azure Blob Storage with meaningful folder names:

```
main/ (container)
├── legal/
│   ├── contracts/
│   │   ├── contract_2024_01.pdf
│   │   └── service_agreement.pdf
│   └── policies/
│       ├── privacy_policy.pdf
│       └── terms_of_service.pdf
├── hr/
│   ├── benefits/
│   │   ├── health_insurance.pdf
│   │   └── retirement_plan.pdf
│   └── handbook/
│       └── employee_handbook.pdf
└── technical/
    ├── documentation/
    │   ├── api_guide.pdf
    │   └── user_manual.pdf
    └── specifications/
        └── system_requirements.pdf
```

## Usage

### Indexing Files

Run the indexing process (now uses Azure Data Lake Gen2):
```bash
./scripts/prepdocs.sh
```

The system will:
1. Connect to your Azure Blob Storage
2. Process all files while preserving folder structure
3. Index files with enhanced metadata including:
   - Full file path (e.g., `legal/contracts/contract_2024_01.pdf`)
   - Folder name for categorization (e.g., `legal/contracts`)
   - Source page with path (e.g., `legal/contracts/contract_2024_01.pdf#page=1`)

### Search Features

The enhanced indexing enables several search capabilities:

#### 1. Folder-based Search
Search within specific folders:
```
folder:legal
folder:hr/benefits
```

#### 2. Full Path Search
Search for files by their complete path:
```
sourcefile:"legal/contracts/contract_2024_01.pdf"
```

#### 3. Category-based Search
Files are automatically categorized by their top-level folder:
```
category:legal
category:hr
category:technical
```

## Index Fields

The search index now includes these fields with folder information:

- `sourcefile`: Full path including folders (e.g., `hr/benefits/health_insurance.pdf`)
- `sourcepage`: Full path with page number (e.g., `hr/benefits/health_insurance.pdf#page=1`)
- `folder`: Directory path (e.g., `hr/benefits`)
- `category`: Top-level folder or custom category
- `content`: Extracted text content

## Benefits

1. **Better Organization**: Files maintain their logical folder structure
2. **Enhanced Search**: Users can filter by department, document type, or folder
3. **Improved Context**: Search results show the organizational location of documents
4. **Scalability**: Works with complex folder hierarchies in blob storage

## Migration Notes

- Existing indexes will be automatically updated to support the new fields
- Old documents indexed without folder information will have `folder: "root"`
- The search functionality remains backward compatible

## Example Queries

```bash
# Find all HR documents
folder:hr

# Find contracts specifically
folder:legal/contracts

# Find all documents in benefits folder across all departments
folder:benefits

# Search for specific file with folder context
sourcefile:"technical/documentation/api_guide.pdf"
```