# Quick Deployment Reference

## 🚀 Quick Start

### Deploy Backend to Azure (5 minutes) - FREE Tier

**Free tier limits:** 1 GB storage, 60 min/day CPU time. Upgrade to B1 ($12/month) for unlimited usage.

```bash
# 1. Set credentials
export DIRECT_LINE_SECRET="your-secret-from-bot-service"
export DEPLOYMENT_USER="your-username"
export DEPLOYMENT_PASSWORD="your-strong-password"
export ALLOWED_ORIGIN="https://automateversellc.com"

# 2. Run deployment script
cd myeai-av-site-repo
bash deploy-to-azure.sh

# 3. Push code to Azure
cd ../webchat-integration-sample
git remote add azure <git-url-from-script>
git push azure main

# 4. Update frontend endpoint
cd ../myeai-av-site-repo
# Edit js/chat-widget.js line 16
git add js/chat-widget.js
git commit -m "Update backend endpoint"
git push origin main
```

### Deploy Frontend to GitHub Pages (Already Done)

```bash
# GitHub Pages auto-deploys from main branch
# Just push to trigger rebuild
cd myeai-av-site-repo
git push origin main
```

---

## 📋 Command Reference

### Azure CLI Commands

```bash
# Login
az login

# Create resource group
az group create --name automateverse-rg --location eastus

# Create App Service Plan - FREE Tier
az appservice plan create --name automateverse-plan \
  --resource-group automateverse-rg --sku F1 --is-linux

# Create Web App
az webapp create --resource-group automateverse-rg \
  --plan automateverse-plan --name automateverse-backend \
  --runtime "node|20-lts"

# Set environment variables
az webapp config appsettings set \
  --resource-group automateverse-rg --name automateverse-backend \
  --settings DIRECT_LINE_SECRET="your-secret" \
    ALLOWED_ORIGIN="https://automateversellc.com" \
    NODE_ENV="production" PORT="8080"

# View logs
az webapp log tail --resource-group automateverse-rg \
  --name automateverse-backend

# Check status
az webapp show --resource-group automateverse-rg \
  --name automateverse-backend \
  --query "{State: state, Url: defaultHostName}"
```

### Git Deployment

```bash
# Get Git endpoint
az webapp deployment source config-local-git \
  --resource-group automateverse-rg \
  --name automateverse-backend

# Set deployment credentials
az webapp deployment user set --user-name <username> \
  --password <password>

# Add Azure remote
git remote add azure <git-endpoint-url>

# Deploy
git push azure main
```

### Verify Deployment

```bash
# Test health endpoint
curl https://automateverse-backend.azurewebsites.net/healthz

# Test token endpoint
curl -X POST \
  https://automateverse-backend.azurewebsites.net/api/webchat/token \
  -H "Origin: https://automateversellc.com"

# Check website
open https://automateversellc.com
```

---

## 🔧 Troubleshooting

### Backend not responding

```bash
# Check app status
az webapp show --resource-group automateverse-rg \
  --name automateverse-backend

# View logs
az webapp log tail --resource-group automateverse-rg \
  --name automateverse-backend

# Restart app
az webapp restart --resource-group automateverse-rg \
  --name automateverse-backend

# Check settings
az webapp config appsettings list \
  --resource-group automateverse-rg \
  --name automateverse-backend
```

### CORS errors

```bash
# Verify ALLOWED_ORIGIN
az webapp config appsettings list \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --query "[?name=='ALLOWED_ORIGIN']"

# Update if needed
az webapp config appsettings set \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --settings ALLOWED_ORIGIN="https://automateversellc.com"
```

### Chat not loading

1. Check browser console for errors (`F12`)
2. Verify token endpoint URL in `js/chat-widget.js`
3. Confirm backend is responding to `/api/webchat/token`
4. Check DIRECT_LINE_SECRET is set correctly

### Need to redeploy

```bash
cd webchat-integration-sample
git push azure main --force
```

---

## 📊 Monitoring

### View metrics

```bash
az monitor metrics list-definitions \
  --resource /subscriptions/{subscription-id}/resourceGroups/automateverse-rg/providers/Microsoft.Web/sites/automateverse-backend
```

### Enable Auto-scaling (Optional)

```bash
az monitor autoscale-settings create \
  --resource-group automateverse-rg \
  --resource automateverse-plan \
  --resource-type "Microsoft.Web/serverfarms" \
  --name automateverse-autoscale \
  --min-count 1 --max-count 3 --count 1
```

### Scale up the app (if hitting Free tier limits)

```bash
# Upgrade to B1 tier ($12/month)
az appservice plan update --resource-group automateverse-rg \
  --name automateverse-plan --sku B1
```

---

## 🗑️ Cleanup

```bash
# Delete everything
az group delete --name automateverse-rg --yes --no-wait

# Delete specific app only
az webapp delete --resource-group automateverse-rg \
  --name automateverse-backend
```

---

## ✅ Deployment Checklist

- [ ] Set `DIRECT_LINE_SECRET` environment variable
- [ ] Set `DEPLOYMENT_USER` and `DEPLOYMENT_PASSWORD`
- [ ] Run `deploy-to-azure.sh` script
- [ ] Push code to Azure Git: `git push azure main`
- [ ] Health endpoint responds: `curl https://automateverse-backend.azurewebsites.net/healthz`
- [ ] Token endpoint works: `curl -X POST https://automateverse-backend.azurewebsites.net/api/webchat/token`
- [ ] Update `js/chat-widget.js` with backend URL
- [ ] Push frontend to GitHub: `git push origin main`
- [ ] Test chat on https://automateversellc.com
- [ ] Verify logs have no errors

---

## 📚 Resources

| Resource | Link |
|----------|------|
| Azure CLI Install | https://learn.microsoft.com/cli/azure/install-azure-cli |
| App Service Docs | https://learn.microsoft.com/en-us/azure/app-service/ |
| GitHub Pages Docs | https://docs.github.com/en/pages |
| Bot Framework | https://github.com/microsoft/BotFramework-WebChat |
| Azure Pricing | https://azure.microsoft.com/pricing/ |

---

## 💰 Cost Estimate

| Service | Tier | Monthly Cost |
|---------|------|--------------|
| App Service Plan | F1 (Free) | FREE* |
| GitHub Pages | - | FREE |
| Data Transfer | - | FREE (first 1GB) |
| **Total** | | **FREE*** |

*F1 Free tier: 1 GB storage, 60 min/day CPU time, single shared instance. Upgrade to B1 ($12/month) for production use.
