# Webchat Integration Guide

This document explains how the chat widget has been integrated into the AutomateVerse website.

## Integration Overview

The webchat functionality has been added to the av site with the following components:

### Frontend Files Added
- **css/chat-widget.css** — Styles for the chat launcher button and panel
- **js/chat-widget.js** — JavaScript logic for chat initialization and interaction
- **index.html** — Updated to include chat widget HTML elements and script references

### Backend Requirements
The webchat requires a backend server to generate secure tokens for Direct Line connections. The backend is NOT included in the static site (since GitHub Pages only serves static files).

## Architecture

```
┌─────────────────────────────────────────┐
│   Automate Website (Static)             │
│   - index.html                          │
│   - chat-widget.js                      │
│   - chat-widget.css                     │
└──────────────┬──────────────────────────┘
               │
               │ HTTP POST /api/webchat/token
               ▼
┌─────────────────────────────────────────┐
│   Webchat Backend Server (Node.js)      │
│   - server.mjs                          │
│   - Token generation endpoint           │
│   - CORS configuration                  │
└─────────────────────────────────────────┘
               │
               │ Exchange for Direct Line token
               ▼
┌─────────────────────────────────────────┐
│   Bot Framework / Azure Bot Service     │
│   - Direct Line connection              │
│   - Bot backend                         │
└─────────────────────────────────────────┘
```

## Setup Instructions

### 1. Prepare the Backend Server

The backend server code is located in the `webchat-integration-sample` folder. To deploy it:

#### Option A: Deploy to Azure App Service
```bash
cd webchat-integration-sample
npm install
azd up
```

#### Option B: Run Locally for Development
```bash
cd webchat-integration-sample
npm install
PORT=3000 npm start
```

### 2. Configure the Token Endpoint

Update the token endpoint in **js/chat-widget.js** if needed:

```javascript
const tokenEndpoint = process.env.WEBCHAT_TOKEN_ENDPOINT || '/api/webchat/token';
```

**For GitHub Pages (production):**
- The site needs to know where to find the token endpoint
- Update the environment variable or configure CORS on the backend

**For local development:**
- Use `http://localhost:3000/api/webchat/token` (if running locally)

### 3. Backend Configuration

The backend server requires one of these environment variables:

#### Option A: Bot Framework Direct Line
```bash
DIRECT_LINE_SECRET=your_direct_line_secret_here
```

#### Option B: Copilot Studio Bot
```bash
COPILOT_STUDIO_BOT_ID=your_bot_id_here
```

#### CORS Configuration
If the frontend and backend are on different domains:
```bash
ALLOWED_ORIGIN=https://automateversellc.com
```

## Chat Widget Features

- **Launcher Button** — Fixed button in bottom-right corner to open/close chat
- **Chat Panel** — Collapsible panel with branding, restart, and close buttons
- **Auto-connect** — Connects to the bot on first interaction
- **Status Messages** — Shows connection status to user
- **Page Context** — Sends page URL and title to bot for context-aware responses
- **Prompt Buttons** — Can add data-prompt attributes to buttons for pre-filled questions

## Customization

### Add Quick-Action Buttons
Add buttons with `data-prompt` attribute anywhere on the page:

```html
<button class="prompt-chip" data-prompt="What services do you offer?">Services</button>
```

### Style Customization
Edit **css/chat-widget.css** to customize:
- Colors (--brand, --ink, etc.)
- Size and positioning
- Animation effects

### Branded Avatar and Colors
In **js/chat-widget.js**, update the styleOptions:

```javascript
const styleOptions = {
  accent: '#0f766e',
  botAvatarInitials: 'AV',
  userAvatarInitials: 'You',
  // ... more options
};
```

## Deployment Checklist

- [ ] Backend server deployed and accessible
- [ ] Environment variables configured (DIRECT_LINE_SECRET or COPILOT_STUDIO_BOT_ID)
- [ ] CORS configured for production domain
- [ ] Token endpoint accessible from the frontend
- [ ] Chat widget appears in bottom-right corner of website
- [ ] Chat opens/closes properly
- [ ] Bot responds to messages

## Troubleshooting

### Chat doesn't open
- Check browser console for errors
- Verify chat-widget.js is loading (Network tab)
- Ensure all HTML elements (id="chat-launcher", id="chat-panel", etc.) exist

### "Unable to start chat" error
- Check token endpoint is responding: `curl -X POST http://your-backend/api/webchat/token`
- Verify DIRECT_LINE_SECRET or COPILOT_STUDIO_BOT_ID is set on backend
- Check CORS headers if backend is on different domain

### Bot doesn't respond
- Verify bot is deployed and healthy
- Check bot configuration in Azure Bot Service
- Review bot endpoint and credentials

## Files Reference

| File | Purpose |
|------|---------|
| css/chat-widget.css | Chat UI styling |
| js/chat-widget.js | Chat logic and initialization |
| index.html | Integrated chat HTML elements |
| ../webchat-integration-sample/server.mjs | Backend token endpoint |
| ../webchat-integration-sample/package.json | Backend dependencies |

## Next Steps

1. Deploy the backend server
2. Update token endpoint URL if necessary
3. Test chat locally
4. Configure bot responses
5. Deploy to production
