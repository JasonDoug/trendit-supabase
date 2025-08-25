# Vercel serverless function entry point
import sys
import os

# Add the backend directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app

# Vercel expects the app to be available as 'app'
# The main.py file already exports 'app', so we just import it