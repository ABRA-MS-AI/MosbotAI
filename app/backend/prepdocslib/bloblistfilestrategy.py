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
    Concrete strategy for listing files that are located in Azure Blob Storage
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
        """List files with change detection based on blob last modified time"""
        async with BlobServiceClient(
            account_url=self.endpoint, credential=self.credential
        ) as service_client:
            container_client = service_client.get_container_client(self.container_name)
            
            async for blob_name in self.list_paths():
                try:
                    blob_client = container_client.get_blob_client(blob_name)
                    blob_properties = await blob_client.get_blob_properties()
                    
                    # Check if file has changed using last modified time
                    if not await self._has_blob_changed(blob_client, blob_properties):
                        logger.info(f"Skipping {blob_name}, no changes detected.")
                        continue
                    
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

    async def _has_blob_changed(self, blob_client, blob_properties) -> bool:
        """
        Check if blob has changed by comparing last modified time
        with stored timestamp in a metadata file
        """
        blob_name = blob_client.blob_name
        timestamp_file = os.path.join(tempfile.gettempdir(), f"{blob_name.replace('/', '_')}.timestamp")
        
        current_modified = blob_properties.last_modified
        
        # If timestamp file doesn't exist, consider it changed
        if not os.path.exists(timestamp_file):
            await self._store_blob_timestamp(timestamp_file, current_modified)
            return True
        
        # Read stored timestamp
        try:
            with open(timestamp_file, 'r') as f:
                stored_timestamp_str = f.read().strip()
                stored_timestamp = datetime.fromisoformat(stored_timestamp_str)
                
            # Compare timestamps
            if current_modified > stored_timestamp:
                await self._store_blob_timestamp(timestamp_file, current_modified)
                return True
            else:
                return False
                
        except Exception as e:
            logger.warning(f"Error reading timestamp file for {blob_name}: {e}")
            await self._store_blob_timestamp(timestamp_file, current_modified)
            return True

    async def _store_blob_timestamp(self, timestamp_file: str, timestamp: datetime):
        """Store the blob's last modified timestamp"""
        try:
            with open(timestamp_file, 'w') as f:
                f.write(timestamp.isoformat())
        except Exception as e:
            logger.error(f"Error storing timestamp: {e}")

    async def list_changed_blobs_since(self, since_datetime: datetime) -> AsyncGenerator[str, None]:
        """
        List only blobs that have changed since a specific datetime.
        Useful for daily incremental updates.
        """
        async with BlobServiceClient(
            account_url=self.endpoint, credential=self.credential
        ) as service_client:
            container_client = service_client.get_container_client(self.container_name)
            
            async for blob_name in self.list_paths():
                try:
                    blob_client = container_client.get_blob_client(blob_name)
                    blob_properties = await blob_client.get_blob_properties()
                    
                    if blob_properties.last_modified > since_datetime:
                        yield blob_name
                        
                except Exception as e:
                    logger.error(f"Error checking blob {blob_name}: {e}")
                    continue
