# AutomateVerse LLC — Generative AI Services Website

Professional, responsive static website for **AutomateVerse LLC**, a Generative AI consulting and solutions company. Hosted on GitHub Pages at [automateversellc.com](https://automateversellc.com).

## Overview

A single-page website built with pure HTML, CSS, and JavaScript — no frameworks, no build tools. Designed to communicate AutomateVerse's Gen AI service offerings with a premium, modern aesthetic.

## Sections

| Section | Description |
|---------|-------------|
| **Hero** | Bold value proposition with animated background |
| **About** | Mission, vision, and expertise |
| **Services** | Six core Gen AI service offerings |
| **Process** | Four-step engagement methodology |
| **Industries** | Six target verticals |
| **Why Us** | Three key differentiators |
| **Contact** | Email, GitHub, and location |

## Features

- Elegant dark/light section design with glassmorphism cards
- Animated hero with floating gradient glows and grid overlay
- Scroll-triggered staggered animations (Intersection Observer)
- Active navigation tracking on scroll
- Fully responsive (mobile-first breakpoints at 480px, 768px, 1024px)
- SEO-optimized with structured data (JSON-LD)
- Zero external dependencies — pure HTML, CSS, JS

## Project Structure

```
├── index.html          # All sections and content
├── css/
│   └── styles.css      # Design system and responsive layout
├── js/
│   └── script.js       # Animations, nav, and interactions
├── CNAME               # Custom domain (automateversellc.com)
└── README.md
```

## Local Development

```bash
# Clone
git clone https://github.com/jpad5/automateverse.git
cd automateverse

# Serve locally (Python 3)
python -m http.server 8000
# Open http://localhost:8000
```

Or use the VS Code task: **Live Server** (runs `python -m http.server 8000`).

## Deployment

The site deploys automatically to GitHub Pages from the `main` branch. Custom domain is configured via the `CNAME` file.

## Technologies

- **HTML5** — Semantic markup with structured data
- **CSS3** — Custom properties, grid, flexbox, animations, glassmorphism
- **JavaScript** — Vanilla ES6+, Intersection Observer API
- **Fonts** — Inter + Space Grotesk (Google Fonts)

## License

MIT License — see [LICENSE](LICENSE) for details.

---

&copy; 2026 AutomateVerse LLC. All rights reserved.