# webapp-installer

A cross-platform web app (PWA) manager for macOS and Linux distributions. Creates native application entries that launch websites in Chromium's `--app` mode — no address bar, just like a native application.

**macOS:** Creates `.app` bundles in `~/Applications/`
**Linux:** Creates `.desktop` entries in `~/.local/share/applications/` (works with GNOME, KDE, XFCE, and other desktop environments)

Inspired by the approach used in [Omarchy](https://omarchy.org).

## Requirements

### macOS
- **Chromium**: Install via Homebrew or direct download
  ```bash
  brew install --cask chromium
  # or download from https://www.chromium.org/getting-involved/download-chromium
  ```
- **curl** (usually pre-installed)

### Linux
- **Chromium**: Install via your distribution's package manager:
  ```bash
  # Debian/Ubuntu
  sudo apt install chromium-browser

  # Fedora/RHEL
  sudo dnf install chromium

  # Arch
  sudo pacman -S chromium

  # openSUSE
  sudo zypper install chromium

  # Or via Flatpak (all distributions)
  flatpak install flathub org.chromium.Chromium
  ```
- **curl** (usually pre-installed)

### Both
- `~/bin` in `$PATH` (for easy access to the script)

## Installation

```bash
# Create ~/bin if it doesn't exist
mkdir -p ~/bin

# Download the script
curl -o ~/bin/webapp-installer https://raw.githubusercontent.com/Rzemieslnik-Programowania/webapp-installer/main/webapp-installer

# Make it executable
chmod +x ~/bin/webapp-installer
```

Ensure `~/bin` is in your PATH:

```bash
# Bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

or

```bash
# Zsh
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

### Add a web app

```bash
webapp-installer add "Name" "https://url.com"
```

The icon is fetched automatically from the site's favicon. You can provide a custom icon URL:

```bash
webapp-installer add "Name" "https://url.com" "https://icon-url.com/icon.png"
```

### High-quality icons

[Dashboard Icons](https://dashboardicons.com) provides clean PNG icons for popular web apps via CDN:

```
https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/{name}.png
```

Examples:

```bash
webapp-installer add "Notion" "https://notion.so" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/notion.png"

webapp-installer add "Linear" "https://linear.app" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/linear.png"

webapp-installer add "Figma" "https://figma.com" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/figma.png"

webapp-installer add "GitHub" "https://github.com" \
  "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/github.png"
```

The `icons` command suggests a CDN URL:

```bash
webapp-installer icons chatgpt
# → https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/chatgpt.png
```

### List installed web apps

```bash
webapp-installer list
```

### Remove a web app

```bash
webapp-installer remove "Notion"
```

**macOS:** Deletes the `.app` bundle from `~/Applications/`
**Linux:** Removes the `.desktop` file and downloaded icon

### Upgrade to the latest version

```bash
webapp-installer upgrade
```

## How it works

### macOS
Creates a `.app` bundle in `~/Applications/`:
- `Contents/MacOS/` — shell script launcher that calls Chromium with `--app=<url>`
- `Contents/Info.plist` — app metadata for Spotlight, Dock, and System Preferences
- `Contents/Resources/icon.icns` — app icon (if provided and `sips` is available)

The app appears in Spotlight, the Dock, Finder, and Launchpad like any native application.

### Linux
Creates a `.desktop` entry in `~/.local/share/applications/`:

```ini
[Desktop Entry]
Version=1.0
Name=Notion
Exec=chromium --app=https://notion.so
Icon=/home/user/.local/share/applications/icons/notion.png
Type=Application
Categories=Network;WebApplication;
```

The `--app` flag launches Chromium without the address bar — the window looks and behaves like a native app. The `.desktop` entries appear in your application menu (Activities in GNOME, Applications in KDE, etc.).

## File structure

**macOS:**
```
~/Applications/
├── webapp-notion.app/
│   └── Contents/
│       ├── MacOS/webapp-notion
│       ├── Info.plist
│       └── Resources/icon.icns
└── webapp-linear.app/
    └── ...
```

**Linux:**
```
~/.local/share/applications/
├── webapp-notion.desktop
├── webapp-linear.desktop
└── icons/
    ├── notion.png
    └── linear.png
```

## Testing

This project uses [bats-core](https://github.com/bats-core/bats-core) for testing. To run tests:

```bash
./test/bats/bin/bats test/*.bats
```

## License

MIT
