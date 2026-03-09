# Spec for webapp-installer: Cross-Platform Support (macOS + Linux distros)

branch: update-name-extend-usage

## Summary

The `webapp` script currently targets Pop!_OS/GNOME exclusively. This spec covers:
1. Renaming the script and all internal references from `webapp` / `gnome-webapp` to `webapp-installer`
2. Extending support to macOS (using Chromium `--app` mode with a macOS `.app` shim)
3. Supporting additional Linux distributions beyond Debian/Ubuntu (Fedora/DNF, Arch/Pacman, openSUSE/Zypper, and generic paths)

## Functional Requirements

### Renaming
- Rename the script file from `webapp` to `webapp-installer`
- Update all internal messages, usage strings, and comments that reference `webapp` to use `webapp-installer`
- Update `README.md` to reflect the new name, updated install URL, and cross-platform instructions
- Desktop file prefix remains `webapp-` (this is a stable identifier for installed apps, changing it would break existing installs)

### OS / Platform Detection
- Detect the current OS at runtime: macOS (`darwin`), Linux, and emit an unsupported-OS error for anything else
- Detect the desktop environment on Linux (GNOME, KDE Plasma, XFCE, etc.) to decide how to register the app

### Browser Detection (Chromium only)
- Chromium is the only supported browser across all platforms
- On Linux: detect `chromium`, `chromium-browser`, and Flatpak (`org.chromium.Chromium`) / Snap variants
- On macOS: detect Chromium via `/Applications/Chromium.app` or `brew --prefix`-based paths
- Prefer native packages over Flatpak/Snap
- If Chromium is not found, print OS/distro-specific install hints for Chromium

### Linux: Multi-distro Desktop Integration
- Continue using `~/.local/share/applications/*.desktop` (works across GNOME, KDE, XFCE, etc.)
- Replace the hardcoded `update-desktop-database` call with a portable helper that also runs `kbuildsycoca6` (KDE) when detected
- Detect available package manager (apt, dnf, pacman, zypper) for install hints in error messages

### macOS: App Creation
- On macOS, instead of `.desktop` files, create a minimal macOS `.app` bundle under `~/Applications/`
- The `.app` bundle wraps a shell script that calls Chromium with `--app=<url>`
- Icon handling: download the icon as `icon.png` and convert to `.icns` using `sips` (built-in on macOS) or fall back to no custom icon
- Register the app with the system using `touch ~/Applications/<name>.app` so Spotlight indexes it
- `remove` command must delete the `.app` bundle from `~/Applications/`
- `list` command must enumerate `~/Applications/webapp-*.app` on macOS

### Icon Fetching
- No change to current logic (URL → favicon fallback → system icon)
- On macOS, if `sips` is available, convert the downloaded `.png` to `.icns` and place it inside the `.app` bundle

### Error Messages & Help Text
- All user-facing strings must be updated to say `webapp-installer` instead of `webapp`
- Install hints for missing browser must be OS/distro-aware

## Possible Edge Cases

- macOS with no Chromium installed
- Linux with a Wayland compositor that does not use XDG desktop files (e.g., a minimal sway setup without a file manager)
- Flatpak Chromium on a non-GNOME desktop where `flatpak run` works but `update-desktop-database` does not exist
- Existing `webapp-*.desktop` files installed by the old `webapp` script — the new script must continue to manage them (list, remove)
- macOS `.app` bundles with names containing special characters or spaces — slugify must produce a valid path
- Icon download failure on macOS when `sips` is present but `curl` is unavailable (rare but possible)
- KDE Plasma on Arch Linux with both `update-desktop-database` and `kbuildsycoca6` present
- `~/Applications` directory does not exist on macOS (must be created on first use)
- Running the script on an older macOS version where `sips` flags differ

## Acceptance Criteria

- [ ] Script file is renamed to `webapp-installer` and all internal references updated
- [ ] `webapp-installer add` works on macOS (creates `~/Applications/webapp-<slug>.app`, browser opens in `--app` mode)
- [ ] `webapp-installer remove` works on macOS (deletes the `.app` bundle and icon)
- [ ] `webapp-installer list` works on macOS (enumerates `~/Applications/webapp-*.app`)
- [ ] `webapp-installer add` works on Fedora/RHEL (detects `chromium`, provides `dnf` install hint)
- [ ] `webapp-installer add` works on Arch Linux (detects `chromium`, provides `pacman` install hint)
- [ ] `webapp-installer add` works on openSUSE (detects `chromium`, provides `zypper` install hint)
- [ ] KDE Plasma desktop database is refreshed after add/remove on Linux
- [ ] Chromium detected correctly on macOS (native install or Homebrew)
- [ ] Error message for missing browser is OS/distro-specific
- [ ] README updated with new name, new install URL, and macOS + multi-distro instructions
- [ ] Existing `webapp-*.desktop` entries (from old script) remain manageable by the new script

## Open Questions

- Should the macOS `.app` bundle approach use `osascript` / AppleScript for better Dock integration, or is a plain shell-script `.app` sufficient? Use the approach with better Dock integration
- Should there be a `webapp-installer upgrade` or self-update command? yes, add `webapp-installer upgrade`
- Should `.desktop` file prefix `webapp-` be preserved for backward compatibility, or migrated to `webapp-installer-`? use prefix `webapp-`
- On macOS, should the `.app` be placed in `~/Applications` (user) or `/Applications` (system, requires sudo)? `~/Applications`

## Testing Considerations

- Test `detect_chromium` on each target platform with Chromium installed/absent via different methods
- Test `add` command on macOS: verify `.app` bundle structure, icon conversion, Spotlight visibility
- Test `add` command on Fedora, Arch, openSUSE in CI (Docker containers)
- Test `remove` cleans up correctly on macOS (`.app` removed) and Linux (`.desktop` + icon removed)
- Test `list` enumerates correctly when no apps are installed (should print empty message, not error)
- Test icon fallback chain: custom URL → favicon → system default, on both platforms
- Test Chromium detection via Homebrew on macOS
- Test names with spaces and special characters in `slugify`
- Test macOS icon conversion path when `sips` is available vs. absent

## Tech Stack Context

- **Primary framework:** Bash shell script (no framework)
- **Language:** Bash / POSIX sh
- **Relevant tools:** `curl`, `sips` (macOS), `update-desktop-database`, `kbuildsycoca6`, `flatpak`
- **Testing:** bats-core (recommended for Bash testing, not currently set up)
- **Package manager:** N/A (script distributed via `curl` download)

> No tech stack profile found at `.claude/techstack.md`. Run `/init-techstack` to generate one.

## Accessibility Considerations

- N/A — this is a CLI tool with no GUI; ensure error and success messages are clear and unambiguous for screen-reader-friendly terminal usage
- Use distinct exit codes (0 = success, 1 = usage error, 2 = dependency missing) so wrapper scripts and CI can detect failure modes

<details>
<summary>Context Loaded</summary>

**Skills:**
- `tech-stack` — stack-aware development guidance

<!-- context-manifest:{"v":1,"pv":"2.26.0","step":"spec","skills":["tech-stack"],"docs":[],"local":{"skills":[],"agents":[],"commands":[]},"git":{"branch":"update-name-extend-usage"}} -->
</details>
