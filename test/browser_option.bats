#!/usr/bin/env bats

# Tests for the --browser option in the add command

setup() {
    load test_helper
    source "$WEBAPP_INSTALLER"
    restore_test_path
}

# --- Browser selection override tests ---

@test "--browser chrome selects Chrome even when Chromium is present (macOS)" {
    mock_uname Darwin
    create_fake_chromium_macos
    create_fake_chrome_macos

    resolve_browser "chrome" "macos"
    [ "$BROWSER_NAME" = "Google Chrome" ]
    [[ "$BROWSER_CMD" == *"Google Chrome"* ]]
}

@test "--browser chrome selects Chrome even when Chromium is present (Linux)" {
    mock_uname Linux
    create_fake_chromium_linux native
    create_fake_chrome_linux

    resolve_browser "chrome" "linux"
    [ "$BROWSER_NAME" = "Google Chrome" ]
    [ "$BROWSER_CMD" = "google-chrome" ]
}

@test "--browser brave selects Brave (macOS)" {
    mock_uname Darwin
    create_fake_chromium_macos
    create_fake_brave_macos

    resolve_browser "brave" "macos"
    [ "$BROWSER_NAME" = "Brave" ]
    [[ "$BROWSER_CMD" == *"Brave Browser"* ]]
}

@test "--browser vivaldi selects Vivaldi (Linux)" {
    mock_uname Linux
    create_fake_chromium_linux native
    create_fake_vivaldi_linux

    resolve_browser "vivaldi" "linux"
    [ "$BROWSER_NAME" = "Vivaldi" ]
    [ "$BROWSER_CMD" = "vivaldi" ]
}

@test "--browser edge selects Edge (macOS)" {
    mock_uname Darwin
    create_fake_chromium_macos
    create_fake_edge_macos

    resolve_browser "edge" "macos"
    [ "$BROWSER_NAME" = "Microsoft Edge" ]
    [[ "$BROWSER_CMD" == *"Microsoft Edge"* ]]
}

@test "--browser chromium selects Chromium (Linux)" {
    mock_uname Linux
    create_fake_chromium_linux native
    create_fake_chrome_linux

    resolve_browser "chromium" "linux"
    [ "$BROWSER_NAME" = "Chromium" ]
    [ "$BROWSER_CMD" = "chromium" ]
}

# --- Case-insensitivity tests ---

@test "--browser CHROME works (uppercase)" {
    mock_uname Linux
    create_fake_chrome_linux

    resolve_browser "CHROME" "linux"
    [ "$BROWSER_NAME" = "Google Chrome" ]
}

@test "--browser Chrome works (mixed case)" {
    mock_uname Linux
    create_fake_chrome_linux

    resolve_browser "Chrome" "linux"
    [ "$BROWSER_NAME" = "Google Chrome" ]
}

@test "--browser BRAVE works (uppercase)" {
    mock_uname Darwin
    create_fake_brave_macos

    resolve_browser "BRAVE" "macos"
    [ "$BROWSER_NAME" = "Brave" ]
}

# --- Error cases ---

@test "--browser firefox errors with valid browser list" {
    run resolve_browser "firefox" "linux"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown browser"* ]]
    [[ "$output" == *"chromium, chrome, brave, edge, vivaldi"* ]]
}

@test "--browser without value errors with usage hint" {
    mock_uname Linux
    create_fake_chrome_linux

    # Mock curl to prevent real network calls
    curl() { return 1; }
    export -f curl

    run main add --browser
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"--browser"* ]]
}

@test "--browser chrome when Chrome not installed errors with install hint" {
    mock_uname Linux
    # No chrome installed

    run resolve_browser "chrome" "linux"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Browser not found: chrome"* ]]
    [[ "$output" == *"Install it first"* ]]
}

