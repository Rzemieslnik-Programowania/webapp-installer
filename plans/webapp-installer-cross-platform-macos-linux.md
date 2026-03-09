# Implementation Plan: Cross-Platform Support (macOS + Linux distros)

branch: update-name-extend-usage

---

## Overview

Transform the existing `webapp` script (Pop!_OS/GNOME-only, 183 lines) into `webapp-installer` with cross-platform support for macOS and multiple Linux distributions. The implementation is organized into 8 steps, each producing a testable increment.

---

## Step 0: Set Up bats-core Testing Infrastructure

**Why first:** All subsequent steps will be validated by tests. Setting up the test harness before any code changes enables TDD for the rest of the implementation.

**Files to create:**
- `test/test_helper.bash` — shared setup: export `WEBAPP_INSTALLER` path, create temp `$HOME` directories, mock commands
- `test/slugify.bats` — test the `slugify` function in isolation
- `test/detect_chromium.bats` — placeholder (expanded in Step 3)

**Actions:**
1. Install bats-core as a git submodule or document install instructions in README
2. Create `test/` directory structure:
   ```
   test/
   ├── test_helper.bash
   ├── slugify.bats
   └── detect_chromium.bats
   ```
3. In `test_helper.bash`:
   - Set up a temporary `$HOME` with `$BATS_TMPDIR`
   - Source the script's functions (requires Step 1 refactor to make functions sourceable)
   - Provide helper to create mock commands on `$PATH`
4. Write initial `slugify.bats` tests:
   - Basic lowercasing and space-to-dash
   - Special characters stripped
   - Names with spaces and unicode
5. Verify `bats test/` runs and reports TAP output

**Bash scripting guidance:**
- Use `setup()` and `teardown()` in each `.bats` file for test isolation
- Use `run` helper for capturing exit codes and output
- Use `load test_helper` to share common setup

---

## Step 1: Rename Script and Update Internal References

**File changes:**
- Rename `webapp` → `webapp-installer`
- Edit `webapp-installer`: update all internal strings

