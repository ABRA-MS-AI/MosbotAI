[1mdiff --git a/.github/workflows/process-documents.yml b/.github/workflows/process-documents.yml[m
[1mnew file mode 100644[m
[1mindex 0000000..7f2fbb2[m
[1m--- /dev/null[m
[1m+++ b/.github/workflows/process-documents.yml[m
[36m@@ -0,0 +1,51 @@[m
[32m+[m[32mname: Process Documents from Blob Storage[m
[32m+[m
[32m+[m[32mon:[m
[32m+[m[32m  workflow_dispatch:  # Manual trigger[m
[32m+[m[32m    inputs:[m
[32m+[m[32m      source_container:[m
[32m+[m[32m        description: 'Source blob container name'[m
[32m+[m[32m        required: true[m
[32m+[m[32m        default: 'documents'[m
[32m+[m[32m      path_prefix:[m
[32m+[m[32m        description: 'Path prefix (optional)'[m
[32m+[m[32m        required: false[m
[32m+[m[32m        default: ''[m
[32m+[m
[32m+[m[32mjobs:[m
[32m+[m[32m  process-docs:[m
[32m+[m[32m    runs-on: ubuntu-latest[m
[32m+[m[41m    [m
[32m+[m[32m    steps:[m
[32m+[m[32m    - uses: actions/checkout@v4[m
[32m+[m[41m    [m
[32m+[m[32m    - name: Set up Python[m
[32m+[m[32m      uses: actions/setup-python@v4[m
[32m+[m[32m      with:[m
[32m+[m[32m        python-version: '3.11'[m
[32m+[m[41m    [m
[32m+[m[32m    - name: Install dependencies[m
[32m+[m[32m      run: |[m
[32m+[m[32m        cd app/backend[m
[32m+[m[32m        pip install -r requirements.txt[m
[32m+[m[41m    [m
[32m+[m[32m    - name: Azure Login[m
[32m+[m[32m      uses: azure/login@v1[m
[32m+[m[32m      with:[m
[32m+[m[32m        client-id: ${{ secrets.AZURE_CLIENT_ID }}[m
[32m+[m[32m        tenant-id: ${{ secrets.AZURE_TENANT_ID }}[m
[32m+[m[32m        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}[m
[32m+[m[41m    [m
[32m+[m[32m    - name: Process Documents[m
[32m+[m[32m      env:[m
[32m+[m[32m        AZURE_SOURCE_BLOB_STORAGE_ACCOUNT: ${{ vars.AZURE_SOURCE_BLOB_STORAGE_ACCOUNT }}[m
[32m+[m[32m        AZURE_SOURCE_BLOB_CONTAINER: ${{ github.event.inputs.source_container }}[m
[32m+[m[32m        AZURE_SOURCE_BLOB_PATH_PREFIX: ${{ github.event.inputs.path_prefix }}[m
[32m+[m[32m        AZURE_STORAGE_ACCOUNT: ${{ vars.AZURE_STORAGE_ACCOUNT }}[m
[32m+[m[32m        AZURE_STORAGE_CONTAINER: ${{ vars.AZURE_STORAGE_CONTAINER }}[m
[32m+[m[32m        AZURE_SEARCH_SERVICE: ${{ vars.AZURE_SEARCH_SERVICE }}[m
[32m+[m[32m        AZURE_SEARCH_INDEX: ${{ vars.AZURE_SEARCH_INDEX }}[m
[32m+[m[32m        # Add other required environment variables from your azd env[m
[32m+[m[32m      run: |[m
[32m+[m[32m        cd scripts[m
[32m+[m[32m        python process_blob_docs.py[m
[1mdiff --git a/app/backend/prepdocs_blob.py b/app/backend/prepdocs_blob.py[m
[1mnew file mode 100644[m
[1mindex 0000000..8cbbbf0[m
[1m--- /dev/null[m
[1m+++ b/app/backend/prepdocs_blob.py[m
[36m@@ -0,0 +1,274 @@[m
[32m+[m[32m#!/usr/bin/env python3[m
[32m+[m[32m"""[m
[32m+[m[32mPrepdocs script specifically for blob storage sources[m
[32m+[m[32mThis bypasses the local file requirements of the original prepdocs.py[m
[32m+[m[32m"""[m
[32m+[m[32mimport argparse[m
[32m+[m[32mimport asyncio[m
[32m+[m[32mimport logging[m
[32m+[m[32mimport os[m
[32m+[m[32mfrom typing import Optional[m
[32m+[m
[32m+[m[32mfrom azure.identity.aio import AzureDeveloperCliCredential, ManagedIdentityCredential[m
[32m+[m[32mfrom rich.logging import RichHandler[m
[32m+[m
[32m+[m[32mfrom load_azd_env import load_azd_env[m
[32m+[m[32mfrom prepdocs import ([m
[32m+[m[32m    clean_key_if_exists,[m
[32m+[m[32m    setup_search_info,[m
[32m+[m[32m    setup_blob_manager,[m
[32m+[m[32m    setup_list_file_strategy,[m
[32m+[m[32m    setup_embeddings_service,[m
[32m+[m[32m    setup_file_processors,[m
[32m+[m[32m    setup_image_embeddings_service,[m
[32m+[m[32m    main[m
[32m+[m[32m)[m
[32m+[m[32mfrom prepdocslib.filestrategy import FileStrategy[m
[32m+[m[32mfrom prepdocslib.integratedvectorizerstrategy import IntegratedVectorizerStrategy[m
[32m+[m[32mfrom prepdocslib.strategy import DocumentAction[m
[32m+[m
[32m+[m[32mlogger = logging.getLogger("scripts")[m
[32m+[m
[32m+[m[32masync def main_blob_processing([m
[32m+[m[32m    source_storage_account: str,[m
[32m+[m[32m    source_container: str,[m
[32m+[m[32m    source_path_prefix: Optional[str] = None,[m
[32m+[m[32m    source_storage_key: Optional[str] = None,[m
[32m+[m[32m    remove_all: bool = False,[m
[32m+[m[32m    remove: bool = False,[m
[32m+[m[32m    category: Optional[str] = None[m
[32m+[m[32m):[m
[32m+[m[32m    """Main function for processing documents from blob storage"""[m
[32m+[m[41m    [m
[32m+[m[32m    load_azd_env()[m
[32m+[m[41m    [m
[32m+[m[32m    # Detect if running in Azure (use managed identity) or local (use azd credential)[m
[32m+[m[32m    RUNNING_ON_AZURE = os.getenv("WEBSITE_HOSTNAME") is not None or os.getenv("RUNNING_IN_PRODUCTION") is not None[m
[32m+[m[41m    [m
[32m+[m[32m    if RUNNING_ON_AZURE:[m
[32m+[m[32m        logger.info("Using ManagedIdentityCredential")[m
[32m+[m[32m        azure_credential = ManagedIdentityCredential()[m
[32m+[m[32m    else:[m
[32m+[m[32m        if tenant_id := os.getenv("AZURE_TENANT_ID"):[m
[32m+[m[32m            logger.info("Using AzureDeveloperCliCredential with tenant %s", tenant_id)[m
[32m+[m[32m            azure_credential = AzureDeveloperCliCredential(tenant_id=tenant_id, process_timeout=60)[m
[32m+[m[32m        else:[m
[32m+[m[32m            logger.info("Using AzureDeveloperCliCredential for home tenant")[m
[32m+[m[32m            azure_credential = AzureDeveloperCliCredential(process_timeout=60)[m
[32m+[m[41m    [m
[32m+[m[32m    # Determine document action[m
[32m+[m[32m    if remove_all:[m
[32m+[m[32m        document_action = DocumentAction.RemoveAll[m
[32m+[m[32m    elif remove:[m
[32m+[m[32m        document_action = DocumentAction.Remove[m
[32m+[m[32m    else:[m
[32m+[m[32m        document_action = DocumentAction.Add[m
[32m+[m[41m    [m
[32m+[m[32m    # Check for required environment variables[m
[32m+[m[32m    required_vars = [[m
[32m+[m[32m        "AZURE_SEARCH_SERVICE",[m
[32m+[m[32m        "AZURE_SEARCH_INDEX",[m[41m [m
[32m+[m[32m        "AZURE_STORAGE_ACCOUNT",[m
[32m+[m[32m        "AZURE_STORAGE_CONTAINER",[m
[32m+[m[32m        "AZURE_STORAGE_RESOURCE_GROUP",[m
[32m+[m[32m        "AZURE_SUBSCRIPTION_ID"[m
[32m+[m[32m    ][m
[32m+[m[41m    [m
[32m+[m[32m    missing_vars = [var for var in required_vars if not os.getenv(var)][m
[32m+[m[32m    if missing_vars:[m
[32m+[m[32m        raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")[m
[32m+[m[41m    [m
[32m+[m[32m    # Setup configurations[m
[32m+[m[32m    use_int_vectorization = os.getenv("USE_FEATURE_INT_VECTORIZATION", "").lower() == "true"[m
[32m+[m[32m    use_gptvision = os.getenv("USE_GPT4V", "").lower() == "true"[m
[32m+[m[32m    use_acls = os.getenv("AZURE_ENFORCE_ACCESS_CONTROL") is not None[m
[32m+[m[32m    dont_use_vectors = os.getenv("USE_VECTORS", "").lower() == "false"[m
[32m+[m[32m    use_agentic_retrieval = os.getenv("USE_AGENTIC_RETRIEVAL", "").lower() == "true"[m
[32m+[m[41m    [m
[32m+[m[32m    logger.info("Processing documents from blob storage:")[m
[32m+[m[32m    logger.info("  Source: %s/%s/%s", source_storage_account, source_container, source_path_prefix or "")[m
[32m+[m[32m    logger.info("  Action: %s", document_action.name)[m
[32m+[m[32m    logger.info("  Use integrated vectorization: %s", use_int_vectorization)[m
[32m+[m[32m    logger.info("  Use GPT Vision: %s", use_gptvision)[m
[32m+[m[41m    [m
[32m+[m[32m    # Setup search info[m
[32m+[m[32m    search_info = await setup_search_info([m
[32m+[m[32m        search_service=os.environ["AZURE_SEARCH_SERVICE"],[m
[32m+[m[32m        index_name=os.environ["AZURE_SEARCH_INDEX"],[m
[32m+[m[32m        use_agentic_retrieval=use_agentic_retrieval,[m
[32m+[m[32m        agent_name=os.getenv("AZURE_SEARCH_AGENT"),[m
[32m+[m[32m        agent_max_output_tokens=int(os.getenv("AZURE_SEARCH_AGENT_MAX_OUTPUT_TOKENS", 10000)),[m
[32m+[m[32m        azure_openai_endpoint=os.environ.get("AZURE_OPENAI_ENDPOINT"),[m
[32m+[m[32m        azure_openai_searchagent_deployment=os.getenv("AZURE_OPENAI_SEARCHAGENT_DEPLOYMENT"),[m
[32m+[m[32m        azure_openai_searchagent_model=os.getenv("AZURE_OPENAI_SEARCHAGENT_MODEL"),[m
[32m+[m[32m        azure_credential=azure_credential,[m
[32m+[m[32m        search_key=None[m
[32m+[m[32m    )[m
[32m+[m[41m    [m
[32m+[m[32m    # Setup blob manager for destination (where processed chunks go)[m
[32m+[m[32m    blob_manager = setup_blob_manager([m
[32m+[m[32m        azure_credential=azure_credential,[m
[32m+[m[32m        storage_account=os.environ["AZURE_STORAGE_ACCOUNT"],[m
[32m+[m[32m        storage_container=os.environ["AZURE_STORAGE_CONTAINER"],[m
[32m+[m[32m        storage_resource_group=os.environ["AZURE_STORAGE_RESOURCE_GROUP"],[m
[32m+[m[32m        subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],[m
[32m+[m[32m        search_images=use_gptvision,[m
[32m+[m[32m        storage_key=None[m
[32m+[m[32m    )[m
[32m+[m[41m    [m
[32m+[m[32m    # Setup source file strategy (blob storage)[m
[32m+[m[32m    list_file_strategy = setup_list_file_strategy([m
[32m+[m[32m        azure_credential=azure_credential,[m
[32m+[m[32m        local_files=None,  # No local files[m
[32m+[m[32m        datalake_storage_account=None,[m
[32m+[m[32m        datalake_filesystem=None,[m
[32m+[m[32m        datalake_path=None,[m
[32m+[m[32m        datalake_key=None,[m
[32m+[m[32m        blob_storage_account=source_storage_account,[m
[32m+[m[32m        blob_container=source_container,[m
[32m+[m[32m        blob_path_prefix=source_path_prefix,[m
[32m+[m[32m        blob_storage_key=source_storage_key[m
[32m+[m[32m    )[m
[32m+[m[41m    [m
[32m+[m[32m    # Setup embeddings service[m
[32m+[m[32m    openai_host = os.environ["OPENAI_HOST"][m
[32m+[m[32m    openai_key = None[m
[32m+[m[32m    if os.getenv("AZURE_OPENAI_API_KEY_OVERRIDE"):[m
[32m+[m[32m        openai_key = os.getenv("AZURE_OPENAI_API_KEY_OVERRIDE")[m
[32m+[m[32m    elif not openai_host.startswith("azure") and os.getenv("OPENAI_API_KEY"):[m
[32m+[m[32m        openai_key = os.getenv("OPENAI_API_KEY")[m
[32m+[m[41m    [m
[32m+[m[32m    embeddings_service = setup_embeddings_service([m
[32m+[m[32m        azure_credential=azure_credential,[m
[32m+[m[32m        openai_host=openai_host,[m
[32m+[m[32m        openai_model_name=os.environ["AZURE_OPENAI_EMB_MODEL_NAME"],[m
[32m+[m[32m        openai_service=os.getenv("AZURE_OPENAI_SERVICE"),[m
[32m+[m[32m        openai_custom_url=os.getenv("AZURE_OPENAI_CUSTOM_URL"),[m
[32m+[m[32m        openai_deployment=os.getenv("AZURE_OPENAI_EMB_DEPLOYMENT"),[m
[32m+[m[32m        openai_api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-06-01"),[m
[32m+[m[32m        openai_dimensions=int(os.getenv("AZURE_OPENAI_EMB_DIMENSIONS", 1536)),[m
[32m+[m[32m        openai_key=clean_key_if_exists(openai_key),[m
[32m+[m[32m        openai_org=os.getenv("OPENAI_ORGANIZATION"),[m
[32m+[m[32m        disable_vectors=dont_use_vectors,[m
[32m+[m[32m        disable_batch_vectors=False[m
[32m+[m[32m    )[m
[32m+[m[41m    [m
[32m+[m[32m    # Choose strategy[m
[32m+[m[32m    if use_int_vectorization:[m
[32m+[m[32m        # Use integrated vectorization[m
[32m+[m[32m        strategy = IntegratedVectorizerStrategy([m
[32m+[m[32m            search_info=search_info,[m
[32m+[m[32m            list_file_strategy=list_file_strategy,[m
[32m+[m[32m            blob_manager=blob_manager,[m
[32m+[m[32m            document_action=document_action,[m
[32m+[m[32m            embeddings=embeddings_service,[m
[32m+[m[32m            search_field_name_embedding=os.environ["AZURE_SEARCH_FIELD_NAME_EMBEDDING"],[m
[32m+[m[32m            subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],[m
[32m+[m[32m            search_service_user_assigned_id=None,  # You'd need to add this if using integrated vectorization[m
[32m+[m[32m            search_analyzer_name=os.getenv("AZURE_SEARCH_ANALYZER_NAME"),[m
[32m+[m[32m            use_acls=use_acls,[m
[32m+[m[32m            category=category[m
[32m+[m[32m        )[m
[32m+[m[32m    else:[m
[32m+[m[32m        # Use file strategy[m
[32m+[m[32m        file_processors = setup_file_processors([m
[32m+[m[32m            azure_credential=azure_credential,[m
[32m+[m[32m            document_intelligence_service=os.getenv("AZURE_DOCUMENTINTELLIGENCE_SERVICE"),[m
[32m+[m[32m            document_intelligence_key=None,[m
[32m+[m[32m            local_pdf_parser=os.getenv("USE_LOCAL_PDF_PARSER", "").lower() == "true",[m
[32m+[m[32m            local_html_parser=os.getenv("USE_LOCAL_HTML_PARSER", "").lower() == "true",[m
[32m+[m[32m            search_images=use_gptvision[m
[32m+[m[32m        )[m
[32m+[m[41m        [m
[32m+[m[32m        image_embeddings_service = setup_image_embeddings_service([m
[32m+[m[32m            azure_credential=azure_credential,[m
[32m+[m[32m            vision_endpoint=os.getenv("AZURE_VISION_ENDPOINT"),[m
[32m+[m[32m            search_images=use_gptvision[m
[32m+[m[32m        )[m
[32m+[m[41m        [m
[32m+[m[32m        strategy = FileStrategy([m
[32m+[m[32m            search_info=search_info,[m
[32m+[m[32m            list_file_strategy=list_file_strategy,[m
[32m+[m[32m            blob_manager=blob_manager,[m
[32m+[m[32m            file_processors=file_processors,[m
[32m+[m[32m            document_action=document_action,[m
[32m+[m[32m            embeddings=embeddings_service,[m
[32m+[m[32m            image_embeddings=image_embeddings_service,[m
[32m+[m[32m            search_analyzer_name=os.getenv("AZURE_SEARCH_ANALYZER_NAME"),[m
[32m+[m[32m            search_field_name_embedding=os.getenv("AZURE_SEARCH_FIELD_NAME_EMBEDDING", "embedding"),[m
[32m+[m[32m            use_acls=use_acls,[m
[32m+[m[32m            category=category[m
[32m+[m[32m        )[m
[32m+[m[41m    [m
[32m+[m[32m    # Run the processing[m
[32m+[m[32m    await main(strategy, setup_index=not remove and not remove_all)[m
[32m+[m
[32m+[m[32mif __name__ == "__main__":[m
[32m+[m[32m    parser = argparse.ArgumentParser([m
[32m+[m[32m        description="Process documents from Azure Blob Storage into search index"[m
[32m+[m[32m    )[m
[32m+[m[41m    [m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--source-account",[m
[32m+[m[32m        required=True,[m
[32m+[m[32m        help="Source Azure Blob Storage account name"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--source-container",[m[41m [m
[32m+[m[32m        required=True,[m
[32m+[m[32m        help="Source Azure Blob Storage container name"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--source-prefix",[m
[32m+[m[32m        help="Optional path prefix within the source container"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--source-key",[m
[32m+[m[32m        help="Optional storage key for source account (use managed identity if not provided)"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--category",[m
[32m+[m[32m        help="Category to assign to all processed documents"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--remove",[m
[32m+[m[32m        action="store_true",[m
[32m+[m[32m        help="Remove documents instead of adding them"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument([m
[32m+[m[32m        "--remove-all",[m
[32m+[m[32m        action="store_true",[m[41m [m
[32m+[m[32m        help="Remove all documents from the index"[m
[32m+[m[32m    )[m
[32m+[m[32m    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")[m
[32m+[m[41m    [m
[32m+[m[32m    args = parser.parse_args()[m
[32m+[m[41m    [m
[32m+[m[32m    if args.verbose:[m
[32m+[m[32m        logging.basicConfig([m
[32m+[m[32m            format="%(message)s",[m[41m [m
[32m+[m[32m            datefmt="[%X]",[m[41m [m
[32m+[m[32m            handlers=[RichHandler(rich_tracebacks=True)][m
[32m+[m[32m        )[m
[32m+[m[32m        logger.setLevel(logging.DEBUG)[m
[32m+[m[41m    [m
[32m+[m[32m    # Run the processing[m
[32m+[m[32m    loop = asyncio.new_event_loop()[m
[32m+[m[32m    asyncio.set_event_loop(loop)[m
[32m+[m[41m    [m
[32m+[m[32m    try:[m
[32m+[m[32m        loop.run_until_complete(main_blob_processing([m
[32m+[m[32m            source_storage_account=args.source_account,[m
[32m+[m[32m            source_container=args.source_container,[m
[32m+[m[32m            source_path_prefix=args.source_prefix,[m
[32m+[m[32m            source_storage_key=args.source_key,[m
[32m+[m[32m            remove_all=args.remove_all,[m
[32m+[m[32m            remove=args.remove,[m
[32m+[m[32m            category=args.category[m
[32m+[m[32m        ))[m
[32m+[m[32m        logger.info("Processing completed successfully!")[m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        logger.error("Processing failed: %s", str(e))[m
[32m+[m[32m        raise[m
[32m+[m[32m    finally:[m
[32m+[m[32m        loop.close()[m
[1mdiff --git a/app/backend/prepdocslib/bloblistfilestrategy.py b/app/backend/prepdocslib/bloblistfilestrategy.py[m
[1mnew file mode 100644[m
[1mindex 0000000..1ff2420[m
[1m--- /dev/null[m
[1m+++ b/app/backend/prepdocslib/bloblistfilestrategy.py[m
[36m@@ -0,0 +1,130 @@[m
[32m+[m[32m# prepdocslib/bloblistfilestrategy.py - Fixed implementation with proper cleanup[m
[32m+[m
[32m+[m[32mimport hashlib[m
[32m+[m[32mimport logging[m
[32m+[m[32mimport os[m
[32m+[m[32mimport tempfile[m
[32m+[m[32mfrom collections.abc import AsyncGenerator[m
[32m+[m[32mfrom typing import Union[m
[32m+[m[32mfrom datetime import datetime, timezone[m
[32m+[m
[32m+[m[32mfrom azure.core.credentials_async import AsyncTokenCredential[m
[32m+[m[32mfrom azure.storage.blob.aio import BlobServiceClient[m
[32m+[m
[32m+[m[32mfrom .listfilestrategy import File, ListFileStrategy[m
[32m+[m
[32m+[m[32mlogger = logging.getLogger("scripts")[m
[32m+[m
[32m+[m
[32m+[m[32mclass BlobFile(File):[m
[32m+[m[32m    """Extended File class that tracks temp files for cleanup"""[m
[32m+[m[32m    def __init__(self, content, acls=None, url=None, temp_path=None):[m
[32m+[m[32m        super().__init__(content, acls, url)[m
[32m+[m[32m        self.temp_path = temp_path[m
[32m+[m[41m    [m
[32m+[m[32m    def close(self):[m
[32m+[m[32m        super().close()[m
[32m+[m[32m        # Clean up temp file[m
[32m+[m[32m        if self.temp_path and os.path.exists(self.temp_path):[m
[32m+[m[32m            try:[m
[32m+[m[32m                os.remove(self.temp_path)[m
[32m+[m[32m                logger.debug(f"Cleaned up temp file: {self.temp_path}")[m
[32m+[m[32m            except Exception as e:[m
[32m+[m[32m                logger.warning(f"Could not cleanup temp file {self.temp_path}: {e}")[m
[32m+[m
[32m+[m
[32m+[m[32mclass BlobListFileStrategy(ListFileStrategy):[m
[32m+[m[32m    """[m
[32m+[m[32m    Concrete strategy for listing files that are located in Azure Blob Storage (non-HNS)[m
[32m+[m[32m    """[m
[32m+[m
[32m+[m[32m    def __init__([m
[32m+[m[32m        self,[m
[32m+[m[32m        storage_account: str,[m
[32m+[m[32m        container_name: str,[m
[32m+[m[32m        blob_path_prefix: str = "",[m
[32m+