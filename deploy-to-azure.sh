#!/bin/bash

# AutomateVerse Backend - Azure Deployment Script
# Usage: bash deploy-to-azure.sh

set -e

# ============================================
# Configuration
# ============================================

RESOURCE_GROUP="automateverse-rg"
REGION="eastus"
APP_SERVICE_PLAN="automateverse-plan"
APP_NAME="automateverse-backend"
RUNTIME="node|20-lts"
SKU="F1"  # Free tier

# Set these before running:
DIRECT_LINE_SECRET=${DIRECT_LINE_SECRET:-""}
ALLOWED_ORIGIN=${ALLOWED_ORIGIN:-"https://automateversellc.com"}
DEPLOYMENT_USER=${DEPLOYMENT_USER:-""}
DEPLOYMENT_PASSWORD=${DEPLOYMENT_PASSWORD:-""}

# ============================================
# Functions
# ============================================

log() {
  echo "ℹ️  $1"
}

success() {
  echo "✅ $1"
}

error() {
  echo "❌ $1"
  exit 1
}

check_prerequisites() {
  log "Checking prerequisites..."
  
  command -v az >/dev/null 2>&1 || error "Azure CLI not found. Install: https://learn.microsoft.com/cli/azure/install-azure-cli"
  
  az account show >/dev/null 2>&1 || error "Not logged into Azure. Run: az login"
  
  [ -n "$DIRECT_LINE_SECRET" ] || error "DIRECT_LINE_SECRET not set. Export it: export DIRECT_LINE_SECRET='your-secret'"
  [ -n "$DEPLOYMENT_USER" ] || error "DEPLOYMENT_USER not set. Export it: export DEPLOYMENT_USER='your-username'"
  [ -n "$DEPLOYMENT_PASSWORD" ] || error "DEPLOYMENT_PASSWORD not set. Export it: export DEPLOYMENT_PASSWORD='your-password'"
  
  success "Prerequisites checked"
}

create_resource_group() {
  log "Creating resource group: $RESOURCE_GROUP"
  
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$REGION" \
    >/dev/null || log "Resource group already exists"
  
  success "Resource group ready"
}

create_app_service_plan() {
  log "Creating App Service Plan: $APP_SERVICE_PLAN"
  
  az appservice plan create \
    --name "$APP_SERVICE_PLAN" \
    --resource-group "$RESOURCE_GROUP" \
    --sku "$SKU" \
    --is-linux \
    >/dev/null || log "App Service Plan already exists"
  
  success "App Service Plan ready"
}

create_web_app() {
  log "Creating Web App: $APP_NAME"
  
  az webapp create \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN" \
    --name "$APP_NAME" \
    --runtime "$RUNTIME" \
    >/dev/null || log "Web App already exists"
  
  success "Web App ready"
}

configure_deployment() {
  log "Configuring Git-based deployment..."
  
  az webapp deployment user set \
    --user-name "$DEPLOYMENT_USER" \
    --password "$DEPLOYMENT_PASSWORD" \
    >/dev/null
  
  az webapp deployment source config-local-git \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    >/dev/null
  
  success "Deployment configured"
}

configure_environment() {
  log "Configuring environment variables..."
  
  az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --settings \
      DIRECT_LINE_SECRET="$DIRECT_LINE_SECRET" \
      ALLOWED_ORIGIN="$ALLOWED_ORIGIN" \
      NODE_ENV="production" \
      PORT="8080" \
    >/dev/null
  
  success "Environment variables configured"
}

enable_logging() {
  log "Enabling diagnostic logging..."
  
  az webapp log config \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --web-server-logging filesystem \
    >/dev/null
  
  success "Logging enabled"
}

deploy_code() {
  log "Deploying code via Git..."
  
  GIT_URL=$(az webapp deployment source config-local-git \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --query "url" \
    --output tsv)
  
  log "Git deployment URL: $GIT_URL"
  log "Next steps:"
  echo ""
  echo "  cd webchat-integration-sample"
  echo "  git remote add azure $GIT_URL"
  echo "  git push azure main"
  echo ""
  
  success "Ready for Git deployment"
}

verify_deployment() {
  log "Waiting for app to start (this may take 1-2 minutes)..."
  sleep 10
  
  APP_URL="https://${APP_NAME}.azurewebsites.net"
  
  log "Testing health endpoint: $APP_URL/healthz"
  
  # Try up to 30 times (5 minutes)
  for i in {1..30}; do
    if curl -s "$APP_URL/healthz" | grep -q "ok"; then
      success "Health check passed!"
      success "Backend deployed successfully at: $APP_URL"
      return 0
    fi
    if [ $i -lt 30 ]; then
      log "Attempt $i/30: Waiting for app to be ready..."
      sleep 10
    fi
  done
  
  error "Health check failed after 5 minutes. Check logs: az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME"
}

view_logs() {
  log "Tailing application logs..."
  echo ""
  log "Press Ctrl+C to stop"
  echo ""
  
  az webapp log tail \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --lines 50
}

# ============================================
# Main
# ============================================

main() {
  echo ""
  echo "🚀 AutomateVerse Backend - Azure Deployment"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  check_prerequisites
  create_resource_group
  create_app_service_plan
  create_web_app
  configure_deployment
  configure_environment
  enable_logging
  deploy_code
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  success "Azure infrastructure created!"
  echo ""
  log "Resource Group: $RESOURCE_GROUP"
  log "App Service Plan: $APP_SERVICE_PLAN"
  log "Web App: $APP_NAME"
  log "Region: $REGION"
  log "Tier: Free (F1) - 1 GB storage, 60 min/day CPU time"
  echo ""
  
  read -p "View logs now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    view_logs
  fi
}

# Run main
main
