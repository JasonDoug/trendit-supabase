# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Trendit is a comprehensive Reddit data collection and analysis platform built with FastAPI and PostgreSQL. It provides a five-tier API architecture for collecting, analyzing, and exporting Reddit data with AI-powered sentiment analysis.

## Development Environment Setup

### Prerequisites
- Python 3.9+
- Database: PostgreSQL, SQLite, or Supabase
- Reddit API credentials (script-type app)

### Initial Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env  # Edit with your credentials

# For standard PostgreSQL/SQLite
python init_db.py

# For Supabase: Run supabase_tables.sql in Supabase SQL editor first, then:
python test_supabase.py  # Test Supabase connection
python init_db.py       # Verify tables with SQLAlchemy
```

### Running the Application
```bash
# Start development server
uvicorn main:app --reload --port 8000

# Alternative with environment variables
python main.py
```

## Testing Commands

### Primary Test Suites
```bash
# Comprehensive API test suite (all APIs)
python test_api.py

# Collection API focused tests
python test_collection_api.py

# Simple Reddit connection test
python test_reddit_simple.py

# Supabase integration test
python test_supabase.py

# Query API tests (in root directory)
cd ..
python test_query_api.py
```

### Manual Testing
```bash
# Health check
curl http://localhost:8000/health

# API documentation
open http://localhost:8000/docs
```

## Architecture

### Core Components

**Backend Structure (`backend/`)**:
- `main.py` - FastAPI application entry point with CORS, error handling
- `init_db.py` - Database initialization script
- `models/` - SQLAlchemy models and database configuration
  - `database.py` - Database connection and session management
  - `models.py` - Data models (User, CollectionJob, RedditPost, etc.)
- `services/` - Business logic layer
  - `reddit_client.py` - Synchronous Reddit API client (PRAW)
  - `reddit_client_async.py` - Asynchronous Reddit client
  - `data_collector.py` - Data collection orchestration
  - `sentiment_analyzer.py` - AI-powered sentiment analysis (OpenRouter + Claude)
  - `analytics.py` - Analytics and reporting
- `api/` - REST API endpoints (6 routers)
  - `scenarios.py` - Pre-configured quickstart examples
  - `query.py` - Flexible one-off queries
  - `collect.py` - Persistent data pipeline with job management
  - `data.py` - Query stored data
  - `export.py` - Multi-format data export
  - `sentiment.py` - AI sentiment analysis

### Key Technologies
- **FastAPI** - Modern async web framework
- **PRAW** - Python Reddit API Wrapper (sync)
- **asyncpraw** - Async version for better performance
- **PostgreSQL/Supabase + SQLAlchemy** - Database with comprehensive indexing
- **Supabase** - Optional backend with real-time features, RLS, and managed PostgreSQL
- **OpenRouter + Claude** - AI sentiment analysis
- **Pandas + PyArrow** - Data processing and export

### Database Models
The system uses comprehensive database models for:
- `CollectionJob` - Background job management with progress tracking
- `RedditPost/RedditComment/RedditUser` - Reddit data storage
- `Analytics` - Performance metrics and insights
- Enums for `JobStatus`, `SortType`, `TimeFilter`

## API Architecture

The application provides **34 endpoints** across 6 categories:

1. **Scenarios API** (7 endpoints) - Pre-configured examples
2. **Query API** (5 endpoints) - Flexible one-off queries  
3. **Collection API** (6 endpoints) - Persistent data pipeline
4. **Data API** (4 endpoints) - Query stored data
5. **Export API** (4 endpoints) - Multi-format exports
6. **Sentiment API** (4 endpoints) - AI-powered analysis

## Configuration

### Required Environment Variables

#### Option 1: Standard PostgreSQL/SQLite
```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/trendit
# Or for development: DATABASE_URL=sqlite:///./trendit.db

# Reddit API (from https://www.reddit.com/prefs/apps - must be "script" type)
REDDIT_CLIENT_ID=your_client_id
REDDIT_CLIENT_SECRET=your_client_secret
REDDIT_USER_AGENT=YourAppName by u/yourusername

# Server
HOST=localhost
PORT=8000
RELOAD=true
```

#### Option 2: Supabase
```env
# Enable Supabase
USE_SUPABASE=true

# Supabase configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_DB_URL=postgresql://postgres.your-ref:[password]@aws-0-us-west-1.pooler.supabase.com:6543/postgres

# Reddit API & Server (same as above)
REDDIT_CLIENT_ID=your_client_id
REDDIT_CLIENT_SECRET=your_client_secret
REDDIT_USER_AGENT=YourAppName by u/yourusername
HOST=localhost
PORT=8000
RELOAD=true
```

#### Optional Features
```env
# AI Sentiment Analysis
OPENROUTER_API_KEY=your_openrouter_key
```

### Reddit App Setup
1. Go to https://www.reddit.com/prefs/apps
2. Create app with type **"script"** (not web app)
3. Use redirect URI: `http://localhost:8080`

### Supabase Setup
1. Create project at https://supabase.com/dashboard
2. Go to Settings > API to get your `SUPABASE_URL` and keys
3. Go to Settings > Database to get connection string for `SUPABASE_DB_URL`
4. Run the SQL script in `supabase_tables.sql` via SQL Editor
5. Optionally configure Row Level Security (RLS) policies
6. Set environment variables and test with `python test_supabase.py`

## Development Workflow

### Code Conventions
- Follow existing FastAPI patterns in `api/` modules
- Use SQLAlchemy models consistently
- Implement proper error handling with HTTPException
- Use Pydantic models for request/response validation
- Follow async/await patterns where applicable

### Testing Strategy
- Run comprehensive test suite before commits: `python test_api.py`
- Test individual components: `python test_reddit_simple.py`
- Use health endpoint for quick connectivity checks
- API documentation available at `/docs` and `/redoc`

### Performance Considerations
- Current implementation uses sync PRAW (consider async migration)
- Database optimized with indexes for fast job queries
- Background job processing with real-time status updates
- Supports multiple concurrent collection jobs
- Built-in rate limiting respects Reddit API limits (60 req/min)

### Common Development Tasks
- **Add new API endpoints**: Create in appropriate `api/` module, add to router
- **Extend data models**: Modify `models/models.py`, update `supabase_tables.sql` if using Supabase
- **Add new collection scenarios**: Extend `services/data_collector.py`
- **Update export formats**: Modify `api/export.py` with new format handlers
- **Enhance sentiment analysis**: Update `services/sentiment_analyzer.py`
- **Add Supabase features**: Use `services/supabase_service.py` for real-time updates, bulk operations
- **Database migrations**: Update both SQLAlchemy models and Supabase SQL scripts

## Troubleshooting

### Common Issues
- **401 Reddit API errors**: Verify app type is "script", check credentials
- **Database connection failures**: Verify PostgreSQL running, check DATABASE_URL
- **Supabase connection issues**: Check SUPABASE_URL and keys, verify project is active
- **Supabase table errors**: Run `supabase_tables.sql` in SQL Editor first
- **Import errors**: Ensure running from `backend/` directory, venv activated
- **Async warnings**: PRAW async warnings are normal, don't affect functionality
- **Supabase RLS errors**: Check Row Level Security policies if enabled

### Performance Notes
- Tests take 2-5 minutes due to Reddit API rate limiting
- Memory usage ~200MB baseline
- Database operations: 10,000+ inserts/second
- API response time: <100ms average