-- SQL script to create tables in Supabase for Trendit application

-- Create collection_jobs table
CREATE TABLE IF NOT EXISTS collection_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id TEXT UNIQUE NOT NULL,
    subreddits JSONB,
    sort_types JSONB,
    time_filters JSONB,
    post_limit INTEGER DEFAULT 100,
    comment_limit INTEGER DEFAULT 50,
    max_comment_depth INTEGER DEFAULT 3,
    keywords JSONB,
    min_score INTEGER DEFAULT 0,
    min_upvote_ratio FLOAT DEFAULT 0.0,
    date_from TIMESTAMP WITH TIME ZONE,
    date_to TIMESTAMP WITH TIME ZONE,
    exclude_nsfw BOOLEAN DEFAULT TRUE,
    anonymize_users BOOLEAN DEFAULT TRUE,
    status TEXT DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    total_expected INTEGER DEFAULT 0,
    collected_posts INTEGER DEFAULT 0,
    collected_comments INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reddit_posts table
CREATE TABLE IF NOT EXISTS reddit_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_job_id UUID REFERENCES collection_jobs(id),
    reddit_id TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    selftext TEXT,
    url TEXT,
    permalink TEXT,
    subreddit TEXT NOT NULL,
    author TEXT,
    author_id TEXT,
    score INTEGER DEFAULT 0,
    upvote_ratio FLOAT DEFAULT 1.0,
    num_comments INTEGER DEFAULT 0,
    awards_received INTEGER DEFAULT 0,
    is_nsfw BOOLEAN DEFAULT FALSE,
    is_spoiler BOOLEAN DEFAULT FALSE,
    is_stickied BOOLEAN DEFAULT FALSE,
    post_hint TEXT,
    created_utc TIMESTAMP WITH TIME ZONE NOT NULL,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sentiment_score FLOAT,
    readability_score FLOAT
);

-- Create reddit_comments table
CREATE TABLE IF NOT EXISTS reddit_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES reddit_posts(id) ON DELETE CASCADE,
    reddit_id TEXT UNIQUE NOT NULL,
    body TEXT NOT NULL,
    parent_id TEXT,
    author TEXT,
    author_id TEXT,
    depth INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    awards_received INTEGER DEFAULT 0,
    is_submitter BOOLEAN DEFAULT FALSE,
    is_stickied BOOLEAN DEFAULT FALSE,
    created_utc TIMESTAMP WITH TIME ZONE NOT NULL,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sentiment_score FLOAT
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_collection_jobs_job_id ON collection_jobs(job_id);
CREATE INDEX IF NOT EXISTS idx_collection_jobs_status ON collection_jobs(status);
CREATE INDEX IF NOT EXISTS idx_collection_jobs_created_at ON collection_jobs(created_at);

CREATE INDEX IF NOT EXISTS idx_reddit_posts_reddit_id ON reddit_posts(reddit_id);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_subreddit ON reddit_posts(subreddit);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_score ON reddit_posts(score);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_created_utc ON reddit_posts(created_utc);
CREATE INDEX IF NOT EXISTS idx_reddit_posts_collection_job_id ON reddit_posts(collection_job_id);

CREATE INDEX IF NOT EXISTS idx_reddit_comments_reddit_id ON reddit_comments(reddit_id);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_post_id ON reddit_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_score ON reddit_comments(score);
CREATE INDEX IF NOT EXISTS idx_reddit_comments_created_utc ON reddit_comments(created_utc);

-- Enable Row Level Security (RLS) for all tables
ALTER TABLE collection_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reddit_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reddit_comments ENABLE ROW LEVEL SECURITY;

-- Create policies for anonymous access (adjust as needed for your security requirements)
CREATE POLICY "Allow read access to collection_jobs" ON collection_jobs
FOR SELECT USING (true);

CREATE POLICY "Allow read access to reddit_posts" ON reddit_posts
FOR SELECT USING (true);

CREATE POLICY "Allow read access to reddit_comments" ON reddit_comments
FOR SELECT USING (true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE collection_jobs TO anon, authenticated;
GRANT ALL ON TABLE reddit_posts TO anon, authenticated;
GRANT ALL ON TABLE reddit_comments TO anon, authenticated;

-- To use this SQL script:
--
-- 1. Go to your Supabase dashboard
-- 2. Select your project
-- 3. Go to the SQL editor (SQL > Editor in the left sidebar)
-- 4. Copy and paste the entire script above
-- 5. Click "Run" to execute the script
--
-- This will create all the necessary tables with appropriate indexes and basic Row Level Security policies for read access. You may want to adjust the RLS policies based on your specific security requirements.
--
-- After running this script, your health check endpoint should work properly since it will be able to find the `reddit_posts` table.
