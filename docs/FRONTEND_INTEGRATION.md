# Trendit API Frontend Integration Guide

This document provides all the information needed for frontend code generators and developers to create a comprehensive UI for the Trendit Reddit API.

## API Base Information

- **Base URL**: `http://localhost:8000` (development) / `https://your-domain.com` (production)
- **API Specification**: OpenAPI 3.1.0
- **Authentication**: None required (public API)
- **Rate Limits**: Standard Reddit API limits apply

## Core Endpoints Overview

### 1. Query API (`/api/query/`)
**Purpose**: Real-time Reddit data queries - no data storage

#### Primary Endpoints:
- `GET /api/query/posts/simple` - Simple post search with URL parameters
- `POST /api/query/posts/form` - Form-based post search (recommended for UI)
- `POST /api/query/posts` - Advanced JSON-based post search
- `POST /api/query/comments` - Advanced comment search

#### Key Form Fields for Post Query:
```typescript
interface PostQueryForm {
  subreddits: string;          // Required: "python,MachineLearning" 
  keywords?: string;           // Optional: "AI,neural networks"
  min_score?: number;          // Optional: 5
  limit: number;               // Default: 100, Max: 1000
  sort_type: "hot" | "new" | "top" | "rising" | "controversial";  // Default: "hot"
  time_filter: "hour" | "day" | "week" | "month" | "year" | "all"; // Default: "week"
}
```

### 2. Collection API (`/api/collect/`)
**Purpose**: Background data collection jobs with persistent storage

#### Primary Endpoints:
- `POST /api/collect/jobs` - Create new collection job
- `GET /api/collect/jobs` - List all jobs with pagination
- `GET /api/collect/jobs/{job_id}` - Get specific job details
- `GET /api/collect/jobs/{job_id}/status` - Get job status (for polling)
- `POST /api/collect/jobs/{job_id}/cancel` - Cancel running job
- `DELETE /api/collect/jobs/{job_id}` - Delete job and all data

#### Collection Job Form Fields:
```typescript
interface CollectionJobForm {
  subreddits: string[];                    // Required: ["python", "MachineLearning"]
  sort_types: ("hot" | "new" | "top" | "rising" | "controversial")[]; // Default: ["hot"]
  time_filters: ("hour" | "day" | "week" | "month" | "year" | "all")[]; // Default: ["week"]
  post_limit: number;                      // Default: 100, Max: 10000
  comment_limit: number;                   // Default: 50, Max: 1000
  max_comment_depth: number;               // Default: 3, Max: 10
  keywords?: string[];                     // Optional: ["AI", "machine learning"]
  min_score: number;                       // Default: 0
  min_upvote_ratio: number;               // Default: 0.0, Range: 0.0-1.0
  date_from?: string;                     // ISO datetime
  date_to?: string;                       // ISO datetime
  exclude_nsfw: boolean;                  // Default: true
  anonymize_users: boolean;               // Default: true
}
```

#### Job Status Values:
```typescript
type JobStatus = "pending" | "running" | "completed" | "failed" | "cancelled";
```

### 3. Data API (`/api/data/`)
**Purpose**: Query stored data from completed collection jobs

#### Primary Endpoints:
- `POST /api/data/posts` - Query stored posts with advanced filtering
- `POST /api/data/comments` - Query stored comments with advanced filtering
- `GET /api/data/analytics/{job_id}` - Get analytics for specific job
- `GET /api/data/summary` - Overall data summary
- `GET /api/data/posts/recent` - Quick access to recent posts
- `GET /api/data/posts/top` - Quick access to top posts

### 4. Export API (`/api/export/`)
**Purpose**: Export collected data in various formats

#### Primary Endpoints:
- `POST /api/export/posts/{format}` - Export posts (csv, json, jsonl, parquet)
- `POST /api/export/comments/{format}` - Export comments
- `GET /api/export/job/{job_id}/{format}` - Export entire job data
- `GET /api/export/formats` - List supported formats

