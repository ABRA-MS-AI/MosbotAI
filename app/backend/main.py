import os
import sys

# Fix the import path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app

from load_azd_env import load_azd_env

# WEBSITE_HOSTNAME is always set by App Service, RUNNING_IN_PRODUCTION is set in main.bicep
RUNNING_ON_AZURE = os.getenv("WEBSITE_HOSTNAME") is not None or os.getenv("RUNNING_IN_PRODUCTION") is not None

if not RUNNING_ON_AZURE:
    load_azd_env()

app = create_app()
