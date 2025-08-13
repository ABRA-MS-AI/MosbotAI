#!/usr/bin/env python3
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Load environment variables from .env.local if it exists
env_path = Path(__file__).parent.parent / ".env.local"
if env_path.exists():
    load_dotenv(env_path)
    print(f"Loaded environment from: {env_path}")

# Add the current directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

# Set minimal environment variables to avoid Azure service dependencies
os.environ.setdefault("AZURE_USE_AUTHENTICATION", "false")
os.environ.setdefault("AZURE_ENABLE_UNAUTHENTICATED_ACCESS", "true")
os.environ.setdefault("AZURE_STORAGE_ACCOUNT", "teststorage")
os.environ.setdefault("AZURE_STORAGE_CONTAINER", "content")
os.environ.setdefault("AZURE_SEARCH_SERVICE", "testsearch")
os.environ.setdefault("AZURE_SEARCH_INDEX", "gptkbindex")
os.environ.setdefault("AZURE_OPENAI_CHATGPT_MODEL", "gpt-35-turbo")
os.environ.setdefault("AZURE_OPENAI_ENDPOINT", "https://test.openai.azure.com/")
os.environ.setdefault("AZURE_OPENAI_EMB_MODEL", "text-embedding-ada-002")

print(f"AZURE_USE_AUTHENTICATION = {os.environ.get('AZURE_USE_AUTHENTICATION')}")
print(f"AZURE_ENABLE_UNAUTHENTICATED_ACCESS = {os.environ.get('AZURE_ENABLE_UNAUTHENTICATED_ACCESS')}")

try:
    from main import app
    print("App imported successfully")
    
    # Run the server
    app.run(host="localhost", port=50505, debug=True)
    
except ImportError as e:
    print(f"Import error: {e}")
    print("Missing dependencies. Install with: pip install -r requirements.txt")
    sys.exit(1)
except Exception as e:
    print(f"Error starting server: {e}")

    sys.exit(1)

