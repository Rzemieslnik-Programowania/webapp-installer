#!/usr/bin/env bash
# Shared test helper for webapp-installer tests
# Provides utilities for mocking commands and setting up isolated test environments

# Path to the script under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export WEBAPP_INSTALLER="$SCRIPT_DIR/webapp-installer"

# Fresh temporary directories for each test (cleaned on every load)
export TEST_HOME="${BATS_TMPDIR}/home"
rm -rf "$TEST_HOME"
mkdir -p "$TEST_HOME"/.local/share/applications
mkdir -p "$TEST_HOME"/Applications  # for macOS testing
export HOME="$TEST_HOME"

# Override system-level Applications directory for test isolation
export MACOS_SYSTEM_APPS="${BATS_TMPDIR}/system-apps"
rm -rf "$MACOS_SYSTEM_APPS"
mkdir -p "$MACOS_SYSTEM_APPS"

# Add test utilities to PATH (for mocking commands)
TEST_BIN="${BATS_TMPDIR}/test-bin"
rm -rf "$TEST_BIN"
mkdir -p "$TEST_BIN"
export PATH="$TEST_BIN:$PATH"

# Helper to create a mock command
mock_command() {
    local name="$1"
    local output="$2"
    local exit_code="${3:-0}"

    cat > "$TEST_BIN/$name" <<EOF
#!/usr/bin/env bash
echo "$output"
exit $exit_code
EOF
    chmod +x "$TEST_BIN/$name"
}

# Helper to record command calls
call_log_init() {
    CALL_LOG="${BATS_TMPDIR}/call_log"
    > "$CALL_LOG"
    export CALL_LOG
}

record_call() {
    echo "$@" >> "$CALL_LOG"
}

call_log_content() {
    cat "$CALL_LOG" 2>/dev/null || true
}

# Helper to mock uname for OS detection
mock_uname() {
    local os="$1"  # 'Darwin' or 'Linux'

    cat > "$TEST_BIN/uname" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-s" ]]; then
    echo "$os"
else
    /bin/uname "\$@"
fi
EOF
    chmod +x "$TEST_BIN/uname"
}

# Helper to create fake Chromium installations
create_fake_chromium_linux() {
    local variant="${1:-native}"  # native, flatpak, snap

    case "$variant" in
        native)
            mkdir -p "$TEST_BIN"
            cat > "$TEST_BIN/chromium" <<'EOF'
#!/usr/bin/env bash
exec echo "chromium-mock" "$@"
EOF
            chmod +x "$TEST_BIN/chromium"
            ;;
        snap)
            mkdir -p "$TEST_BIN"
            cat > "$TEST_BIN/snap" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "list" ]]; then
    echo "Name                      Version  Rev   Tracking       Publisher   Notes"
    echo "chromium                  latest   1234  stable         Canonical   classic"
fi
EOF
            chmod +x "$TEST_BIN/snap"
            ;;
        flatpak)
            mkdir -p "$TEST_BIN"
            cat > "$TEST_BIN/flatpak" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "list" ]]; then
    echo "Ref                                   Branch Op Remote  Options"
    echo "app/org.chromium.Chromium/x86_64/stable --     i flathub --system"
fi
EOF
            chmod +x "$TEST_BIN/flatpak"
            ;;
    esac
}

# Helper to create fake macOS Chromium installation
create_fake_chromium_macos() {
    mkdir -p "$TEST_HOME/Applications/Chromium.app/Contents/MacOS"
    cat > "$TEST_HOME/Applications/Chromium.app/Contents/MacOS/Chromium" <<'EOF'
#!/usr/bin/env bash
echo "macos-chromium-mock" "$@"
EOF
    chmod +x "$TEST_HOME/Applications/Chromium.app/Contents/MacOS/Chromium"
}

# Helper to create fake macOS Chrome installation
create_fake_chrome_macos() {
    mkdir -p "$TEST_HOME/Applications/Google Chrome.app/Contents/MacOS"
    cat > "$TEST_HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" <<'EOF'
#!/usr/bin/env bash
echo "macos-chrome-mock" "$@"
EOF
    chmod +x "$TEST_HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
}

# Helper to create fake macOS Brave installation
create_fake_brave_macos() {
    mkdir -p "$TEST_HOME/Applications/Brave Browser.app/Contents/MacOS"
    cat > "$TEST_HOME/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" <<'EOF'
#!/usr/bin/env bash
echo "macos-brave-mock" "$@"
EOF
    chmod +x "$TEST_HOME/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
}

# Helper to create fake macOS Edge installation
create_fake_edge_macos() {
    mkdir -p "$TEST_HOME/Applications/Microsoft Edge.app/Contents/MacOS"
    cat > "$TEST_HOME/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" <<'EOF'
#!/usr/bin/env bash
echo "macos-edge-mock" "$@"
EOF
    chmod +x "$TEST_HOME/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
}

# Helper to create fake macOS Vivaldi installation
create_fake_vivaldi_macos() {
    mkdir -p "$TEST_HOME/Applications/Vivaldi.app/Contents/MacOS"
    cat > "$TEST_HOME/Applications/Vivaldi.app/Contents/MacOS/Vivaldi" <<'EOF'
#!/usr/bin/env bash
echo "macos-vivaldi-mock" "$@"
EOF
    chmod +x "$TEST_HOME/Applications/Vivaldi.app/Contents/MacOS/Vivaldi"
}

# Helper to create fake Linux Chrome installation
create_fake_chrome_linux() {
    mkdir -p "$TEST_BIN"
    cat > "$TEST_BIN/google-chrome" <<'EOF'
#!/usr/bin/env bash
echo "google-chrome-mock" "$@"
EOF
    chmod +x "$TEST_BIN/google-chrome"
}

# Helper to create fake Linux Brave installation
create_fake_brave_linux() {
    mkdir -p "$TEST_BIN"
    cat > "$TEST_BIN/brave-browser" <<'EOF'
#!/usr/bin/env bash
echo "brave-browser-mock" "$@"
EOF
    chmod +x "$TEST_BIN/brave-browser"
}

# Helper to create fake Linux Edge installation
create_fake_edge_linux() {
    mkdir -p "$TEST_BIN"
    cat > "$TEST_BIN/microsoft-edge" <<'EOF'
#!/usr/bin/env bash
echo "microsoft-edge-mock" "$@"
EOF
    chmod +x "$TEST_BIN/microsoft-edge"
}

# Helper to create fake Linux Vivaldi installation
create_fake_vivaldi_linux() {
    mkdir -p "$TEST_BIN"
    cat > "$TEST_BIN/vivaldi" <<'EOF'
#!/usr/bin/env bash
echo "vivaldi-mock" "$@"
EOF
    chmod +x "$TEST_BIN/vivaldi"
}

# Re-inject TEST_BIN into PATH after the script's hardcoded PATH override
restore_test_path() {
    export PATH="$TEST_BIN:$PATH"
}