**Actions:**
1. `git mv webapp webapp-installer`
2. Update the shebang and header comment:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   # webapp-installer — cross-platform web app (PWA) manager
   ```
3. Update all usage strings, echo messages, and comments that reference `webapp` to `webapp-installer`
4. Keep desktop file prefix as `webapp-` (backward compat per spec)
5. Wrap the script body in a `main()` function to enable sourcing for tests:
   - Move the `case` dispatch into `main "$@"` at the bottom
   - Functions (`slugify`, `detect_chromium`, `fetch_icon`) remain at top level, sourceable independently

**Bash scripting guidance:**
- Add `set -euo pipefail` immediately after shebang
- Declare all function-local variables with `local`
- Use `readonly` for constants (`EX_OK=0`, `EX_USAGE=1`, `EX_DEPENDENCY=2`)

**Error handling:**
- Define exit codes: `0` = success, `1` = usage error, `2` = dependency missing
- Add `die()` helper for stderr error messages with non-zero exit

**Tests:**
- `test/rename.bats`: verify `webapp-installer --help` outputs usage with correct name
- `test/slugify.bats`: already written in Step 0

---

## Step 2: OS and Desktop Environment Detection

**New functions in `webapp-installer`:**
- `detect_os()` — returns `macos`, `linux`, or exits with unsupported error
- `detect_desktop_env()` — returns `gnome`, `kde`, `xfce`, `sway`, `unknown` (Linux only)
- `detect_package_manager()` — returns `apt`, `dnf`, `pacman`, `zypper`, or `unknown`

**Actions:**
1. `detect_os()`:
   ```bash
   case "$(uname -s)" in
     Darwin) echo "macos" ;;
     Linux)  echo "linux" ;;
     *)      die "Unsupported OS: $(uname -s). Only macOS and Linux are supported." ;;
   esac
   ```
2. `detect_desktop_env()`:
   - Check `$XDG_CURRENT_DESKTOP` (colon-delimited, e.g., `ubuntu:GNOME`)
   - Check `$DESKTOP_SESSION` as fallback
   - Detect KDE via `kde`, `KDE`, `plasma` patterns
   - Return `unknown` if undetectable (still works — `.desktop` files are universal)
3. `detect_package_manager()`:
   - Check `command -v apt`, `dnf`, `pacman`, `zypper` in that order
   - Return the first found, or `unknown`

**Bash security guidance:**
- Do not trust `$XDG_CURRENT_DESKTOP` for security decisions — only for UX hints
- Validate `uname -s` output against known values

**Tests:**
- `test/detect_os.bats`: mock `uname` to return `Darwin`, `Linux`, `FreeBSD`
- `test/detect_desktop_env.bats`: set `$XDG_CURRENT_DESKTOP` to various values
- `test/detect_package_manager.bats`: mock `command -v` for each package manager

---

## Step 3: Cross-Platform Chromium Detection

**Refactor `detect_chromium()` to be OS-aware:**

**Actions:**
1. Linux detection (expand existing):
   - Native: `chromium`, `chromium-browser`
   - Snap: check `/snap/bin/chromium`
   - Flatpak: `flatpak list 2>/dev/null | grep -q "org.chromium.Chromium"`
   - Prefer native > Snap > Flatpak
2. macOS detection (new):
   - `/Applications/Chromium.app/Contents/MacOS/Chromium`
   - Homebrew: `"$(brew --prefix 2>/dev/null)/bin/chromium"` if brew is available
   - Homebrew cask: check for the `.app` bundle installed by `brew install --cask chromium`
3. Return the full command path/invocation (e.g., `flatpak run org.chromium.Chromium` for Flatpak)
4. If not found, call `chromium_install_hint()` which uses `detect_os()` + `detect_package_manager()`:
   - apt: `sudo apt install chromium-browser`
   - dnf: `sudo dnf install chromium`
   - pacman: `sudo pacman -S chromium`
   - zypper: `sudo zypper install chromium`
   - macOS: `brew install --cask chromium` or download from chromium.org
   - Generic: "Install Chromium from your distribution's package manager"

**Error handling:**
- Exit with code `2` (dependency missing) when Chromium is not found
- Print install hints to stderr

**Tests:**
- `test/detect_chromium.bats`:
  - Mock `uname` to `Darwin`/`Linux`
  - Create fake binaries on temp `$PATH` to simulate each detection path
  - Test Flatpak detection with mock `flatpak list` output
  - Test install hint output for each distro
  - Test macOS Homebrew path detection

---

## Step 4: Linux Multi-Distro Desktop Integration

**Refactor desktop database refresh to be DE-aware:**

**Actions:**
1. Replace hardcoded `update-desktop-database` with `refresh_desktop_db()`:
   ```bash
   refresh_desktop_db() {
     local apps_dir="$1"
     if command -v update-desktop-database &>/dev/null; then
       update-desktop-database "$apps_dir" 2>/dev/null || true
     fi
     if command -v kbuildsycoca6 &>/dev/null; then
       kbuildsycoca6 2>/dev/null || true
     elif command -v kbuildsycoca5 &>/dev/null; then
       kbuildsycoca5 2>/dev/null || true
     fi
   }
   ```
2. Call `refresh_desktop_db "$APPS_DIR"` in both `add` and `remove` commands
3. Desktop file path remains `~/.local/share/applications/` (universal across GNOME, KDE, XFCE)

**Bash scripting guidance:**
- Use `|| true` after optional commands to prevent `set -e` from exiting
- Use `command -v` not `which` for portability

**Tests:**
- `test/refresh_desktop_db.bats`:
  - Mock `update-desktop-database` and `kbuildsycoca6` to verify both are called when present
  - Verify graceful behavior when neither exists
  - Verify both KDE 5 and 6 paths

---

## Step 5: macOS `.app` Bundle Creation

**New functions:**
- `create_macos_app()` — creates the `.app` bundle structure
- `convert_icon_to_icns()` — converts PNG to ICNS using `sips`
- `macos_add()` — orchestrates macOS `add` command
- `macos_remove()` — removes `.app` bundle
- `macos_list()` — lists installed `.app` bundles

**Actions:**
1. `create_macos_app "$name" "$slug" "$url" "$chromium_cmd" "$icon_path"`:
   ```
   ~/Applications/webapp-<slug>.app/
   ├── Contents/
   │   ├── Info.plist
   │   ├── MacOS/
   │   │   └── webapp-<slug>     (shell script launcher)
   │   └── Resources/
   │       └── icon.icns         (if icon conversion succeeded)
   ```
2. `Info.plist` template:
   - `CFBundleName`: the app name
   - `CFBundleExecutable`: `webapp-<slug>`
   - `CFBundleIconFile`: `icon` (without extension)
   - `CFBundleIdentifier`: `com.webapp-installer.<slug>`
   - `CFBundlePackageType`: `APPL`
3. Launcher script in `MacOS/webapp-<slug>`:
   ```bash
   #!/bin/bash
   exec <chromium_cmd> --app=<url>
   ```
4. Icon conversion:
   - Download PNG using existing `fetch_icon()`
   - Convert: `sips -s format icns "$png_path" --out "$icns_path"` (if `sips` is available)
   - Fall back to no custom icon if `sips` fails or is absent
5. Use `osascript` for better Dock integration (per spec decision):
   - After creating the `.app` bundle, call `touch ~/Applications/webapp-<slug>.app` so Spotlight indexes it
   - Consider adding `LSUIElement` key to Info.plist to prevent the script process from showing in Dock
6. `mkdir -p ~/Applications` on first use
7. `macos_remove "$name"`: `rm -rf ~/Applications/webapp-${slug}.app`
8. `macos_list`: enumerate `~/Applications/webapp-*.app`, extract names from `Info.plist`

**Bash security guidance:**
- Validate the slug contains only `[a-zA-Z0-9-]` before using in file paths
- Quote all paths (names with spaces)
- Use `mktemp` for temporary icon downloads with `trap cleanup EXIT`

**Error handling:**
- If `~/Applications` cannot be created, exit with clear error
- If icon conversion fails, warn but continue (non-fatal)
- If `.app` already exists for same slug, overwrite with notice

**Tests:**
- `test/macos_app.bats`:
  - Mock `uname` to `Darwin`, mock `sips`
  - Verify `.app` bundle directory structure after `add`
  - Verify `Info.plist` contains correct values
  - Verify launcher script content
  - Verify `remove` deletes the bundle
  - Verify `list` enumerates correctly (0 apps, 1 app, multiple apps)
  - Test slug with special characters produces valid path
  - Test icon fallback when `sips` is not available

---

## Step 6: Integrate OS-Aware Command Dispatch

**Refactor the `case "$cmd"` block to dispatch per OS:**

**Actions:**
1. At the top of `main()`, detect the OS:
   ```bash
   OS="$(detect_os)"
   ```
2. Refactor `add` command:
   ```bash
   add)
     # ... validate NAME, URL (shared logic) ...
     CHROMIUM_CMD="$(detect_chromium)"
     # ... fetch icon (shared logic) ...
     case "$OS" in
       linux) linux_add "$NAME" "$SLUG" "$URL" "$CHROMIUM_CMD" "$ICON" ;;
       macos) macos_add "$NAME" "$SLUG" "$URL" "$CHROMIUM_CMD" "$ICON" ;;
     esac
     ;;
   ```
3. Similarly dispatch `remove` and `list` per OS
4. Extract shared validation logic:
   - `validate_add_args "$NAME" "$URL"` — exits with usage error if invalid
   - Icon fetching remains shared (works on both platforms)
5. `icons` command remains unchanged (platform-independent)

**Bash scripting guidance:**
- Keep shared logic in common functions, OS-specific logic in `linux_*` / `macos_*` functions
- All functions use `local` for variables

**Tests:**
- `test/integration.bats`:
  - Full `add` → `list` → `remove` cycle on mocked Linux environment
  - Full `add` → `list` → `remove` cycle on mocked macOS environment
  - Test that `add` with missing name/URL shows correct usage

---

## Step 7: Add `upgrade` (Self-Update) Command

**New command per spec decision:**

**Actions:**
1. Add `upgrade` case to the command dispatch:
   ```bash
   upgrade)
     upgrade_self
     ;;
   ```
2. `upgrade_self()`:
   - Determine the script's own path: `SELF="$(realpath "$0")"`
   - Download the latest version from the GitHub raw URL to a temp file
   - Verify the download succeeded and is non-empty
   - Replace the current script: `mv "$tmp_file" "$SELF" && chmod +x "$SELF"`
   - Print: `"✓ webapp-installer upgraded to latest version"`
3. Use the repo URL: `https://raw.githubusercontent.com/Rzemieslnik-Programowania/webapp-installer/main/webapp-installer`

