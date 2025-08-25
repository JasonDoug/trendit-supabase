#!/bin/bash
# Trendit API Deployment Script

set -e  # Exit on any error

echo "🚀 Trendit API Deployment Script"
echo "================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if provider argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: ./deploy.sh [render|vercel|azure|railway]"
    echo ""
    echo "Available deployment targets:"
    echo "  render  - Deploy to Render (recommended)"
    echo "  vercel  - Deploy to Vercel (serverless)"
    echo "  azure   - Deploy to Azure Functions"
    echo "  railway - Deploy to Railway"
    exit 1
fi

PROVIDER=$1

# Validate environment variables
check_env_vars() {
    print_info "Checking required environment variables..."
    
    required_vars=(
        "REDDIT_CLIENT_ID"
        "REDDIT_CLIENT_SECRET" 
        "USE_SUPABASE"
        "SUPABASE_URL"
        "SUPABASE_ANON_KEY"
        "SUPABASE_DB_URL"
    )
    
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        print_warning "Set these variables before deploying or configure them in your deployment platform"
        echo ""
    else
        print_status "All required environment variables are set"
    fi
}

# Test API endpoints locally
test_local() {
    print_info "Testing local API endpoints..."
    
    if ! command -v curl &> /dev/null; then
        print_warning "curl not found, skipping local tests"
        return
    fi
    
    # Check if server is running
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        print_status "Local server is running"
        
        # Test health endpoint
        health_response=$(curl -s http://localhost:8000/health)
        if [[ $health_response == *"healthy"* ]]; then
            print_status "Health check passed"
        else
            print_warning "Health check returned: $health_response"
        fi
        
        # Test sentiment status
        sentiment_response=$(curl -s http://localhost:8000/api/sentiment/status)
        print_info "Sentiment analysis status: $sentiment_response"
        
    else
        print_warning "Local server not running. Start with: cd backend && uvicorn main:app --reload"
    fi
}

# Deploy to Render
deploy_render() {
    print_info "Deploying to Render..."
    
    if [ ! -f "render.yaml" ]; then
        print_error "render.yaml not found. Please ensure it exists in the project root."
        exit 1
    fi
    
    print_status "render.yaml found"
    print_info "Next steps for Render deployment:"
    echo "1. Push your code to GitHub"
    echo "2. Go to https://render.com and create a new Web Service"
    echo "3. Connect your GitHub repository"
    echo "4. Render will automatically use render.yaml for configuration"
    echo "5. Set environment variables in Render dashboard"
    echo "6. Deploy!"
    
    print_warning "Manual setup required - Render doesn't support CLI deployments with YAML config"
}

# Deploy to Vercel
deploy_vercel() {
    print_info "Deploying to Vercel..."
    
    # Check if Vercel CLI is installed
    if ! command -v vercel &> /dev/null; then
        print_error "Vercel CLI not found. Install with: npm install -g vercel"
        exit 1
    fi
    
    if [ ! -f "vercel.json" ]; then
        print_error "vercel.json not found. Please ensure it exists in the project root."
        exit 1
    fi
    
    if [ ! -f "api/index.py" ]; then
        print_error "api/index.py not found. Please ensure it exists."
        exit 1
    fi
    
    print_status "Vercel configuration files found"
    print_info "Setting environment variables..."
    
    # Set environment variables (will prompt for values if not set)
    env_vars=(
        "REDDIT_CLIENT_ID"
        "REDDIT_CLIENT_SECRET" 
        "REDDIT_USER_AGENT"
        "OPENROUTER_API_KEY"
        "USE_SUPABASE"
        "SUPABASE_URL"
        "SUPABASE_ANON_KEY"
        "SUPABASE_DB_URL"
    )
    
    for var in "${env_vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo "${!var}" | vercel env add "$var" production
        else
            print_warning "Environment variable $var not set locally"
        fi
    done
    
    print_info "Deploying to production..."
    vercel --prod
    
    if [ $? -eq 0 ]; then
        print_status "Deployment successful!"
        print_info "Your API is now available at the Vercel URL shown above"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Deploy to Azure Functions
deploy_azure() {
    print_info "Deploying to Azure Functions..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if Functions Core Tools is installed
    if ! command -v func &> /dev/null; then
        print_error "Azure Functions Core Tools not found. Install with: npm install -g azure-functions-core-tools@4"
        exit 1
    fi
    
    if [ ! -d "azure-functions" ]; then
        print_error "azure-functions directory not found"
        exit 1
    fi
    
    print_status "Azure configuration found"
    
    # Login to Azure
    print_info "Checking Azure login..."
    if ! az account show &> /dev/null; then
        print_info "Logging in to Azure..."
        az login
    fi
    
    print_status "Azure login confirmed"
    
    # Deploy function app
    cd azure-functions
    print_info "Publishing function app..."
    
    # Prompt for function app name if not set
    if [ -z "$AZURE_FUNCTION_APP_NAME" ]; then
        echo -n "Enter your Azure Function App name: "
        read AZURE_FUNCTION_APP_NAME
    fi
    
    func azure functionapp publish "$AZURE_FUNCTION_APP_NAME"
    
    if [ $? -eq 0 ]; then
        print_status "Deployment successful!"
        print_info "Your API is now available at: https://$AZURE_FUNCTION_APP_NAME.azurewebsites.net"
    else
        print_error "Deployment failed"
        exit 1
    fi
    
    cd ..
}

# Deploy to Railway
deploy_railway() {
    print_info "Deploying to Railway..."
    
    # Check if Railway CLI is installed
    if ! command -v railway &> /dev/null; then
        print_error "Railway CLI not found. Install with: npm install -g @railway/cli"
        exit 1
    fi
    
    print_info "Logging in to Railway..."
    railway login
    
    print_info "Linking project..."
    railway link
    
    print_info "Setting environment variables..."
    env_vars=(
        "REDDIT_CLIENT_ID"
        "REDDIT_CLIENT_SECRET" 
        "REDDIT_USER_AGENT"
        "OPENROUTER_API_KEY"
        "USE_SUPABASE"
        "SUPABASE_URL"
        "SUPABASE_ANON_KEY"
        "SUPABASE_DB_URL"
    )
    
    for var in "${env_vars[@]}"; do
        if [ -n "${!var}" ]; then
            railway variables set "$var=${!var}"
        fi
    done
    
    print_info "Deploying..."
    railway up
    
    if [ $? -eq 0 ]; then
        print_status "Deployment successful!"
        railway open
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Main deployment logic
main() {
    print_info "Deploying to: $PROVIDER"
    echo ""
    
    # Run checks
    check_env_vars
    test_local
    
    echo ""
    
    case $PROVIDER in
        "render")
            deploy_render
            ;;
        "vercel")
            deploy_vercel
            ;;
        "azure")
            deploy_azure
            ;;
        "railway")
            deploy_railway
            ;;
        *)
            print_error "Unknown provider: $PROVIDER"
            echo "Supported providers: render, vercel, azure, railway"
            exit 1
            ;;
    esac
    
    echo ""
    print_status "Deployment process completed!"
    print_info "Don't forget to:"
    echo "  - Set up custom domain (if needed)"
    echo "  - Configure monitoring and alerts"
    echo "  - Test all endpoints after deployment"
    echo "  - Update CORS settings for your frontend domain"
}

# Run main function
main