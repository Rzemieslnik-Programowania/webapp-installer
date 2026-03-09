#!/usr/bin/env bats

# Test the slugify function

setup() {
    load test_helper
    # Source the script to test the slugify function
    source "$WEBAPP_INSTALLER"
}

@test "slugify: lowercases uppercase letters" {
    run slugify "MyApp"
    [ "$status" -eq 0 ]
    [ "$output" = "myapp" ]
}

@test "slugify: converts spaces to dashes" {
    run slugify "My Application"
    [ "$status" -eq 0 ]
    [ "$output" = "my-application" ]
}

@test "slugify: removes special characters" {
    run slugify "My@App#Name"
    [ "$status" -eq 0 ]
    [ "$output" = "myappname" ]
}

@test "slugify: handles mixed case and spaces" {
    run slugify "Hello World App"
    [ "$status" -eq 0 ]
    [ "$output" = "hello-world-app" ]
}

@test "slugify: preserves dashes" {
    run slugify "my-app"
    [ "$status" -eq 0 ]
    [ "$output" = "my-app" ]
}

@test "slugify: handles unicode characters (strips them)" {
    run slugify "Über App"
    [ "$status" -eq 0 ]
    # tr -cd removes non-alphanumeric chars, so ü becomes empty
    [[ "$output" =~ ^[a-z0-9-]+$ ]]  # output should contain only alphanumeric and dashes
}

@test "slugify: handles empty string" {
    run slugify ""
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "slugify: handles string with only dashes and numbers" {
    run slugify "app-123"
    [ "$status" -eq 0 ]
    [ "$output" = "app-123" ]
}
