#!/usr/bin/env bats

# Test the validate_url function

setup() {
    load test_helper
    # Source the script to test the validate_url function
    source "$WEBAPP_INSTALLER"
}

@test "validate_url: accepts https:// URL" {
    run validate_url "https://example.com"
    [ "$status" -eq 0 ]
}

@test "validate_url: accepts http:// URL with warning" {
    run --separate-stderr validate_url "http://example.com"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"Warning: using insecure http://"* ]]
}

@test "validate_url: rejects ftp:// URL with error mentioning both schemes" {
    run validate_url "ftp://example.com"
    [ "$status" -ne 0 ]
    [[ "$output" == *"http://"* ]]
    [[ "$output" == *"https://"* ]]
}

@test "validate_url: rejects empty string" {
    run validate_url ""
    [ "$status" -ne 0 ]
}

@test "validate_url: rejects URL without scheme" {
    run validate_url "example.com"
    [ "$status" -ne 0 ]
}

@test "validate_url: accepts bare https:// scheme" {
    run validate_url "https://"
    [ "$status" -eq 0 ]
}