### 5. Sentiment Analysis API (`/api/sentiment/`)
**Purpose**: AI-powered sentiment analysis

#### Primary Endpoints:
- `GET /api/sentiment/status` - Check if sentiment analysis is available
- `POST /api/sentiment/analyze` - Analyze single text
- `POST /api/sentiment/analyze-batch` - Analyze multiple texts
- `GET /api/sentiment/test` - Test with sample data

## UI Components & Workflows

### 1. Quick Search Interface
**Component**: Simple search form
**Endpoint**: `GET /api/query/posts/simple`
**Fields**:
- Subreddits (text input, comma-separated)
- Keywords (optional text input, comma-separated)
- Min Score (optional number input)
- Limit (number input, default: 50)
- Sort Type (dropdown: hot, new, top, rising, controversial)
- Time Filter (dropdown: hour, day, week, month, year, all)

**Submit**: GET request with query parameters
**Response**: Display posts in cards/list format

### 2. Advanced Search Interface  
**Component**: Advanced form with multiple sections
**Endpoint**: `POST /api/query/posts/form`
**Sections**:
- **Subreddits** (required multi-input or comma-separated text)
- **Keywords** (optional multi-input for include/exclude)
- **Scoring** (min/max score, upvote ratio sliders)
- **Time Range** (date pickers for from/to)
- **Content Filters** (checkboxes for NSFW, spoilers, stickied)
- **Sorting** (dropdowns for sort type and time filter)

### 3. Collection Job Creator
**Component**: Multi-step wizard or tabbed form
**Endpoint**: `POST /api/collect/jobs`
**Steps/Tabs**:
1. **Target Selection**: Subreddits, keywords, date ranges
2. **Collection Parameters**: Post/comment limits, depth settings
3. **Filtering**: Score thresholds, content exclusions
4. **Options**: Anonymization, NSFW handling

**Submit**: Create job and redirect to monitoring page

### 4. Collection Job Monitor
**Component**: Job dashboard with real-time updates
**Endpoints**: 
- `GET /api/collect/jobs` - List jobs
- `GET /api/collect/jobs/{job_id}/status` - Poll for updates (every 5-10 seconds)

**Features**:
- Job list with status badges
- Progress bars for running jobs
- Action buttons (cancel, delete, view results)
- Auto-refresh for active jobs

### 5. Data Explorer
**Component**: Advanced data browser
**Endpoint**: `POST /api/data/posts`
**Features**:
- **Filters Panel**: Job selection, subreddits, keywords, dates, scores
- **Results Table**: Sortable columns, pagination
- **Export Options**: Format selection and download buttons
- **Analytics View**: Charts and statistics

### 6. Sentiment Analyzer
**Component**: Text analysis tool
**Endpoints**: 
- `POST /api/sentiment/analyze` - Single text
- `POST /api/sentiment/analyze-batch` - Multiple texts

**Features**:
- Text input area
- Sentiment score display (-1 to +1 scale)
- Sentiment label (Very Negative to Very Positive)
- Batch processing interface

## Error Handling

### Standard Error Response:
```typescript
interface APIError {
  detail: string | ValidationError[];
}

interface ValidationError {
  loc: (string | number)[];
  msg: string;
  type: string;
}
```

### Common HTTP Status Codes:
- `200` - Success
- `422` - Validation Error (form field errors)
- `404` - Not Found (invalid job ID, etc.)
- `500` - Server Error

## Real-time Updates

### Job Status Polling:
```javascript
// Poll job status every 5 seconds for running jobs
const pollJobStatus = async (jobId) => {
  const response = await fetch(`/api/collect/jobs/${jobId}/status`);
  const status = await response.json();
  
  // Update UI with status.status, status.progress, status.collected_posts
  if (status.status === "running") {
    setTimeout(() => pollJobStatus(jobId), 5000);
  }
};
```

## Response Formats

