-- Supabase table creation script
-- Run this in your Supabase SQL editor to create tables with RLS policies

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR UNIQUE,
    email VARCHAR UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Collection jobs table
CREATE TABLE IF NOT EXISTS collection_jobs (
    id SERIAL PRIMARY KEY,
    job_id VARCHAR UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id),
    
    -- Collection parameters (JSON columns)
    subreddits JSONB,
    sort_types JSONB,
    time_filters JSONB,
    post_limit INTEGER DEFAULT 100,
    comment_limit INTEGER DEFAULT 50,
    max_comment_depth INTEGER DEFAULT 3,
    
    -- Filters
    keywords JSONB,
    min_score INTEGER DEFAULT 0,
    min_upvote_ratio REAL DEFAULT 0.0,
    date_from TIMESTAMP WITH TIME ZONE,
    date_to TIMESTAMP WITH TIME ZONE,
    exclude_nsfw BOOLEAN DEFAULT true,
    anonymize_users BOOLEAN DEFAULT true,
    
    -- Status and progress
    status VARCHAR DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    total_expected INTEGER DEFAULT 0,
    collected_posts INTEGER DEFAULT 0,
    collected_comments INTEGER DEFAULT 0,
    error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Reddit posts table
CREATE TABLE IF NOT EXISTS reddit_posts (
    id SERIAL PRIMARY KEY,
    collection_job_id INTEGER REFERENCES collection_jobs(id) ON DELETE CASCADE,
    
    -- Reddit data
    reddit_id VARCHAR UNIQUE NOT NULL,
    title TEXT,
    selftext TEXT,
    url VARCHAR,
    permalink VARCHAR,
    
    -- Metadata
    subreddit VARCHAR,
    author VARCHAR,
    author_id VARCHAR,
    created_utc TIMESTAMP WITH TIME ZONE,
    
    -- Engagement metrics
    score INTEGER DEFAULT 0,
    upvote_ratio REAL DEFAULT 0.0,
    num_comments INTEGER DEFAULT 0,
    num_crossposts INTEGER DEFAULT 0,
    
    -- Flags
    is_self BOOLEAN DEFAULT false,
    is_video BOOLEAN DEFAULT false,
    over_18 BOOLEAN DEFAULT false,
    spoiler BOOLEAN DEFAULT false,
    locked BOOLEAN DEFAULT false,
    stickied BOOLEAN DEFAULT false,
    
    -- Awards and gilding
    gilded INTEGER DEFAULT 0,
    total_awards_received INTEGER DEFAULT 0,
    
    -- Analysis
    sentiment_score REAL,
    sentiment_label VARCHAR,
    
    -- Timestamps
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reddit comments table
CREATE TABLE IF NOT EXISTS reddit_comments (
    id SERIAL PRIMARY KEY,
    collection_job_id INTEGER REFERENCES collection_jobs(id) ON DELETE CASCADE,
    post_id INTEGER REFERENCES reddit_posts(id) ON DELETE CASCADE,
    
    -- Reddit data
    reddit_id VARCHAR UNIQUE NOT NULL,
    parent_id VARCHAR,
    body TEXT,
    permalink VARCHAR,
    
    -- Metadata
    subreddit VARCHAR,
    author VARCHAR,
    author_id VARCHAR,
    created_utc TIMESTAMP WITH TIME ZONE,
    
    -- Hierarchy
    depth INTEGER DEFAULT 0,
    
    -- Engagement metrics
    score INTEGER DEFAULT 0,
    controversiality INTEGER DEFAULT 0,
    
    -- Flags
    is_submitter BOOLEAN DEFAULT false,
    stickied BOOLEAN DEFAULT false,
    
    -- Awards
    gilded INTEGER DEFAULT 0,
    total_awards_received INTEGER DEFAULT 0,
    
    -- Analysis
    sentiment_score REAL,
    sentiment_label VARCHAR,
    
    -- Timestamps
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reddit users table
CREATE TABLE IF NOT EXISTS reddit_users (
    id SERIAL PRIMARY KEY,
    collection_job_id INTEGER REFERENCES collection_jobs(id) ON DELETE CASCADE,
    
    -- Reddit data
    reddit_id VARCHAR UNIQUE NOT NULL,
    name VARCHAR,
    created_utc TIMESTAMP WITH TIME ZONE,
    
    -- Karma and activity
    link_karma INTEGER DEFAULT 0,
    comment_karma INTEGER DEFAULT 0,
    total_karma INTEGER DEFAULT 0,
    
    -- Flags
    has_verified_email BOOLEAN DEFAULT false,
    is_gold BOOLEAN DEFAULT false,
    is_mod BOOLEAN DEFAULT false,
    
    -- Activity metrics
    posts_analyzed INTEGER DEFAULT 0,
    comments_analyzed INTEGER DEFAULT 0,
    avg_post_score REAL DEFAULT 0.0,
    avg_comment_score REAL DEFAULT 0.0,
    
    -- Timestamps
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics table
CREATE TABLE IF NOT EXISTS analytics (
    id SERIAL PRIMARY KEY,
    collection_job_id INTEGER REFERENCES collection_jobs(id) ON DELETE CASCADE,
    
    -- Analytics data
    metric_name VARCHAR NOT NULL,
    metric_value REAL,
    metric_data JSONB,
    
    -- Metadata
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_collection_jobs_job_id ON collection_jobs(job_id);
CREATE INDEX IF NOT EXISTS idx_collection_jobs_status ON collection_jobs(status);
CREATE INDEX IF NOT EXISTS idx_collection_jobs_created_at ON collection_jobs(created_at);

CREATE INDEX IF NOT EXISTS idx_reddit_posts_reddit_id ON reddit_posts(reddit_id);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_collection_job_id ON reddit_posts(collection_job_id);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_subreddit ON reddit_posts(subreddit);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_created_utc ON reddit_posts(created_utc);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_score ON reddit_posts(score);

CREATE INDEX IF NOT EXISTS idx_reddit_comments_reddit_id ON reddit_comments(reddit_id);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_collection_job_id ON reddit_comments(collection_job_id);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_post_id ON reddit_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_subreddit ON reddit_comments(subreddit);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_parent_id ON reddit_comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_depth ON reddit_comments(depth);

CREATE INDEX IF NOT EXISTS idx_reddit_users_reddit_id ON reddit_users(reddit_id);
CREATE INDEX IF NOT EXISTS idx_reddit_users_collection_job_id ON reddit_users(collection_job_id);

CREATE INDEX IF NOT EXISTS idx_analytics_collection_job_id ON analytics(collection_job_id);
CREATE INDEX IF NOT EXISTS idx_analytics_metric_name ON analytics(metric_name);

-- Enable Row Level Security (RLS) - Uncomment if needed
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE collection_jobs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reddit_posts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reddit_comments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reddit_users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (uncomment and modify as needed)
-- CREATE POLICY "Users can view their own data" ON collection_jobs FOR SELECT USING (auth.uid()::text = user_id::text);
-- CREATE POLICY "Users can insert their own jobs" ON collection_jobs FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- Create a function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_collection_jobs_updated_at 
    BEFORE UPDATE ON collection_jobs 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();