@test "unknown option --foo errors with usage hint" {
    mock_uname Linux
    create_fake_chrome_linux

    # Mock curl to prevent real network calls
    curl() { return 1; }
    export -f curl

    run main add --foo "Test" "https://example.com"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

# --- Auto-detection regression tests ---

@test "add without --browser auto-detects as before" {
    mock_uname Linux
    create_fake_chromium_linux native
    create_fake_chrome_linux

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
}

# --- Output distinction tests ---

@test "user-selected browser output says (user-selected)" {
    mock_uname Linux
    create_fake_chrome_linux

    # Mock curl to prevent real network calls during add
    curl() {
        # Return failure for icon fetch
        echo "000"
        return 0
    }
    export -f curl

    # Mock update-desktop-database
    mock_command update-desktop-database "" 0

    run main add --browser chrome "TestApp" "https://example.com"
    [ "$status" -eq 0 ]
    [[ "$output" == *"(user-selected)"* ]]
}

@test "auto-detected fallback output says (Chromium not found)" {
    mock_uname Linux
    create_fake_chrome_linux

    # Mock curl to prevent real network calls during add
    curl() {
        echo "000"
        return 0
    }
    export -f curl

    # Mock update-desktop-database
    mock_command update-desktop-database "" 0

    run main add "TestApp" "https://example.com"
    [ "$status" -eq 0 ]
    [[ "$output" == *"(Chromium not found)"* ]]
}

# --- Generated launcher/desktop file tests ---

@test "--browser brave: Linux .desktop file contains correct Exec line" {
    mock_uname Linux
    create_fake_brave_linux

    # Mock curl to return a fake icon
    curl() {
        if [[ "$*" == *"-o"* ]]; then
            # Find the output file path (after -o flag)
            local args=("$@")
            for i in "${!args[@]}"; do
                if [[ "${args[$i]}" == "-o" ]]; then
                    echo "fake-icon-data" > "${args[$((i+1))]}"
                    echo "200"
                    return 0
                fi
            done
        fi
        echo "000"
        return 0
    }
    export -f curl

    # Mock update-desktop-database
    mock_command update-desktop-database "" 0

    run main add --browser brave "TestApp" "https://example.com"
    [ "$status" -eq 0 ]

    local desktop_file="$HOME/.local/share/applications/webapp-testapp.desktop"
    [ -f "$desktop_file" ]
    grep -q 'Exec=brave-browser --app="https://example.com"' "$desktop_file"
}

@test "--browser chrome: Linux .desktop file contains correct Exec line" {
    mock_uname Linux
    create_fake_chrome_linux

    curl() {
        if [[ "$*" == *"-o"* ]]; then
            local args=("$@")
            for i in "${!args[@]}"; do
                if [[ "${args[$i]}" == "-o" ]]; then
                    echo "fake-icon-data" > "${args[$((i+1))]}"
                    echo "200"
                    return 0
                fi
            done
        fi
        echo "000"
        return 0
    }
    export -f curl

    mock_command update-desktop-database "" 0

    run main add --browser chrome "TestApp" "https://example.com"
    [ "$status" -eq 0 ]

    local desktop_file="$HOME/.local/share/applications/webapp-testapp.desktop"
    [ -f "$desktop_file" ]
    grep -q 'Exec=google-chrome --app="https://example.com"' "$desktop_file"
}

@test "--browser brave: macOS launcher script contains correct browser command" {
    mock_uname Darwin
    create_fake_brave_macos

    curl() {
        if [[ "$*" == *"-o"* ]]; then
            local args=("$@")
            for i in "${!args[@]}"; do
                if [[ "${args[$i]}" == "-o" ]]; then
                    echo "fake-icon-data" > "${args[$((i+1))]}"
                    echo "200"
                    return 0
                fi
            done
        fi
        echo "000"
        return 0
    }
    export -f curl

    # Mock sips (macOS icon conversion)
    mock_command sips "" 0

    run main add --browser brave "TestApp" "https://example.com"
    [ "$status" -eq 0 ]

    local launcher="$HOME/Applications/webapp-testapp.app/Contents/MacOS/webapp-testapp"
    [ -f "$launcher" ]
    # printf %q escapes spaces, so check for Brave and Browser separately
    grep -q "Brave" "$launcher"
    grep -q "app=https://example.com" "$launcher"
}

# --- Double-dash separator test ---

@test "-- terminates option parsing" {
    mock_uname Linux
    create_fake_chromium_linux native

    curl() {
        if [[ "$*" == *"-o"* ]]; then
            local args=("$@")
            for i in "${!args[@]}"; do
                if [[ "${args[$i]}" == "-o" ]]; then
                    echo "fake-icon-data" > "${args[$((i+1))]}"
                    echo "200"
                    return 0
                fi
            done
        fi
        echo "000"
        return 0
    }
    export -f curl

    mock_command update-desktop-database "" 0

    # After --, positional args are treated as-is (auto-detection used)
    run main add -- "TestApp" "https://example.com"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Browser: Chromium"* ]]
}
