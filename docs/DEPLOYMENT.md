# Trendit API Deployment Guide

This guide covers deploying the Trendit Reddit API to various serverless cloud providers.

## Prerequisites

Before deploying, ensure you have:
- Reddit API credentials (Client ID, Client Secret)
- Supabase project configured
- OpenRouter API key (for sentiment analysis)
- Git repository connected to deployment platform

## Deployment Options

### 1. Render (Recommended - Easiest)

**Pros**: Simple setup, free tier, persistent disk storage, good for databases
**Cons**: Cold starts on free tier

#### Setup Steps:

1. **Connect Repository**:
   - Go to [render.com](https://render.com)
   - Connect your GitHub repository
   - Select "Web Service" deployment

2. **Configure Service**:
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Environment**: Python 3.11

3. **Set Environment Variables**:
   ```
   REDDIT_CLIENT_ID=your_reddit_client_id
   REDDIT_CLIENT_SECRET=your_reddit_client_secret
   REDDIT_USER_AGENT=Trendit/1.0 Production
   OPENROUTER_API_KEY=your_openrouter_key
   USE_SUPABASE=true
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_DB_URL=your_supabase_db_connection_string
   HOST=0.0.0.0
   RELOAD=false
   ```

4. **Deploy**:
   - Use the provided `render.yaml` file for Infrastructure as Code
   - Or configure manually through Render dashboard
   - Automatic deploys on git push

**Cost**: Free tier available, $7/month for always-on service

---

### 2. Vercel (Best for Frontend Integration)

**Pros**: Excellent for Next.js/React frontends, fast global CDN, simple deployment
**Cons**: 10-second timeout limit, cold starts, limited for long-running tasks

#### Setup Steps:

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Configure Project**:
   - Use provided `vercel.json` configuration
   - Entry point at `api/index.py`

3. **Set Environment Variables**:
   ```bash
   vercel env add REDDIT_CLIENT_ID
   vercel env add REDDIT_CLIENT_SECRET
   vercel env add REDDIT_USER_AGENT
   vercel env add OPENROUTER_API_KEY
   vercel env add USE_SUPABASE
   vercel env add SUPABASE_URL
   vercel env add SUPABASE_ANON_KEY
   vercel env add SUPABASE_DB_URL
   ```

4. **Deploy**:
   ```bash
   vercel --prod
   ```

**Limitations**:
- Collection jobs must complete within 10 seconds
- Best for query endpoints only
- Consider splitting collection jobs to separate service

**Cost**: Free tier generous, $20/month pro plan

---

### 3. Azure Functions (Enterprise-Grade)

**Pros**: Enterprise features, excellent scaling, good integration with Azure services
**Cons**: More complex setup, Azure-specific tooling

#### Setup Steps:

1. **Install Azure CLI and Functions Core Tools**:
   ```bash
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Install Azure Functions Core Tools
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```

2. **Login and Create Resources**:
   ```bash
   az login
   az group create --name trendit-rg --location eastus
   az storage account create --name trenditstorage --resource-group trendit-rg
   az functionapp create --resource-group trendit-rg --consumption-plan-location eastus \
     --runtime python --runtime-version 3.11 --functions-version 4 \
     --name trendit-api --storage-account trenditstorage
   ```

3. **Configure Environment Variables**:
   ```bash
   az functionapp config appsettings set --name trendit-api --resource-group trendit-rg \
     --settings REDDIT_CLIENT_ID=your_client_id \
                REDDIT_CLIENT_SECRET=your_client_secret \
                REDDIT_USER_AGENT="Trendit/1.0 Azure" \
                OPENROUTER_API_KEY=your_openrouter_key \
                USE_SUPABASE=true \
                SUPABASE_URL=your_supabase_url \
                SUPABASE_ANON_KEY=your_anon_key \
                SUPABASE_DB_URL=your_db_url
   ```

4. **Deploy**:
   ```bash
   cd azure-functions
   func azure functionapp publish trendit-api
   ```

**Cost**: Pay-per-execution, very cost-effective for intermittent usage

---

### 4. Railway (Alternative to Render)

**Pros**: Similar to Render, good free tier, simple deployment
**Cons**: Newer platform, fewer features than established providers

#### Quick Setup:
1. Connect GitHub repository to Railway
2. Set environment variables in dashboard
3. Railway auto-detects Python and deploys

---

### 5. Google Cloud Run (Container-Based)

**Pros**: Pay-per-request, scales to zero, container flexibility
**Cons**: Requires Docker knowledge

#### Setup with Docker:
1. **Create Dockerfile**:
   ```dockerfile
   FROM python:3.11-slim
   
   WORKDIR /app
   COPY backend/ .
   RUN pip install -r requirements.txt
   
   CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "$PORT"]
   ```

2. **Deploy**:
   ```bash
   gcloud run deploy trendit-api --source . --platform managed
   ```

---

## Environment Variables Reference

### Required Variables:
```env
REDDIT_CLIENT_ID=your_reddit_client_id
REDDIT_CLIENT_SECRET=your_reddit_client_secret
REDDIT_USER_AGENT=Trendit/1.0 Production
USE_SUPABASE=true
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_DB_URL=postgresql://postgres:password@host:port/database
```

### Optional Variables:
```env
OPENROUTER_API_KEY=your_openrouter_key  # For sentiment analysis
HOST=0.0.0.0                           # Bind to all interfaces
PORT=8000                              # Default port (auto-set by most providers)
RELOAD=false                           # Disable auto-reload in production
```

## Health Checks and Monitoring

All deployments should monitor:
- **Health Endpoint**: `GET /health`
- **API Status**: `GET /` for basic info
- **Logs**: Monitor application logs for errors
- **Performance**: Track response times and error rates

## Domain and SSL

### Custom Domain Setup:
1. **Render**: Add custom domain in dashboard, automatic SSL
2. **Vercel**: Add domain in project settings, automatic SSL  
3. **Azure Functions**: Configure custom domain in Azure portal
4. **Others**: Follow provider-specific documentation

## CI/CD Pipeline

### GitHub Actions Example:
```yaml
name: Deploy to Render
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Render
        uses: JorgeLNJunior/render-deploy@v1.4.4
        with:
          service_id: ${{ secrets.RENDER_SERVICE_ID }}
          api_key: ${{ secrets.RENDER_API_KEY }}
```

## Performance Considerations

### Cold Starts:
- **Render**: Keep one instance warm with paid plan
- **Vercel**: Inevitable on serverless, optimize imports
- **Azure Functions**: Premium plan for pre-warmed instances

### Database Connections:
- Use connection pooling
- Implement proper connection cleanup
- Monitor connection limits

### Memory Usage:
- Most providers limit memory (512MB-1GB)
- Optimize imports and data processing
- Use streaming for large responses

## Troubleshooting

### Common Issues:

1. **Import Errors**:
   - Ensure all dependencies in requirements.txt
   - Check Python path configuration

2. **Environment Variables**:
   - Verify all required variables are set
   - Check variable names for typos

3. **Database Connection**:
   - Verify Supabase URL and credentials
   - Check network connectivity

4. **Cold Start Timeouts**:
   - Optimize application startup
   - Consider keeping endpoints warm

5. **Memory Issues**:
   - Monitor memory usage
   - Optimize data processing

### Debug Commands:
```bash
# Check deployment logs
vercel logs
az functionapp log tail --name trendit-api --resource-group trendit-rg

# Test endpoints
curl https://your-deployment-url.com/health
curl https://your-deployment-url.com/api/sentiment/status
```

## Scaling Considerations

### For High Traffic:
- **Render**: Scale to multiple instances
- **Vercel**: Automatic scaling, monitor costs
- **Azure Functions**: Premium plan with dedicated instances

### For Long-Running Jobs:
- Consider splitting collection jobs across multiple function calls
- Use queue systems for heavy processing
- Implement job status polling for frontend

## Security

### Production Security:
- Never commit secrets to git
- Use provider-specific secret management
- Enable HTTPS only
- Implement rate limiting
- Monitor API usage

### CORS Configuration:
```python
# In main.py, configure CORS for your frontend domains
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-frontend-domain.com"],
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

## Cost Estimation

### Monthly Costs (Approximate):
- **Render**: Free tier or $7/month
- **Vercel**: Free tier or $20/month  
- **Azure Functions**: $0-50/month depending on usage
- **Railway**: Free tier or $5/month
- **Google Cloud Run**: Pay-per-request, typically $0-20/month

Choose based on your traffic patterns, feature requirements, and budget constraints.