### Query Response:
```typescript
interface QueryResponse {
  query_type: string;
  parameters: Record<string, any>;
  results: any[];               // Array of posts/comments
  count: number;               // Number of results returned
  execution_time_ms: number;   // Query performance
  reddit_api_calls: number;    // API usage
  filters_applied: string[];   // Applied filters
}
```

### Collection Job Response:
```typescript
interface CollectionJobResponse {
  id: number;
  job_id: string;                    // Unique identifier
  status: JobStatus;
  progress: number;                  // 0-100 percentage
  total_expected: number;
  collected_posts: number;
  collected_comments: number;
  error_message?: string;
  created_at: string;               // ISO datetime
  started_at?: string;              // ISO datetime
  completed_at?: string;            // ISO datetime
  subreddits: string[];
  post_limit: number;
}
```

### Data Post Object:
```typescript
interface RedditPost {
  id: number;
  reddit_id: string;               // Reddit's unique ID
  title: string;
  selftext?: string;               // Post content
  url?: string;
  permalink: string;               // Reddit permalink
  subreddit: string;
  author: string;
  created_utc: string;             // ISO datetime
  score: number;
  upvote_ratio: number;           // 0.0-1.0
  num_comments: number;
  is_self: boolean;               // Text post vs link
  is_video: boolean;
  over_18: boolean;               // NSFW
  spoiler: boolean;
  locked: boolean;
  stickied: boolean;
  sentiment_score?: number;       // -1.0 to 1.0
  sentiment_label?: string;       // "Very Positive", etc.
}
```

## Form Validation Rules

### Subreddits:
- Required for all queries
- Format: Comma-separated list or array
- Example: `"python,MachineLearning"` or `["python", "MachineLearning"]`

### Limits:
- Query API: 1-1000 posts
- Collection API: 1-10000 posts, 0-1000 comments per post
- Data API: 1-1000 results per page

### Dates:
- Format: ISO 8601 datetime strings
- Example: `"2025-08-25T00:00:00Z"`

### Scores:
- Upvote ratio: 0.0-1.0 (0% to 100%)
- Post/comment scores: Any integer

## Recommended UI Libraries

### Form Libraries:
- **React**: React Hook Form + Zod validation
- **Vue**: VeeValidate or Formkit  
- **Angular**: Reactive Forms

### HTTP Client:
- **React**: TanStack Query (React Query) + Axios
- **Vue**: VueUse + Axios
- **Angular**: HttpClient

### UI Components:
- **Multi-framework**: Headless UI, Radix UI
- **React**: Chakra UI, Mantine, Ant Design
- **Vue**: Quasar, Vuetify, Naive UI
- **Angular**: Angular Material

## Sample API Calls

### Quick Search:
```bash
GET /api/query/posts/simple?subreddits=python,javascript&keywords=async&min_score=10&limit=20&sort_type=hot&time_filter=week
```

### Create Collection Job:
```bash
POST /api/collect/jobs
Content-Type: application/json

{
  "subreddits": ["python", "MachineLearning"],
  "sort_types": ["hot", "top"],
  "time_filters": ["week"],
  "post_limit": 500,
  "comment_limit": 100,
  "keywords": ["AI", "neural networks"],
  "min_score": 5,
  "exclude_nsfw": true
}
```

### Query Stored Data:
```bash
POST /api/data/posts
Content-Type: application/json

{
  "subreddits": ["python"],
  "min_score": 50,
  "limit": 20,
  "sort_by": "score",
  "sort_order": "desc"
}
```

## OpenAPI Specification

The complete API specification is available in multiple formats:
- **JSON**: `docs/openapi_spec.json`
- **YAML**: `docs/openapi_spec.yaml`  
- **Postman Collection**: `docs/postman_collection.json`
- **Live Docs**: `http://localhost:8000/docs` (Swagger UI)
- **Alternative Docs**: `http://localhost:8000/redoc` (ReDoc)

Use these files to generate type-safe client code, mock servers, and comprehensive documentation for your frontend application.