#!/usr/bin/env python3
"""
Script to process documents from blob storage
Run this via GitHub Actions or Azure Container Jobs
"""
import asyncio
import logging
import os
import sys
from pathlib import Path

# Add the backend to the Python path
sys.path.append(str(Path(__file__).parent.parent / "app" / "backend"))

from azure.identity.aio import ManagedIdentityCredential

from load_azd_env import load_azd_env
from prepdocs import (
    main,
    setup_blob_manager,
    setup_embeddings_service,
    setup_file_processors,
    setup_list_file_strategy,
    setup_search_info,
)
from prepdocslib.filestrategy import FileStrategy
from prepdocslib.strategy import DocumentAction


async def process_documents_from_blob():
    """Process documents from your source blob storage"""

    # Load environment variables
    load_azd_env()

    # Use managed identity (works in Azure environments)
    azure_credential = ManagedIdentityCredential()

    # Configuration from environment variables
    SOURCE_BLOB_ACCOUNT = os.environ.get("AZURE_SOURCE_BLOB_STORAGE_ACCOUNT", "yoursourceaccount")
    SOURCE_BLOB_CONTAINER = os.environ.get("AZURE_SOURCE_BLOB_CONTAINER", "documents")
    SOURCE_BLOB_PATH_PREFIX = os.environ.get("AZURE_SOURCE_BLOB_PATH_PREFIX", "")

    logging.info(f"Processing documents from: {SOURCE_BLOB_ACCOUNT}/{SOURCE_BLOB_CONTAINER}/{SOURCE_BLOB_PATH_PREFIX}")

    # Set up search info
    search_info = await setup_search_info(
        search_service=os.environ["AZURE_SEARCH_SERVICE"],
        index_name=os.environ["AZURE_SEARCH_INDEX"],
        azure_credential=azure_credential,
    )

    # Set up destination blob manager (for processed chunks)
    blob_manager = setup_blob_manager(
        azure_credential=azure_credential,
        storage_account=os.environ["AZURE_STORAGE_ACCOUNT"],
        storage_container=os.environ["AZURE_STORAGE_CONTAINER"],
        storage_resource_group=os.environ["AZURE_STORAGE_RESOURCE_GROUP"],
        subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
        search_images=os.getenv("USE_GPT4V", "").lower() == "true",
    )

    # Set up source blob strategy
    list_file_strategy = setup_list_file_strategy(
        azure_credential=azure_credential,
        local_files=None,
        datalake_storage_account=None,
        datalake_filesystem=None,
        datalake_path=None,
        datalake_key=None,
        blob_storage_account=SOURCE_BLOB_ACCOUNT,
        blob_container=SOURCE_BLOB_CONTAINER,
        blob_path_prefix=SOURCE_BLOB_PATH_PREFIX,
        blob_storage_key=None,
    )

    # Set up embeddings
    embeddings_service = setup_embeddings_service(
        azure_credential=azure_credential,
        openai_host=os.environ["OPENAI_HOST"],
        openai_model_name=os.environ["AZURE_OPENAI_EMB_MODEL_NAME"],
        openai_service=os.environ.get("AZURE_OPENAI_SERVICE"),
        openai_custom_url=os.environ.get("AZURE_OPENAI_CUSTOM_URL"),
        openai_deployment=os.environ.get("AZURE_OPENAI_EMB_DEPLOYMENT"),
        openai_dimensions=int(os.environ.get("AZURE_OPENAI_EMB_DIMENSIONS", 1536)),
        openai_api_version=os.environ.get("AZURE_OPENAI_API_VERSION", "2024-06-01"),
        openai_key=None,
        openai_org=None,
        disable_vectors=os.getenv("USE_VECTORS", "").lower() == "false",
    )

    # Set up file processors
    file_processors = setup_file_processors(
        azure_credential=azure_credential,
        document_intelligence_service=os.environ.get("AZURE_DOCUMENTINTELLIGENCE_SERVICE"),
        local_pdf_parser=os.getenv("USE_LOCAL_PDF_PARSER", "").lower() == "true",
        local_html_parser=os.getenv("USE_LOCAL_HTML_PARSER", "").lower() == "true",
        search_images=os.getenv("USE_GPT4V", "").lower() == "true",
    )

    # Create processing strategy
    strategy = FileStrategy(
        search_info=search_info,
        list_file_strategy=list_file_strategy,
        blob_manager=blob_manager,
        file_processors=file_processors,
        document_action=DocumentAction.Add,
        embeddings=embeddings_service,
        search_field_name_embedding=os.environ.get("AZURE_SEARCH_FIELD_NAME_EMBEDDING", "embedding"),
        use_acls=False,
        category=None,
    )

    # Run processing
    await main(strategy, setup_index=True)
    logging.info("Document processing completed successfully!")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(process_documents_from_blob())