**Bash security guidance:**
- Download to `mktemp` file first, verify before replacing
- Use `trap` to clean up temp file on failure
- Validate downloaded file is a shell script (check shebang) before replacing
- Use HTTPS only

**Error handling:**
- If `curl` fails, print error and do not replace the script
- If the downloaded file is empty or doesn't start with `#!/`, abort with warning

**Tests:**
- `test/upgrade.bats`:
  - Mock `curl` to return a fake script
  - Verify the old file is replaced
  - Mock `curl` failure, verify original script is preserved
  - Verify empty download is rejected

---

## Step 8: Update README.md

**Actions:**
1. Change title from `gnome-webapp` to `webapp-installer`
2. Update description to mention cross-platform support (macOS + Linux)
3. Update requirements section:
   - macOS: Chromium via Homebrew or direct download
   - Linux: Chromium via apt, dnf, pacman, zypper, or Flatpak
4. Update installation instructions:
   - New download URL pointing to `webapp-installer`
   - macOS-specific notes (e.g., `~/bin` in PATH)
5. Update usage examples to use `webapp-installer` command name
6. Add macOS-specific examples (`.app` bundle creation)
7. Add `upgrade` command documentation
8. Update "How it works" section to describe both `.desktop` (Linux) and `.app` (macOS) approaches
9. Update file structure section to show both platforms

