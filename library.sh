#!/bin/bash

# Shellib TOML Library - TOML parsing utilities

# Check if a section exists in TOML file
has_section() {
    local section="$1"
    local file="$2"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Trim trailing whitespace and match section
    grep -q "^\[$section\][ ]*$" "$file" 2>/dev/null
}

# Get a value from a TOML section
get_value() {
    local section="$1"
    local key="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Use awk to parse the TOML section, handling trailing whitespace
    awk -v section="$section" -v key="$key" '
        $0 ~ "^\\[" section "\\][ ]*$" { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && $0 ~ "^" key " = " { 
            gsub(/^[^=]*= *"|"$/, ""); 
            print; 
            exit 
        }
    ' "$file"
}

# Get all key-value pairs from a TOML section
get_section() {
    local section="$1"
    local file="$2"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Use awk to extract all key-value pairs from section
    awk -v section="$section" '
        $0 ~ "^\\[" section "\\][ ]*$" { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && /^[a-zA-Z_][a-zA-Z0-9_]* = / {
            key = $1
            gsub(/^[^=]*= *"|"$/, "")
            print key "|" $0
        }
    ' "$file"
}

# List all sections in a TOML file
list_sections() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Match both quoted and unquoted sections, handle trailing whitespace
    grep "^\[.*\][ ]*$" "$file" | sed 's/^\[\(.*\)\][ ]*$/\1/'
}

# Test functions
test_has_section() {
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << 'EOF'
[default]
method = "fallback"

["github.com"]
method = "https"

["gitlab.example.com/org/repo"]
method = "ssh"
username = "testuser"
EOF
    
    # Test existing sections
    if has_section "default" "$temp_file"; then
        echo "✓ has_section finds default section"
    else
        echo "✗ has_section failed to find default section"
        rm "$temp_file"
        return 1
    fi
    
    if has_section "\"github.com\"" "$temp_file"; then
        echo "✓ has_section finds quoted section"
    else
        echo "✗ has_section failed to find quoted section"
        rm "$temp_file"
        return 1
    fi
    
    # Test non-existing section
    if ! has_section "nonexistent" "$temp_file"; then
        echo "✓ has_section correctly rejects non-existing section"
    else
        echo "✗ has_section incorrectly found non-existing section"
        rm "$temp_file"
        return 1
    fi
    
    rm "$temp_file"
    return 0
}

test_get_value() {
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << 'EOF'
[default]
method = "fallback"

["github.com"]
method = "https"

["gitlab.example.com/org/repo"]
method = "ssh"
username = "testuser"
EOF
    
    # Test getting values
    local method
    method=$(get_value "default" "method" "$temp_file")
    if [ "${method:-}" = "fallback" ]; then
        echo "✓ get_value gets default method"
    else
        echo "✗ get_value failed for default method, got: '$method'"
        rm "$temp_file"
        return 1
    fi
    
    local github_method
    github_method=$(get_value "\"github.com\"" "method" "$temp_file")
    if [ "${github_method:-}" = "https" ]; then
        echo "✓ get_value gets quoted section method"
    else
        echo "✗ get_value failed for quoted section, got: '$github_method'"
        rm "$temp_file"
        return 1
    fi
    
    local username
    username=$(get_value "\"gitlab.example.com/org/repo\"" "username" "$temp_file")
    if [ "${username:-}" = "testuser" ]; then
        echo "✓ get_value gets username"
    else
        echo "✗ get_value failed for username, got: '$username'"
        rm "$temp_file"
        return 1
    fi
    
    # Test non-existing key
    local nonexistent
    nonexistent=$(get_value "default" "nonexistent" "$temp_file")
    if [ -z "${nonexistent:-}" ]; then
        echo "✓ get_value returns empty for non-existing key"
    else
        echo "✗ get_value should return empty for non-existing key, got: '$nonexistent'"
        rm "$temp_file"
        return 1
    fi
    
    rm "$temp_file"
    return 0
}

test_get_section() {
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << 'EOF'
[default]
method = "fallback"

["gitlab.example.com/org/repo"]
method = "ssh"
username = "testuser"
EOF
    
    # Test getting section
    local section_data
    section_data=$(get_section "\"gitlab.example.com/org/repo\"" "$temp_file")
    if echo "${section_data:-}" | grep -q "method|ssh" && echo "${section_data:-}" | grep -q "username|testuser"; then
        echo "✓ get_section gets all key-value pairs"
    else
        echo "✗ get_section failed, got: '$section_data'"
        rm "$temp_file"
        return 1
    fi
    
    rm "$temp_file"
    return 0
}

test_list_sections() {
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << 'EOF'
[default]
method = "fallback"

["github.com"]
method = "https"

["gitlab.example.com/org/repo"]
method = "ssh"
EOF
    
    # Test listing sections
    local sections
    sections=$(list_sections "$temp_file")
    if echo "${sections:-}" | grep -q "default" && echo "${sections:-}" | grep -q "\"github.com\"" && echo "${sections:-}" | grep -q "\"gitlab.example.com/org/repo\""; then
        echo "✓ list_sections lists all sections"
    else
        echo "✗ list_sections failed, got: '$sections'"
        rm "$temp_file"
        return 1
    fi
    
    rm "$temp_file"
    return 0
}

# Run all tests
run_tests() {
    echo "Running tests for toml library..."
    local failed=0
    
    test_has_section || failed=1
    test_get_value || failed=1
    test_get_section || failed=1
    test_list_sections || failed=1
    
    if [ $failed -eq 0 ]; then
        echo "All tests passed!"
        return 0
    else
        echo "Some tests failed!"
        return 1
    fi
}

if [ "${1:-}" = "--test" ] && [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_tests
    exit $?
fi
