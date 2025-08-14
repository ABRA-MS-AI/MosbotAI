#!/usr/bin/env python3
"""Simple test server to verify the auth_setup endpoint works"""

from quart import Quart, jsonify

app = Quart(__name__)


@app.route("/")
async def index():
    return "Backend server is running!"


@app.route("/auth_setup", methods=["GET"])
def auth_setup():
    """Simple auth setup endpoint for testing"""
    return jsonify(
        {
            "auth": {
                "clientId": "test-client-id",
                "authority": "https://login.microsoftonline.com/test-tenant",
                "knownAuthorities": [],
                "redirectUri": "/redirect",
            },
            "login_enabled": False,
        }
    )


@app.route("/config", methods=["GET"])
def config():
    """Basic config endpoint"""
    return jsonify(
        {
            "showGPT4VOptions": False,
            "showSemanticRankerOption": False,
            "streamingEnabled": True,
            "showUserUpload": False,
        }
    )


if __name__ == "__main__":
    print("Starting simple backend server on http://localhost:3001")
    app.run(host="localhost", port=3001, debug=True)
