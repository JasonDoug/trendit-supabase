#!/usr/bin/env python3
"""
Test script for Supabase integration
"""

import os
import sys
import asyncio
import logging
from dotenv import load_dotenv

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_supabase_connection():
    """Test basic Supabase connection and setup"""
    try:
        from services.supabase_service import supabase_service
        
        print("🔥 Supabase Integration Test")
        print("=" * 40)
        
        # Check if Supabase is enabled
        if not supabase_service.is_enabled():
            print("❌ Supabase is not enabled or configured")
            print("   Set USE_SUPABASE=true and provide Supabase credentials in .env")
            return False
        
        print("✅ Supabase service is enabled")
        
        # Test basic client connection
        if supabase_service.client:
            print("✅ Supabase client initialized successfully")
            
            # Test getting a simple query (this will fail if tables don't exist, but connection works)
            try:
                result = supabase_service.client.table("collection_jobs").select("id").limit(1).execute()
                print("✅ Database query test successful")
                print(f"   Query returned: {len(result.data)} rows")
            except Exception as e:
                print(f"⚠️  Database query failed (tables may not exist yet): {e}")
                print("   This is normal if you haven't run init_db.py yet")
        else:
            print("❌ Supabase client not initialized")
            return False
        
        print("\n🎉 Supabase integration test completed!")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("   Run: pip install supabase postgrest")
        return False
    except Exception as e:
        print(f"❌ Error testing Supabase: {e}")
        return False

async def test_supabase_operations():
    """Test Supabase-specific operations"""
    try:
        from services.supabase_service import supabase_service
        
        if not supabase_service.is_enabled():
            print("Supabase not enabled, skipping operations test")
            return
        
        print("\n🧪 Testing Supabase Operations")
        print("=" * 40)
        
        # Test real-time analytics (will fail if no jobs exist)
        try:
            analytics = await supabase_service.get_realtime_analytics("test-job-id")
            if analytics:
                print("✅ Real-time analytics query successful")
            else:
                print("⚠️  No analytics data found (expected if no jobs exist)")
        except Exception as e:
            print(f"⚠️  Analytics test failed: {e}")
        
        print("✅ Supabase operations test completed")
        
    except Exception as e:
        print(f"❌ Error testing operations: {e}")

def test_environment_config():
    """Test environment configuration"""
    print("🔧 Environment Configuration Test")
    print("=" * 40)
    
    use_supabase = os.getenv("USE_SUPABASE", "false").lower() == "true"
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_ANON_KEY")
    supabase_db_url = os.getenv("SUPABASE_DB_URL")
    
    print(f"USE_SUPABASE: {use_supabase}")
    print(f"SUPABASE_URL: {'✅ Set' if supabase_url else '❌ Not set'}")
    print(f"SUPABASE_ANON_KEY: {'✅ Set' if supabase_key else '❌ Not set'}")
    print(f"SUPABASE_DB_URL: {'✅ Set' if supabase_db_url else '❌ Not set'}")
    
    if use_supabase:
        if not all([supabase_url, supabase_key]):
            print("❌ Supabase enabled but missing required credentials")
            return False
        print("✅ Supabase configuration looks good")
    else:
        print("ℹ️  Supabase is disabled (USE_SUPABASE=false)")
    
    return True

async def main():
    """Main test function"""
    print("🚀 Starting Supabase Integration Tests\n")
    
    # Test environment configuration
    if not test_environment_config():
        print("\n❌ Environment configuration test failed")
        sys.exit(1)
    
    # Test Supabase connection
    if not await test_supabase_connection():
        print("\n❌ Supabase connection test failed")
        sys.exit(1)
    
    # Test operations
    await test_supabase_operations()
    
    print("\n🎉 All Supabase tests completed successfully!")
    print("\nNext steps:")
    print("1. Run 'python init_db.py' to create database tables")
    print("2. Run 'uvicorn main:app --reload' to start the API server")
    print("3. Test API endpoints with Supabase backend")

if __name__ == "__main__":
    asyncio.run(main())