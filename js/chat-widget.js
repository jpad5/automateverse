const launcher = document.getElementById('chat-launcher');
const panel = document.getElementById('chat-panel');
const closeButton = document.getElementById('chat-close');
const restartButton = document.getElementById('chat-restart');
const statusEl = document.getElementById('chat-status');
const webchatHost = document.getElementById('webchat');
const promptButtons = Array.from(document.querySelectorAll('[data-prompt]'));

let directLine;
let initialized = false;
let pendingPrompt = null;

// Configure the token endpoint URL
// For GitHub Pages deployment, point to the backend server
const tokenEndpoint = process.env.WEBCHAT_TOKEN_ENDPOINT || '/api/webchat/token';

launcher.addEventListener('click', async () => {
  togglePanel(true);

  if (!initialized) {
    await initializeChat();
  }
});

closeButton.addEventListener('click', () => {
  togglePanel(false);
});

restartButton.addEventListener('click', async () => {
  await initializeChat(true);
});

promptButtons.forEach((button) => {
  button.addEventListener('click', async () => {
    pendingPrompt = button.dataset.prompt;
    togglePanel(true);

    if (!initialized) {
      await initializeChat();
      return;
    }

    postPrompt(pendingPrompt);
    pendingPrompt = null;
  });
});

async function initializeChat(forceRestart = false) {
  if (forceRestart) {
    initialized = false;
    webchatHost.replaceChildren();
  }

  setStatus('Connecting to AutomateVerse assistant...');

  try {
    const response = await fetch(tokenEndpoint, {
      method: 'POST'
    });

    if (!response.ok) {
      setStatus('Unable to start chat right now. Check the token service configuration.');
      return;
    }

    const { token, domain } = await response.json();
    directLine = window.WebChat.createDirectLine({
      token,
      ...(domain ? { domain } : {})
    });

    const store = window.WebChat.createStore({}, ({ dispatch }) => (next) => (action) => {
      if (action.type === 'DIRECT_LINE/CONNECT_FULFILLED') {
        dispatch({
          type: 'WEB_CHAT/SEND_EVENT',
          payload: {
            name: 'pageContext',
            type: 'event',
            value: {
              path: window.location.pathname,
              title: document.title,
              referrer: document.referrer || null
            }
          }
        });

        if (pendingPrompt) {
          postPrompt(pendingPrompt);
          pendingPrompt = null;
        }

        setStatus('Connected. Ask about services, delivery approach, industries, or contact details.');
      }

      return next(action);
    });

    const styleOptions = {
      accent: '#0f766e',
      backgroundColor: '#fffdf8',
      bubbleBackground: '#f2ede2',
      bubbleBorderRadius: 18,
      bubbleFromUserBackground: '#d6efe8',
      bubbleFromUserBorderRadius: 18,
      botAvatarInitials: 'AV',
      userAvatarInitials: 'You',
      hideUploadButton: true,
      primaryFont: "'Inter', 'Segoe UI', sans-serif",
      sendBoxBackground: '#fffaf0',
      sendBoxButtonColor: '#0f766e',
      sendBoxButtonColorOnHover: '#0a4f4a',
      subtleColor: '#4d6263'
    };

    window.WebChat.renderWebChat(
      {
        directLine,
        store,
        locale: 'en-US',
        styleOptions
      },
      webchatHost
    );

    initialized = true;
  } catch (error) {
    console.error('Failed to initialize chat:', error);
    setStatus('Unable to start chat. Please try again later.');
  }
}

function postPrompt(text) {
  directLine.postActivity({
    type: 'message',
    from: { id: 'website-visitor', name: 'Website Visitor' },
    text
  }).subscribe({
    error: () => {
      setStatus('The initial question could not be sent. Please try again.');
    }
  });
}

function togglePanel(open) {
  panel.hidden = !open;
  launcher.setAttribute('aria-expanded', String(open));
}

function setStatus(message) {
  statusEl.textContent = message;
}
