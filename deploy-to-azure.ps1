# AutomateVerse Backend - Azure Deployment Script (Windows PowerShell)
# Usage: .\deploy-to-azure.ps1

param(
    [string]$ResourceGroup = "automateverse-rg",
    [string]$Region = "eastus",
    [string]$AppServicePlan = "automateverse-plan",
    [string]$AppName = "automateverse-backend",
    [string]$Sku = "F1",  # Free tier
    [string]$Runtime = "node|20-lts"
)

# ============================================
# Configuration
# ============================================

$ErrorActionPreference = "Stop"

# Check for required environment variables
if ([string]::IsNullOrEmpty($env:DIRECT_LINE_SECRET)) {
    Write-Host "❌ DIRECT_LINE_SECRET environment variable not set" -ForegroundColor Red
    Write-Host "Set it with: `$env:DIRECT_LINE_SECRET = 'your-secret'" -ForegroundColor Yellow
    exit 1
}

if ([string]::IsNullOrEmpty($env:DEPLOYMENT_USER)) {
    Write-Host "❌ DEPLOYMENT_USER environment variable not set" -ForegroundColor Red
    Write-Host "Set it with: `$env:DEPLOYMENT_USER = 'your-username'" -ForegroundColor Yellow
    exit 1
}

if ([string]::IsNullOrEmpty($env:DEPLOYMENT_PASSWORD)) {
    Write-Host "❌ DEPLOYMENT_PASSWORD environment variable not set" -ForegroundColor Red
    Write-Host "Set it with: `$env:DEPLOYMENT_PASSWORD = 'your-password'" -ForegroundColor Yellow
    exit 1
}

$AllowedOrigin = if ($env:ALLOWED_ORIGIN) { $env:ALLOWED_ORIGIN } else { "https://automateversellc.com" }
$DirectLineSecret = $env:DIRECT_LINE_SECRET
$DeploymentUser = $env:DEPLOYMENT_USER
$DeploymentPassword = $env:DEPLOYMENT_PASSWORD

# ============================================
# Functions
# ============================================

function Write-Log {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
    exit 1
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    $azExists = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
    if (-not $azExists) {
        Write-Error "Azure CLI not found. Install from: https://learn.microsoft.com/cli/azure/install-azure-cli"
    }
    
    $account = az account show 2>$null
    if (-not $account) {
        Write-Error "Not logged into Azure. Run: az login"
    }
    
    Write-Success "Prerequisites checked"
}

function New-ResourceGroup {
    Write-Log "Creating resource group: $ResourceGroup"
    
    az group create `
        --name $ResourceGroup `
        --location $Region `
        | Out-Null
    
    Write-Success "Resource group ready"
}

function New-AppServicePlan {
    Write-Log "Creating App Service Plan: $AppServicePlan"
    
    az appservice plan create `
        --name $AppServicePlan `
        --resource-group $ResourceGroup `
        --sku $Sku `
        --is-linux `
        | Out-Null
    
    Write-Success "App Service Plan ready"
}

function New-WebApp {
    Write-Log "Creating Web App: $AppName"
    
    az webapp create `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --name $AppName `
        --runtime $Runtime `
        | Out-Null
    
    Write-Success "Web App ready"
}

function Set-DeploymentConfig {
    Write-Log "Configuring Git-based deployment..."
    
    az webapp deployment user set `
        --user-name $DeploymentUser `
        --password $DeploymentPassword `
        | Out-Null
    
    az webapp deployment source config-local-git `
        --resource-group $ResourceGroup `
        --name $AppName `
        | Out-Null
    
    Write-Success "Deployment configured"
}

function Set-EnvironmentVariables {
    Write-Log "Configuring environment variables..."
    
    az webapp config appsettings set `
        --resource-group $ResourceGroup `
        --name $AppName `
        --settings `
            DIRECT_LINE_SECRET=$DirectLineSecret `
            ALLOWED_ORIGIN=$AllowedOrigin `
            NODE_ENV="production" `
            PORT="8080" `
        | Out-Null
    
    Write-Success "Environment variables configured"
}

function Enable-Logging {
    Write-Log "Enabling diagnostic logging..."
    
    az webapp log config `
        --resource-group $ResourceGroup `
        --name $AppName `
        --web-server-logging filesystem `
        | Out-Null
    
    Write-Success "Logging enabled"
}

function Get-DeploymentInfo {
    Write-Log "Getting Git deployment URL..."
    
    $gitUrl = az webapp deployment source config-local-git `
        --resource-group $ResourceGroup `
        --name $AppName `
        --query "url" `
        --output tsv
    
    Write-Host ""
    Write-Host "📋 Git Deployment URL:" -ForegroundColor Yellow
    Write-Host $gitUrl -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  cd webchat-integration-sample" -ForegroundColor White
    Write-Host "  git remote add azure $gitUrl" -ForegroundColor White
    Write-Host "  git push azure main" -ForegroundColor White
    Write-Host ""
}

function Test-Deployment {
    Write-Log "Waiting for app to start (this may take 1-2 minutes)..."
    
    $appUrl = "https://${AppName}.azurewebsites.net"
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "$appUrl/healthz" -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "Health check passed!"
                Write-Success "Backend deployed successfully at: $appUrl"
                return
            }
        }
        catch {
            # Expected during startup
        }
        
        if ($attempt -lt $maxAttempts) {
            Write-Log "Attempt $attempt/$maxAttempts`: Waiting for app to be ready..."
            Start-Sleep -Seconds 10
        }
        
        $attempt++
    }
    
    Write-Error "Health check failed after 5 minutes. Check logs: az webapp log tail --resource-group $ResourceGroup --name $AppName"
}

# ============================================
# Main
# ============================================

Write-Host ""
Write-Host "🚀 AutomateVerse Backend - Azure Deployment" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""

Test-Prerequisites
New-ResourceGroup
New-AppServicePlan
New-WebApp
Set-DeploymentConfig
Set-EnvironmentVariables
Enable-Logging
Get-DeploymentInfo

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""
Write-Success "Azure infrastructure created!"
Write-Host ""
Write-Log "Resource Group: $ResourceGroup"
Write-Log "App Service Plan: $AppServicePlan"
Write-Log "Web App: $AppName"
Write-Log "Region: $Region"
Write-Log "Tier: Free (F1) - 1 GB storage, 60 min/day CPU time"
Write-Host ""

$response = Read-Host "View logs now? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Log "Tailing application logs (Ctrl+C to stop)..."
    Write-Host ""
    az webapp log tail --resource-group $ResourceGroup --name $AppName
}
