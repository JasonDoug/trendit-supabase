import azure.functions as func
import sys
import os
from pathlib import Path

# Add backend directory to Python path
backend_path = Path(__file__).parent.parent / "backend"
sys.path.insert(0, str(backend_path))

# Import FastAPI app
from main import app as fastapi_app

# Create Azure Functions app
app = func.AsgiFunctionApp(
    app=fastapi_app,
    http_auth_level=func.AuthLevel.ANONYMOUS
)

@app.function_name(name="trendit_api")
@app.route(route="{*route}", auth_level=func.AuthLevel.ANONYMOUS)
async def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function entry point that forwards all requests to FastAPI
    """
    return await func.AsgiMiddleware(fastapi_app).handle_async(req)