---

## Implementation Order and Dependencies

```
Step 0 (test infra) ─→ Step 1 (rename + refactor) ─→ Step 2 (OS detection)
                                                         │
                                                         ├─→ Step 3 (Chromium detection)
                                                         ├─→ Step 4 (Linux desktop integration)
                                                         └─→ Step 5 (macOS .app bundles)
                                                                │
                                                         Step 6 (OS dispatch) ←──────┘
                                                              │
                                                         Step 7 (upgrade command)
                                                              │
                                                         Step 8 (README)
```

Steps 3, 4, and 5 can be implemented in parallel after Step 2. Step 6 integrates them. Steps 7 and 8 are independent and can be done last.

---

## Cross-Cutting Concerns

### Backward Compatibility
- Desktop file prefix stays `webapp-` — existing installs remain manageable
- `list` and `remove` commands work with existing `webapp-*.desktop` files
- No migration needed for existing users on Linux

### Portability (bash-scripting skill)
- Avoid GNU-only flags: no `sed -i` (differs between GNU/BSD), no `readlink -f` (use `realpath` or `cd && pwd`)
- Use `#!/usr/bin/env bash` shebang
- Use `command -v` instead of `which`
- `mktemp` usage: on macOS, `mktemp` requires a template with `XXXXXX`

### Security (bash-security skill)
- Validate slugs: ensure only `[a-zA-Z0-9-]` before using in file paths
- Quote all variable expansions (prevent word splitting / glob expansion)
- No `eval` anywhere — use arrays for command construction
- `upgrade` command: download to temp file, validate before replacing
- Use `trap cleanup EXIT` for all temp file operations

### Error Handling (error-handling skill)
- Distinct exit codes: `0` success, `1` usage error, `2` dependency missing
- All errors to stderr via `die()` — stdout reserved for data output
- Non-fatal warnings (icon download failure, `sips` unavailable) continue with fallback
- `curl` failures produce actionable error messages

### Testing Strategy (testing-patterns skill)
- Unit tests for pure functions: `slugify`, `detect_os`, `detect_desktop_env`, `detect_package_manager`, `detect_chromium`
- Integration tests for full command flows: `add` → `list` → `remove` on each platform
- Mock external commands via temporary `$PATH` manipulation in bats
- Each `.bats` file uses `setup()` / `teardown()` with temp directories for isolation

---

<details>
<summary>Context Loaded</summary>

**Skills:**
- `tech-stack` — stack-aware development guidance
- `bash-scripting` — safety, patterns, and ShellCheck compliance
- `bash-security` — injection prevention, privileges, and secrets
- `error-handling` — structured error handling and recovery patterns
- `testing-patterns` — practical testing guidance

**Documentation:**
- bats-core via WebSearch — "bats-core bash automated testing system documentation 2025"
- macOS .app bundles via WebSearch — "macOS create .app bundle shell script Chromium --app mode 2025"

<!-- context-manifest:{"v":1,"pv":"2.26.0","step":"plan","skills":["tech-stack","bash-scripting","bash-security","error-handling","testing-patterns"],"docs":[{"name":"bats-core","src":"ws","id":"","q":"bats-core bash automated testing system documentation 2025"},{"name":"macOS .app bundles","src":"ws","id":"","q":"macOS create .app bundle shell script Chromium --app mode 2025"}],"local":{"skills":[],"agents":[],"commands":[]},"git":{"branch":"update-name-extend-usage"}} -->
</details>
