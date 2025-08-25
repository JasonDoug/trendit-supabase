"""
Supabase service for enhanced database operations and real-time features
"""

import os
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from models.database import supabase_client, USE_SUPABASE

logger = logging.getLogger(__name__)

class SupabaseService:
    """Service for Supabase-specific operations"""
    
    def __init__(self):
        self.client = supabase_client
        self.enabled = USE_SUPABASE and supabase_client is not None
        
        if not self.enabled:
            logger.warning("Supabase service disabled - client not available")
    
    def is_enabled(self) -> bool:
        """Check if Supabase is enabled and available"""
        return self.enabled
    
    async def insert_post_with_realtime(self, post_data: Dict[str, Any]) -> Optional[Dict]:
        """Insert a Reddit post with real-time updates and duplicate handling"""
        if not self.enabled:
            return None
            
        try:
            # Use upsert to handle duplicates gracefully
            result = self.client.table("reddit_posts").upsert(post_data, on_conflict="reddit_id").execute()
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error inserting post to Supabase: {e}")
            return None
    
    async def update_job_status_realtime(self, job_id: str, status: str, progress: int = None) -> Optional[Dict]:
        """Update collection job status with real-time notifications"""
        if not self.enabled:
            return None
            
        try:
            update_data = {
                "status": status,
                "updated_at": datetime.utcnow().isoformat()
            }
            if progress is not None:
                update_data["progress"] = progress
                
            result = self.client.table("collection_jobs").update(update_data).eq("job_id", job_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error updating job status in Supabase: {e}")
            return None
    
    async def subscribe_to_job_updates(self, job_id: str, callback):
        """Subscribe to real-time updates for a specific job"""
        if not self.enabled:
            return None
            
        try:
            # Set up real-time subscription
            def handle_change(payload):
                if payload.get("eventType") in ["UPDATE", "INSERT"]:
                    callback(payload.get("new"))
            
            # Subscribe to changes for this specific job
            subscription = self.client.realtime.channel(f"job_{job_id}") \
                .on("postgres_changes", {
                    "event": "*",
                    "schema": "public", 
                    "table": "collection_jobs",
                    "filter": f"job_id=eq.{job_id}"
                }, handle_change) \
                .subscribe()
                
            return subscription
        except Exception as e:
            logger.error(f"Error setting up Supabase subscription: {e}")
            return None
    
    async def get_realtime_analytics(self, job_id: str) -> Optional[Dict]:
        """Get real-time analytics for a collection job"""
        if not self.enabled:
            return None
            
        try:
            # Get current job stats
            job_result = self.client.table("collection_jobs").select("*").eq("job_id", job_id).execute()
            if not job_result.data:
                return None
                
            job = job_result.data[0]
            
            # Get post count
            posts_result = self.client.table("reddit_posts") \
                .select("id", count="exact") \
                .eq("collection_job_id", job["id"]) \
                .execute()
                
            # Get comment count  
            comments_result = self.client.table("reddit_comments") \
                .select("id", count="exact") \
                .eq("collection_job_id", job["id"]) \
                .execute()
            
            return {
                "job_id": job_id,
                "status": job["status"],
                "progress": job["progress"],
                "posts_collected": posts_result.count or 0,
                "comments_collected": comments_result.count or 0,
                "created_at": job["created_at"],
                "updated_at": job["updated_at"]
            }
        except Exception as e:
            logger.error(f"Error getting Supabase analytics: {e}")
            return None
    
    async def bulk_insert_posts(self, posts_data: List[Dict[str, Any]]) -> bool:
        """Bulk insert posts for better performance with duplicate handling"""
        if not self.enabled or not posts_data:
            return False
            
        try:
            # Use upsert to handle duplicates gracefully
            result = self.client.table("reddit_posts").upsert(posts_data, on_conflict="reddit_id").execute()
            return len(result.data) > 0
        except Exception as e:
            logger.error(f"Error bulk inserting posts to Supabase: {e}")
            return False
    
    async def bulk_insert_comments(self, comments_data: List[Dict[str, Any]]) -> bool:
        """Bulk insert comments for better performance with duplicate handling"""
        if not self.enabled or not comments_data:
            return False
            
        try:
            # Use upsert to handle duplicates gracefully
            result = self.client.table("reddit_comments").upsert(comments_data, on_conflict="reddit_id").execute()
            return len(result.data) > 0
        except Exception as e:
            logger.error(f"Error bulk inserting comments to Supabase: {e}")
            return False
    
    async def setup_rls_policies(self):
        """Setup Row Level Security policies (if needed)"""
        if not self.enabled:
            return False
            
        # Note: RLS policies are typically set up through the Supabase dashboard
        # or SQL scripts. This method is a placeholder for programmatic setup.
        logger.info("RLS policies should be configured through Supabase dashboard")
        return True

# Global instance
supabase_service = SupabaseService()