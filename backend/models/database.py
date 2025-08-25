from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration
# Supports SQLite (dev/testing), PostgreSQL, and Supabase
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./trendit.db")
USE_SUPABASE = os.getenv("USE_SUPABASE", "false").lower() == "true"

# Initialize Supabase client if enabled
supabase_client = None
if USE_SUPABASE:
    try:
        from supabase import create_client
        SUPABASE_URL = os.getenv("SUPABASE_URL")
        SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
        
        if SUPABASE_URL and SUPABASE_KEY:
            supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)
            # For Supabase, we still use the PostgreSQL connection string for SQLAlchemy
            # but can also use the Supabase client for additional features
            if not DATABASE_URL or DATABASE_URL.startswith("sqlite"):
                # Construct PostgreSQL URL from Supabase credentials if needed
                SUPABASE_DB_URL = os.getenv("SUPABASE_DB_URL")
                if SUPABASE_DB_URL:
                    DATABASE_URL = SUPABASE_DB_URL
    except ImportError:
        print("Warning: Supabase dependencies not installed. Install with: pip install supabase")
        USE_SUPABASE = False

# SQLite requires check_same_thread=False for FastAPI
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()