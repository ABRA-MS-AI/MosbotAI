#!/usr/bin/env python3
"""
Prepdocs script specifically for blob storage sources
This bypasses the local file requirements of the original prepdocs.py
"""
import argparse
import asyncio
import logging
import os
from typing import Optional

from azure.identity.aio import AzureDeveloperCliCredential, ManagedIdentityCredential
from rich.logging import RichHandler

from load_azd_env import load_azd_env
from prepdocs import (
    clean_key_if_exists,
    main,
    setup_blob_manager,
    setup_embeddings_service,
    setup_file_processors,
    setup_image_embeddings_service,
    setup_list_file_strategy,
    setup_search_info,
)
from prepdocslib.filestrategy import FileStrategy
from prepdocslib.integratedvectorizerstrategy import IntegratedVectorizerStrategy
from prepdocslib.strategy import DocumentAction

logger = logging.getLogger("scripts")

async def main_blob_processing(
    source_storage_account: str,
    source_container: str,
    source_path_prefix: Optional[str] = None,
    source_storage_key: Optional[str] = None,
    remove_all: bool = False,
    remove: bool = False,
    category: Optional[str] = None
):
    """Main function for processing documents from blob storage"""
    
    load_azd_env()
    
    # Detect if running in Azure (use managed identity) or local (use azd credential)
    RUNNING_ON_AZURE = os.getenv("WEBSITE_HOSTNAME") is not None or os.getenv("RUNNING_IN_PRODUCTION") is not None
    
    if RUNNING_ON_AZURE:
        logger.info("Using ManagedIdentityCredential")
        azure_credential = ManagedIdentityCredential()
    else:
        if tenant_id := os.getenv("AZURE_TENANT_ID"):
            logger.info("Using AzureDeveloperCliCredential with tenant %s", tenant_id)
            azure_credential = AzureDeveloperCliCredential(tenant_id=tenant_id, process_timeout=60)
        else:
            logger.info("Using AzureDeveloperCliCredential for home tenant")
            azure_credential = AzureDeveloperCliCredential(process_timeout=60)
    
    # Determine document action
    if remove_all:
        document_action = DocumentAction.RemoveAll
    elif remove:
        document_action = DocumentAction.Remove
    else:
        document_action = DocumentAction.Add
    
    # Check for required environment variables
    required_vars = [
        "AZURE_SEARCH_SERVICE",
        "AZURE_SEARCH_INDEX", 
        "AZURE_STORAGE_ACCOUNT",
        "AZURE_STORAGE_CONTAINER",
        "AZURE_STORAGE_RESOURCE_GROUP",
        "AZURE_SUBSCRIPTION_ID"
    ]
    
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    if missing_vars:
        raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")
    
    # Setup configurations
    use_int_vectorization = os.getenv("USE_FEATURE_INT_VECTORIZATION", "").lower() == "true"
    use_gptvision = os.getenv("USE_GPT4V", "").lower() == "true"
    use_acls = os.getenv("AZURE_ENFORCE_ACCESS_CONTROL") is not None
    dont_use_vectors = os.getenv("USE_VECTORS", "").lower() == "false"
    use_agentic_retrieval = os.getenv("USE_AGENTIC_RETRIEVAL", "").lower() == "true"
    
    logger.info("Processing documents from blob storage:")
    logger.info("  Source: %s/%s/%s", source_storage_account, source_container, source_path_prefix or "")
    logger.info("  Action: %s", document_action.name)
    logger.info("  Use integrated vectorization: %s", use_int_vectorization)
    logger.info("  Use GPT Vision: %s", use_gptvision)
    
    # Setup search info
    search_info = await setup_search_info(
        search_service=os.environ["AZURE_SEARCH_SERVICE"],
        index_name=os.environ["AZURE_SEARCH_INDEX"],
        use_agentic_retrieval=use_agentic_retrieval,
        agent_name=os.getenv("AZURE_SEARCH_AGENT"),
        agent_max_output_tokens=int(os.getenv("AZURE_SEARCH_AGENT_MAX_OUTPUT_TOKENS", 10000)),
        azure_openai_endpoint=os.environ.get("AZURE_OPENAI_ENDPOINT"),
        azure_openai_searchagent_deployment=os.getenv("AZURE_OPENAI_SEARCHAGENT_DEPLOYMENT"),
        azure_openai_searchagent_model=os.getenv("AZURE_OPENAI_SEARCHAGENT_MODEL"),
        azure_credential=azure_credential,
        search_key=None
    )
    
    # Setup blob manager for destination (where processed chunks go)
    blob_manager = setup_blob_manager(
        azure_credential=azure_credential,
        storage_account=os.environ["AZURE_STORAGE_ACCOUNT"],
        storage_container=os.environ["AZURE_STORAGE_CONTAINER"],
        storage_resource_group=os.environ["AZURE_STORAGE_RESOURCE_GROUP"],
        subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
        search_images=use_gptvision,
        storage_key=None
    )
    
    # Setup source file strategy (blob storage)
    list_file_strategy = setup_list_file_strategy(
        azure_credential=azure_credential,
        local_files=None,  # No local files
        datalake_storage_account=None,
        datalake_filesystem=None,
        datalake_path=None,
        datalake_key=None,
        blob_storage_account=source_storage_account,
        blob_container=source_container,
        blob_path_prefix=source_path_prefix,
        blob_storage_key=source_storage_key
    )
    
    # Setup embeddings service
    openai_host = os.environ["OPENAI_HOST"]
    openai_key = None
    if os.getenv("AZURE_OPENAI_API_KEY_OVERRIDE"):
        openai_key = os.getenv("AZURE_OPENAI_API_KEY_OVERRIDE")
    elif not openai_host.startswith("azure") and os.getenv("OPENAI_API_KEY"):
        openai_key = os.getenv("OPENAI_API_KEY")
    
    embeddings_service = setup_embeddings_service(
        azure_credential=azure_credential,
        openai_host=openai_host,
        openai_model_name=os.environ["AZURE_OPENAI_EMB_MODEL_NAME"],
        openai_service=os.getenv("AZURE_OPENAI_SERVICE"),
        openai_custom_url=os.getenv("AZURE_OPENAI_CUSTOM_URL"),
        openai_deployment=os.getenv("AZURE_OPENAI_EMB_DEPLOYMENT"),
        openai_api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-06-01"),
        openai_dimensions=int(os.getenv("AZURE_OPENAI_EMB_DIMENSIONS", 1536)),
        openai_key=clean_key_if_exists(openai_key),
        openai_org=os.getenv("OPENAI_ORGANIZATION"),
        disable_vectors=dont_use_vectors,
        disable_batch_vectors=False
    )
    
    # Choose strategy
    if use_int_vectorization:
        # Use integrated vectorization
        strategy = IntegratedVectorizerStrategy(
            search_info=search_info,
            list_file_strategy=list_file_strategy,
            blob_manager=blob_manager,
            document_action=document_action,
            embeddings=embeddings_service,
            search_field_name_embedding=os.environ["AZURE_SEARCH_FIELD_NAME_EMBEDDING"],
            subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
            search_service_user_assigned_id=None,  # You'd need to add this if using integrated vectorization
            search_analyzer_name=os.getenv("AZURE_SEARCH_ANALYZER_NAME"),
            use_acls=use_acls,
            category=category
        )
    else:
        # Use file strategy
        file_processors = setup_file_processors(
            azure_credential=azure_credential,
            document_intelligence_service=os.getenv("AZURE_DOCUMENTINTELLIGENCE_SERVICE"),
            document_intelligence_key=None,
            local_pdf_parser=os.getenv("USE_LOCAL_PDF_PARSER", "").lower() == "true",
            local_html_parser=os.getenv("USE_LOCAL_HTML_PARSER", "").lower() == "true",
            search_images=use_gptvision
        )
        
        image_embeddings_service = setup_image_embeddings_service(
            azure_credential=azure_credential,
            vision_endpoint=os.getenv("AZURE_VISION_ENDPOINT"),
            search_images=use_gptvision
        )
        
        strategy = FileStrategy(
            search_info=search_info,
            list_file_strategy=list_file_strategy,
            blob_manager=blob_manager,
            file_processors=file_processors,
            document_action=document_action,
            embeddings=embeddings_service,
            image_embeddings=image_embeddings_service,
            search_analyzer_name=os.getenv("AZURE_SEARCH_ANALYZER_NAME"),
            search_field_name_embedding=os.getenv("AZURE_SEARCH_FIELD_NAME_EMBEDDING", "embedding"),
            use_acls=use_acls,
            category=category
        )
    
    # Run the processing
    await main(strategy, setup_index=not remove and not remove_all)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process documents from Azure Blob Storage into search index"
    )
    
    parser.add_argument(
        "--source-account",
        required=True,
        help="Source Azure Blob Storage account name"
    )
    parser.add_argument(
        "--source-container", 
        required=True,
        help="Source Azure Blob Storage container name"
    )
    parser.add_argument(
        "--source-prefix",
        help="Optional path prefix within the source container"
    )
    parser.add_argument(
        "--source-key",
        help="Optional storage key for source account (use managed identity if not provided)"
    )
    parser.add_argument(
        "--category",
        help="Category to assign to all processed documents"
    )
    parser.add_argument(
        "--remove",
        action="store_true",
        help="Remove documents instead of adding them"
    )
    parser.add_argument(
        "--remove-all",
        action="store_true", 
        help="Remove all documents from the index"
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.basicConfig(
            format="%(message)s", 
            datefmt="[%X]", 
            handlers=[RichHandler(rich_tracebacks=True)]
        )
        logger.setLevel(logging.DEBUG)
    
    # Run the processing
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        loop.run_until_complete(main_blob_processing(
            source_storage_account=args.source_account,
            source_container=args.source_container,
            source_path_prefix=args.source_prefix,
            source_storage_key=args.source_key,
            remove_all=args.remove_all,
            remove=args.remove,
            category=args.category
        ))
        logger.info("Processing completed successfully!")
    except Exception as e:
        logger.error("Processing failed: %s", str(e))
        raise
    finally:
        loop.close()
