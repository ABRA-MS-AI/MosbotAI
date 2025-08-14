# prepdocslib/bloblistfilestrategy.py - Fixed implementation with proper cleanup

import logging
import os
import tempfile
from collections.abc import AsyncGenerator
from typing import Union

from azure.core.credentials_async import AsyncTokenCredential
from azure.storage.blob.aio import BlobServiceClient

from .listfilestrategy import File, ListFileStrategy

logger = logging.getLogger("scripts")


class BlobFile(File):
    """Extended File class that tracks temp files for cleanup"""
    def __init__(self, content, acls=None, url=None, temp_path=None):
        super().__init__(content, acls, url)
        self.temp_path = temp_path
    
    def close(self):
        super().close()
        # Clean up temp file
        if self.temp_path and os.path.exists(self.temp_path):
            try:
                os.remove(self.temp_path)
                logger.debug(f"Cleaned up temp file: {self.temp_path}")
            except Exception as e:
                logger.warning(f"Could not cleanup temp file {self.temp_path}: {e}")


class BlobListFileStrategy(ListFileStrategy):
    """
    Concrete strategy for listing files that are located in Azure Blob Storage (non-HNS)
    """

    def __init__(
        self,
        storage_account: str,
        container_name: str,
        blob_path_prefix: str = "",
        credential: Optional[Union[AsyncTokenCredential, str]] = None,
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
            
            try:
                if not await container_client.exists():
                    logger.warning(f"Container {self.container_name} does not exist")
                    return
            except Exception as e:
                logger.error(f"Error checking container existence: {e}")
                return
            
            try:
                async for blob in container_client.list_blobs(name_starts_with=self.blob_path_prefix):
                    # Only process actual files, not folders
                    if not blob.name.endswith('/'):
                        # Filter for supported file types
                        supported_extensions = {
                            '.pdf', '.txt', '.md', '.html', '.docx', '.pptx', 
                            '.xlsx', '.json', '.csv', '.png', '.jpg', '.jpeg', 
                            '.tiff', '.bmp', '.heic'
                        }
                        _, ext = os.path.splitext(blob.name.lower())
                        if ext in supported_extensions:
                            yield blob.name
            except Exception as e:
                logger.error(f"Error listing blobs: {e}")

    async def list(self) -> AsyncGenerator[File, None]:
        """List files for processing"""
        async with BlobServiceClient(
            account_url=self.endpoint, credential=self.credential
        ) as service_client:
            container_client = service_client.get_container_client(self.container_name)
            
            async for blob_name in self.list_paths():
                temp_file_path = None
                try:
                    blob_client = container_client.get_blob_client(blob_name)
                    
                    # Create unique temp file to avoid conflicts
                    safe_name = blob_name.replace('/', '_').replace('\\', '_')
                    temp_file_path = os.path.join(
                        tempfile.gettempdir(), 
                        f"blob_{hash(blob_name)}_{safe_name}"
                    )
                    
                    logger.info(f"Downloading blob {blob_name} to {temp_file_path}")
                    
                    # Download blob
                    with open(temp_file_path, "wb") as temp_file:
                        blob_data = await blob_client.download_blob()
                        async for chunk in blob_data.chunks():
                            temp_file.write(chunk)
                    
                    # Create File object with proper cleanup
                    file_obj = BlobFile(
                        content=open(temp_file_path, "rb"),
                        acls=None,  # No ACLs for basic blob storage
                        url=blob_client.url,
                        temp_path=temp_file_path
                    )
                    
                    yield file_obj
                    
                except Exception as e:
                    logger.error(f"Error processing blob {blob_name}: {e}")
                    # Clean up temp file on error
                    if temp_file_path and os.path.exists(temp_file_path):
                        try:
                            os.remove(temp_file_path)
                        except Exception:  # Specify the exception type
                            pass
                    continue
