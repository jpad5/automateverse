# Deployment Guide: GitHub Pages + Azure

This guide covers deploying the AutomateVerse website to GitHub Pages and the webchat backend to Azure App Service.

## Overview

```
┌──────────────────────────────────────────────────────────────┐
│ GitHub Pages (Static Website)                                │
│ - index.html, CSS, JS                                        │
│ - Hosted at: https://automateversellc.com                    │
│ - CNAME: Custom domain configuration                         │
└──────────────────────────────────────────────────────────────┘
                              ↓
                      (CORS-enabled HTTP)
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ Azure App Service (Backend Server)                           │
│ - Node.js Express server                                     │
│ - Token generation endpoint (/api/webchat/token)             │
│ - Hosted at: https://automateverse-backend.azurewebsites.net │
└──────────────────────────────────────────────────────────────┘
```

> **Note:** This guide uses **Azure App Service Free tier (F1)** — no cost, but limited to 1 GB storage and 60 minutes of CPU time per day. For production use with higher traffic, upgrade to B1 tier (~$12/month). See [Scaling & Performance](#part-6-scaling--performance) for upgrade instructions.

---

## Part 1: Deploy Frontend to GitHub Pages

### Prerequisites
- Repository pushed to GitHub at `jpad5/automateverse`
- CNAME file already in repo (`automateversellc.com`)

### Step 1: Enable GitHub Pages

1. Go to **Settings** → **Pages**
2. Under "Build and deployment":
   - **Source**: Select "Deploy from a branch"
   - **Branch**: Select `main` / `root` folder
3. Click **Save**
4. Wait 1-2 minutes for deployment

### Step 2: Verify Custom Domain

1. DNS records should point to GitHub Pages (if not already):
   ```
   Type: A
   Name: @
   Value: 185.199.108.153
         185.199.109.153
         185.199.110.153
         185.199.111.153
   
   OR
   
   Type: CNAME
   Name: www
   Value: jpad5.github.io
   ```

2. Check GitHub Pages settings shows:
   - ✓ Domain verified
   - ✓ HTTPS enforced
   - ✓ Certificate issued

### Step 3: Update Token Endpoint URL

The static site needs to know where to find the backend token endpoint.

**Option A: Environment variable (local development)**
```bash
export WEBCHAT_TOKEN_ENDPOINT=http://localhost:3000/api/webchat/token
npm start  # Local server
```

**Option B: Update in js/chat-widget.js (production)**
After deploying backend to Azure, update line 16:

```javascript
const tokenEndpoint = 'https://automateverse-backend.azurewebsites.net/api/webchat/token';
```

Then push the update to trigger GitHub Pages rebuild.

### Verification
- [ ] Site loads at https://automateversellc.com
- [ ] HTTPS certificate valid
- [ ] All pages accessible
- [ ] Chat widget loads (will show connection error until backend is deployed)

---

## Part 2: Deploy Backend to Azure App Service

### Prerequisites
- Azure subscription
- Azure CLI installed: https://learn.microsoft.com/cli/azure/install-azure-cli
- Logged in: `az login`

### Step 1: Create Azure Resources

#### Create Resource Group
```bash
az group create \
  --name automateverse-rg \
  --location eastus
```

#### Create App Service Plan
```bash
az appservice plan create \
  --name automateverse-plan \
  --resource-group automateverse-rg \
  --sku F1 \
  --is-linux
```

> **F1 Free Tier:** 1 GB storage, 60 min/day shared CPU time. Automatically stops after 1 minute of inactivity. To upgrade to paid tier, see [Scaling & Performance](#part-6-scaling--performance).

#### Create Web App
```bash
az webapp create \
  --resource-group automateverse-rg \
  --plan automateverse-plan \
  --name automateverse-backend \
  --runtime "node|20-lts"
```

### Step 2: Deploy Code

#### Option A: Git-based Deployment (Recommended)

1. **Configure deployment credentials:**
   ```bash
   az webapp deployment user set \
     --user-name <username> \
     --password <password>
   ```

2. **Get Git URL:**
   ```bash
   az webapp deployment source config-local-git \
     --resource-group automateverse-rg \
     --name automateverse-backend
   ```
   
   Returns something like:
   ```
   https://<username>@automateverse-backend.scm.azurewebsites.net/automateverse-backend.git
   ```

3. **Add Azure remote to your repository:**
   ```bash
   cd webchat-integration-sample
   git remote add azure <git-url-from-above>
   ```

4. **Deploy:**
   ```bash
   git push azure main
   ```

#### Option B: ZIP Deployment (Quick)

```bash
cd webchat-integration-sample

# Create deployment package
npm install
zip -r backend.zip . -x "node_modules/*" ".git/*"

# Deploy
az webapp deployment source config-zip \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --src-path backend.zip
```

### Step 3: Configure Environment Variables

Set the required environment variables in Azure:

```bash
# Direct Line secret (get from Bot Service)
az webapp config appsettings set \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --settings DIRECT_LINE_SECRET="your-secret-here"

# Allow CORS from your domain
az webapp config appsettings set \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --settings ALLOWED_ORIGIN="https://automateversellc.com"

# Node environment
az webapp config appsettings set \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --settings NODE_ENV="production"

# Port (Azure uses port 8080 by default)
az webapp config appsettings set \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --settings PORT="8080"
```

### Step 4: Enable Logging (Optional but Recommended)

```bash
az webapp log config \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --web-server-logging filesystem \
  --docker-container-logging filesystem
```

View logs:
```bash
az webapp log tail \
  --resource-group automateverse-rg \
  --name automateverse-backend
```

### Verification

```bash
# Check health endpoint
curl https://automateverse-backend.azurewebsites.net/healthz

# Should return:
# {"ok":true}

# Test token endpoint
curl -X POST https://automateverse-backend.azurewebsites.net/api/webchat/token
```

---

## Part 3: Connect Frontend to Backend

### Update Frontend Token Endpoint

Edit `js/chat-widget.js` line 16:

```javascript
// Before (local)
const tokenEndpoint = process.env.WEBCHAT_TOKEN_ENDPOINT || '/api/webchat/token';

// After (production Azure)
const tokenEndpoint = 'https://automateverse-backend.azurewebsites.net/api/webchat/token';
```

Or keep it flexible:
```javascript
const tokenEndpoint = 
  process.env.NODE_ENV === 'production' 
    ? 'https://automateverse-backend.azurewebsites.net/api/webchat/token'
    : '/api/webchat/token';
```

### Verify CORS Configuration

The backend must allow requests from GitHub Pages:

```javascript
// In server.mjs, already configured:
const allowedOrigin = process.env.ALLOWED_ORIGIN;
// Set via: ALLOWED_ORIGIN=https://automateversellc.com
```

### Push Changes to GitHub

```bash
cd myeai-av-site-repo
git add js/chat-widget.js
git commit -m "Update token endpoint to production Azure backend"
git push origin main
```

GitHub Pages automatically rebuilds (wait ~1 min).

---

## Part 4: End-to-End Testing

### Local Testing (Before Production)

1. **Start backend locally:**
   ```bash
   cd webchat-integration-sample
   PORT=3000 npm start
   ```

2. **Serve frontend locally:**
   ```bash
   cd myeai-av-site-repo
   python -m http.server 8000
   ```

3. **Test:**
   - Open http://localhost:8000
   - Click chat widget
   - Verify token fetched and chat initializes

### Production Testing

1. **Test backend health:**
   ```bash
   curl https://automateverse-backend.azurewebsites.net/healthz
   ```

2. **Test token endpoint:**
   ```bash
   curl -X POST \
     https://automateverse-backend.azurewebsites.net/api/webchat/token \
     -H "Origin: https://automateversellc.com"
   ```

3. **Test live site:**
   - Open https://automateversellc.com
   - Check browser console for errors
   - Click chat widget
   - Verify token fetches and chat loads

---

## Part 5: Monitoring & Troubleshooting

### Check Deployment Status

```bash
# App Service status
az webapp show \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --query "{State: state, DefaultHostName: defaultHostName}"

# Recent deployments
az webapp deployment list \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --query "[0:5]"
```

### Common Issues

#### 1. 404 Token Endpoint

**Error:** Frontend gets 404 from `/api/webchat/token`

**Solution:**
- Verify backend deployed and running
- Check token endpoint URL in chat-widget.js
- Check ALLOWED_ORIGIN matches frontend domain

#### 2. CORS Error

**Error:** "Access to XMLHttpRequest blocked by CORS policy"

**Solution:**
```bash
# Verify ALLOWED_ORIGIN setting
az webapp config appsettings list \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  --query "[?name=='ALLOWED_ORIGIN']"
```

#### 3. WebChat Not Loading

**Error:** Chat panel opens but webchat doesn't render

**Check:**
- Web Chat CDN loads: `window.WebChat` in console
- Token is valid JSON
- Bot Framework endpoint accessible
- DIRECT_LINE_SECRET configured correctly

#### 4. Bot Doesn't Respond

**Check:**
- Bot Service is deployed and healthy
- Direct Line channel enabled
- DIRECT_LINE_SECRET is correct
- Bot endpoint configuration

### View Logs

```bash
# Stream logs in real-time
az webapp log tail \
  --resource-group automateverse-rg \
  --name automateverse-backend

# Search for errors
az webapp log tail \
  --resource-group automateverse-rg \
  --name automateverse-backend \
  | grep -i error
```

---

## Part 6: Scaling & Performance

### Monitor Performance

```bash
# View metrics
az monitor metrics list-definitions \
  --resource /subscriptions/{subscription-id}/resourceGroups/automateverse-rg/providers/Microsoft.Web/sites/automateverse-backend
```

### Scale Up from Free Tier

If you hit Free tier limits (1 GB storage or 60 min/day CPU):

```bash
# Change to B1 tier ($12/month, unlimited)
az appservice plan update \
  --resource-group automateverse-rg \
  --name automateverse-plan \
  --sku B1
```

---

## Part 7: Cleanup (If Needed)

```bash
# Delete everything
az group delete \
  --name automateverse-rg \
  --yes --no-wait

# Or delete individual resources
az webapp delete \
  --resource-group automateverse-rg \
  --name automateverse-backend
```

---

## Deployment Checklist

### GitHub Pages
- [ ] Repository is public
- [ ] CNAME file configured for custom domain
- [ ] GitHub Pages enabled in repository settings
- [ ] DNS records point to GitHub Pages IPs
- [ ] HTTPS certificate valid
- [ ] Site loads at custom domain

### Azure Backend
- [ ] Resource group created
- [ ] App Service Plan created
- [ ] Web App created (Node.js 20 LTS)
- [ ] Code deployed (git push or ZIP)
- [ ] Environment variables configured
- [ ] DIRECT_LINE_SECRET set
- [ ] ALLOWED_ORIGIN set to GitHub Pages domain
- [ ] Health endpoint responds with `{"ok":true}`
- [ ] Token endpoint accessible and returns token

### Integration
- [ ] Frontend token endpoint URL updated
- [ ] CORS headers correct
- [ ] Frontend and backend can communicate
- [ ] Chat widget works end-to-end
- [ ] Bot responds to messages

### Monitoring
- [ ] Application logging enabled
- [ ] Error monitoring configured
- [ ] Health check alerts set up (optional)

---

## Support Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Bot Framework Web Chat Deployment](https://github.com/microsoft/BotFramework-WebChat/blob/main/README.md)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
