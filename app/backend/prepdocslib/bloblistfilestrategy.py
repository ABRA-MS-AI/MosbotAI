# prepdocslib/bloblistfilestrategy.py - Fixed implementation

import hashlib
import logging
import os
import tempfile
from collections.abc import AsyncGenerator
from typing import Union
from datetime import datetime, timezone

from azure.core.credentials_async import AsyncTokenCredential
from azure.storage.blob.aio import BlobServiceClient

from .listfilestrategy import File, ListFileStrategy

logger = logging.getLogger("scripts")


class BlobListFileStrategy(ListFileStrategy):
    """
    Concrete strategy for listing files that are located in Azure Blob Storage (non-HNS)
    """

    def __init__(
        self,
        storage_account: str,
        container_name: str,
        blob_path_prefix: str = "",
        credential: Union[AsyncTokenCredential, str] = None,
    ):
        self.storage_account = storage_account
        self.container_name = container_name
        self.blob_path_prefix = blob_path_prefix.strip("/") + "/" if blob_path_prefix else ""
        self.credential = credential
        self.endpoint = f"https://{storage_account}.blob.core.windows.net"

    async def list_paths(self) -> AsyncGenerator[str, None]:
        """List all blob paths in the container"""
        async with BlobServiceClient(
            account_url=self.endpoint, credential=self.credential
        ) as service_client:
            container_client = service_client.get_container_client(self.container_name)
            
            if not await container_client.exists():
                logger.warning(f"Container {self.container_name} does not exist")
                return
            
            async for blob in container_client.list_blobs(name_starts_with=self.blob_path_prefix):
                # Only process actual files, not folders
                if not blob.name.endswith('/'):
                    # Filter for supported file types
                    supported_extensions = {'.pdf', '.txt', '.md', '.html', '.docx', '.pptx', '.xlsx', '.json', '.csv'}
                    _, ext = os.path.splitext(blob.name.lower())
                    if ext in supported_extensions:
                        yield blob.name

    async def list(self) -> AsyncGenerator[File, None]:
        """List files for processing"""
        async with BlobServiceClient(
            account_url=self.endpoint, credential=self.credential
        ) as service_client:
            container_client = service_client.get_container_client(self.container_name)
            
            async for blob_name in self.list_paths():
                try:
                    blob_client = container_client.get_blob_client(blob_name)
                    
                    # Download blob to temporary file
                    temp_file_path = os.path.join(tempfile.gettempdir(), os.path.basename(blob_name))
                    
                    with open(temp_file_path, "wb") as temp_file:
                        blob_data = await blob_client.download_blob()
                        async for chunk in blob_data.chunks():
                            temp_file.write(chunk)
                    
                    # Create File object with blob URL
                    file_obj = File(
                        content=open(temp_file_path, "rb"),
                        acls=None,  # No ACLs for basic blob storage
                        url=blob_client.url
                    )
                    
                    yield file_obj
                    
                except Exception as e:
                    logger.error(f"Error processing blob {blob_name}: {e}")
                    continue
