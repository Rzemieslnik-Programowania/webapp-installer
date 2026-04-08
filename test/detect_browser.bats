#!/usr/bin/env bats

# Tests for detect_browser and multi-browser fallback detection

setup() {
    load test_helper
    source "$WEBAPP_INSTALLER"
    restore_test_path
}

# --- macOS tests ---

@test "detect_browser: finds Chromium on macOS" {
    mock_uname Darwin
    create_fake_chromium_macos

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
    [[ "$BROWSER_CMD" == *"Chromium.app/Contents/MacOS/Chromium" ]]
}

@test "detect_browser: finds Chrome on macOS when Chromium absent" {
    mock_uname Darwin
    create_fake_chrome_macos

    detect_browser
    [ "$BROWSER_NAME" = "Google Chrome" ]
    [[ "$BROWSER_CMD" == *"Google Chrome.app/Contents/MacOS/Google Chrome" ]]
}

@test "detect_browser: finds Brave on macOS as fallback" {
    mock_uname Darwin
    create_fake_brave_macos

    detect_browser
    [ "$BROWSER_NAME" = "Brave" ]
    [[ "$BROWSER_CMD" == *"Brave Browser.app/Contents/MacOS/Brave Browser" ]]
}

@test "detect_browser: finds Edge on macOS as fallback" {
    mock_uname Darwin
    create_fake_edge_macos

    detect_browser
    [ "$BROWSER_NAME" = "Microsoft Edge" ]
    [[ "$BROWSER_CMD" == *"Microsoft Edge.app/Contents/MacOS/Microsoft Edge" ]]
}

@test "detect_browser: finds Vivaldi on macOS as last resort" {
    mock_uname Darwin
    create_fake_vivaldi_macos

    detect_browser
    [ "$BROWSER_NAME" = "Vivaldi" ]
    [[ "$BROWSER_CMD" == *"Vivaldi.app/Contents/MacOS/Vivaldi" ]]
}

@test "detect_browser: prefers Chromium over Chrome on macOS" {
    mock_uname Darwin
    create_fake_chromium_macos
    create_fake_chrome_macos

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
}

@test "detect_browser: returns failure when no browser on macOS" {
    mock_uname Darwin

    ! detect_browser
}

@test "detect_browser: Chrome path with spaces handled correctly" {
    mock_uname Darwin
    create_fake_chrome_macos

    detect_browser
    [[ "$BROWSER_CMD" == *"Google Chrome"* ]]
}

# --- Linux tests ---

@test "detect_browser: finds chromium on Linux" {
    mock_uname Linux
    create_fake_chromium_linux native

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
    [ "$BROWSER_CMD" = "chromium" ]
}

@test "detect_browser: finds google-chrome on Linux" {
    mock_uname Linux
    create_fake_chrome_linux

    detect_browser
    [ "$BROWSER_NAME" = "Google Chrome" ]
    [ "$BROWSER_CMD" = "google-chrome" ]
}

@test "detect_browser: finds brave-browser on Linux" {
    mock_uname Linux
    create_fake_brave_linux

    detect_browser
    [ "$BROWSER_NAME" = "Brave" ]
    [ "$BROWSER_CMD" = "brave-browser" ]
}

@test "detect_browser: finds microsoft-edge on Linux" {
    mock_uname Linux
    create_fake_edge_linux

    detect_browser
    [ "$BROWSER_NAME" = "Microsoft Edge" ]
    [ "$BROWSER_CMD" = "microsoft-edge" ]
}

@test "detect_browser: finds vivaldi on Linux" {
    mock_uname Linux
    create_fake_vivaldi_linux

    detect_browser
    [ "$BROWSER_NAME" = "Vivaldi" ]
    [ "$BROWSER_CMD" = "vivaldi" ]
}

@test "detect_browser: prefers chromium over chrome on Linux" {
    mock_uname Linux
    create_fake_chromium_linux native
    create_fake_chrome_linux

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
}

@test "detect_browser: returns failure when no browser on Linux" {
    mock_uname Linux

    ! detect_browser
}

# --- Priority tests ---

@test "detect_browser: Chrome chosen before Brave when Chromium absent" {
    mock_uname Linux
    create_fake_chrome_linux
    create_fake_brave_linux

    detect_browser
    [ "$BROWSER_NAME" = "Google Chrome" ]
}

@test "detect_browser: full priority order on Linux" {
    mock_uname Linux
    create_fake_chromium_linux native
    create_fake_chrome_linux
    create_fake_brave_linux
    create_fake_edge_linux
    create_fake_vivaldi_linux

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
}

@test "detect_browser: full priority order on macOS" {
    mock_uname Darwin
    create_fake_chromium_macos
    create_fake_chrome_macos
    create_fake_brave_macos
    create_fake_edge_macos
    create_fake_vivaldi_macos

    detect_browser
    [ "$BROWSER_NAME" = "Chromium" ]
}
