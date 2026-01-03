# TOML Library for Shellib

A bash library providing TOML file parsing utilities for configuration management.

## Usage

```bash
# Load the library using grab
if [ ! -f "$HOME/bin/grab" ]; then
  mkdir -p $HOME/bin
  export PATH=$PATH:$HOME/bin
  curl -o $HOME/bin/grab -L https://github.com/shellib/grab/raw/master/grab.sh && chmod +x $HOME/bin/grab
fi

source $(grab github.com/shellib/toml as toml)
```

## Functions

### Section Operations
- `toml::has_section(section, file)` - Check if section exists
- `toml::list_sections(file)` - List all sections in file

### Value Operations  
- `toml::get_value(section, key, file)` - Get value for key in section
- `toml::get_section(section, file)` - Get all key-value pairs from section

## Examples

Given a TOML file `config.toml`:
```toml
[default]
method = "fallback"

["github.com"]
method = "ssh"
username = "myuser"

["gitlab.example.com/org/repo"]
method = "https"
```

### Basic Usage
```bash
# Check if section exists
if toml::has_section "default" "config.toml"; then
    echo "Default section found"
fi

# Get a value
method=$(toml::get_value "default" "method" "config.toml")
echo "Method: $method"  # Output: Method: fallback

# Get value from quoted section
username=$(toml::get_value '"github.com"' "username" "config.toml")
echo "Username: $username"  # Output: Username: myuser

# List all sections
toml::list_sections "config.toml"
# Output:
# default
# "github.com"
# "gitlab.example.com/org/repo"

# Get all key-value pairs from a section
toml::get_section '"github.com"' "config.toml"
# Output:
# method|ssh
# username|myuser
```

### Working with Quoted Sections
For sections with special characters (like URLs), use quotes:
```bash
# Correct
toml::get_value '"github.com"' "method" "config.toml"
toml::get_value '"gitlab.example.com/org/repo"' "method" "config.toml"
```

## Testing

```bash
./library.sh --test
```

## Features

- Supports both quoted and unquoted section names
- Handles trailing whitespace in TOML files
- Robust parsing using awk for cross-platform compatibility
- Comprehensive test suite included