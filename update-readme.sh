#!/bin/bash
# Script to automatically update README.md Contents section
# This script scans the directory structure and generates a Contents section

README_PATH="${1:-.}/README.md"

# Get the repository root
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT" || exit 1

# Function to generate directory tree
generate_tree() {
    local path="$1"
    local depth="${2:-0}"
    local max_depth=3
    
    if [ "$depth" -ge "$max_depth" ]; then
        return
    fi
    
    local indent=""
    for ((i = 0; i < depth; i++)); do
        indent+="  "
    done
    
    # List directories first, then files (sorted)
    for item in $(ls -1 "$path" 2>/dev/null | sort); do
        # Skip git and node_modules
        if [[ "$item" == ".git" || "$item" == ".github" || "$item" == "node_modules" ]]; then
            continue
        fi
        
        local full_path="$path/$item"
        
        if [ -d "$full_path" ]; then
            echo "${indent}- **${item}/**"
            generate_tree "$full_path" $((depth + 1))
        elif [ -f "$full_path" ]; then
            echo "${indent}- $item"
        fi
    done
}

# Generate the Contents section
CONTENTS_SECTION=$(cat <<'EOF'
## Contents

EOF
)

# Add directory tree
CONTENTS_SECTION+=$'\n'
CONTENTS_SECTION+="$(generate_tree "$REPO_ROOT" 0)"
CONTENTS_SECTION+=$'\n'
CONTENTS_SECTION+=$(cat <<'EOF'
This section is auto-generated. Do not edit manually.
EOF
)

# Read current README.md
if [ ! -f "$README_PATH" ]; then
    echo "ERROR: README.md not found at $README_PATH"
    exit 1
fi

# Create temporary file
TEMP_FILE=$(mktemp)

# Extract content before Contents section
awk '
BEGIN { found = 0 }
/^## Contents/ { found = 1; exit }
{ print }
' "$README_PATH" > "$TEMP_FILE"

# Remove trailing blank lines
sed -i -e :a -e '/^\s*$/d;N;ba' "$TEMP_FILE" 2>/dev/null || sed -i '' -e :a -e '/^\s*$/d;N;ba' "$TEMP_FILE"

# Append new Contents section
echo "" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "$CONTENTS_SECTION" >> "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$README_PATH"

echo "[OK] README.md Contents section updated successfully!"
