# gnome-webapp

A simple web app (PWA) manager for Pop!_OS and other GNOME-based distributions. Creates `.desktop` entries that launch websites in Chromium's `--app` mode — no address bar, just like a native application.

Inspired by the approach used in [Omarchy](https://omarchy.org).

## Requirements

- **Chromium** — jako pakiet systemowy lub Flatpak:
  ```bash
  sudo apt install chromium-browser
  # lub
  flatpak install flathub org.chromium.Chromium
  ```
- **curl** (usually pre-installed)
- `~/bin` in `$PATH`

## Installation

```bash
# Create ~/bin if it doesn't exist
mkdir -p ~/bin

# Download the script
curl -o ~/bin/webapp https://raw.githubusercontent.com/YOUR_USERNAME/gnome-webapp/main/webapp

# Make it executable
chmod +x ~/bin/webapp
```

Make sure `~/bin` is in your PATH (usually automatic in Pop!_OS after session restart, or add manually):

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Add a web app

```bash
webapp add "Name" "https://url.com"
```

The icon is fetched automatically from the site's favicon. You can also provide a custom icon URL:

```bash
webapp add "Name" "https://url.com" "https://icon-url.com/icon.png"
```

### High-quality icons

[Dashboard Icons](https://dashboardicons.com) provides clean PNG icons for popular web apps via CDN:

```
https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/{name}.png
```

Examples:

```bash
webapp add "Notion" "https://notion.so" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/notion.png"

webapp add "Linear" "https://linear.app" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/linear.png"

webapp add "Figma" "https://figma.com" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/figma.png"

webapp add "GitHub" "https://github.com" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/github.png"
```

The `icons` command suggests a CDN URL for a given name:

```bash
webapp icons chatgpt
# → https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/chatgpt.png
```

### List installed web apps

```bash
webapp list
```

### Remove a web app

```bash
webapp remove "Notion"
```

Removes both the `.desktop` file and the downloaded icon.

## How it works

The script creates a `.desktop` entry in `~/.local/share/applications/`:

```ini
[Desktop Entry]
Version=1.0
Name=Notion
Exec=chromium --app=https://notion.so
Icon=/home/user/.local/share/applications/icons/notion.png
Type=Application
Categories=Network;WebApplication;
```

The `--app` flag launches Chromium without the address bar — the window looks and behaves like a native app. The `.desktop` entries appear in GNOME Activities just like regular applications.

## File structure

```
~/.local/share/applications/
├── webapp-notion.desktop
├── webapp-linear.desktop
└── icons/
    ├── notion.png
    └── linear.png
```

## License

MIT
# webapp-gnome
