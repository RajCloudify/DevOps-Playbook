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
    local prefix="$3"

    if [ "$depth" -ge "$max_depth" ]; then
        return
    fi

    # List directories first, then files (sorted)
    local dirs=()
    local files=()

    for item in $(ls -1 "$path" 2>/dev/null | sort); do
        # Skip git and node_modules
        if [[ "$item" == ".git" || "$item" == ".github" || "$item" == "node_modules" ]]; then
            continue
        fi

        local full_path="$path/$item"
        if [ -d "$full_path" ]; then
            dirs+=("$item")
        elif [ -f "$full_path" ]; then
            files+=("$item")
        fi
    done

    # Process directories first
    local dir_count=${#dirs[@]}
    for i in "${!dirs[@]}"; do
        local dir="${dirs[$i]}"
        local full_path="$path/$dir"
        local is_last=$([ $i -eq $((dir_count - 1)) ] && [ ${#files[@]} -eq 0 ] && echo true || echo false)

        if [ "$depth" -eq 0 ]; then
            echo "📁 $dir/"
        else
            if [ "$is_last" = true ]; then
                echo "${prefix}└── 📁 $dir/"
            else
                echo "${prefix}├── 📁 $dir/"
            fi
        fi

        # Recurse into subdirectory
        local new_prefix=""
        if [ "$depth" -gt 0 ]; then
            if [ "$is_last" = true ]; then
                new_prefix="${prefix}    "
            else
                new_prefix="${prefix}│   "
            fi
        fi

        generate_tree "$full_path" $((depth + 1)) "$new_prefix"
    done

    # Process files
    local file_count=${#files[@]}
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local is_last_file=$([ $i -eq $((file_count - 1)) ] && echo true || echo false)

        if [ "$depth" -eq 0 ]; then
            echo "📄 $file"
        else
            if [ "$is_last_file" = true ]; then
                echo "${prefix}└── 📄 $file"
            else
                echo "${prefix}├── 📄 $file"
            fi
        fi
    done
}

AUTO_START="<!-- AUTO-GENERATED CONTENT START -->"
AUTO_END="<!-- AUTO-GENERATED CONTENT END -->"

# Generate the Contents section
CONTENTS_SECTION=$(cat <<EOF
$AUTO_START
## 📋 Repository Contents

EOF
)

# Add directory tree
CONTENTS_SECTION+=$'\n'
CONTENTS_SECTION+="$(generate_tree "$REPO_ROOT" 0)"
CONTENTS_SECTION+=$'\n\n'
CONTENTS_SECTION+=$(cat <<EOF
> *This section is synced & automated with the DevOps Playbook.*
$AUTO_END
EOF
)

# Read current README.md
if [ ! -f "$README_PATH" ]; then
    echo "ERROR: README.md not found at $README_PATH"
    exit 1
fi

# Create temporary file
TEMP_FILE=$(mktemp)

# Remove any existing generated Contents sections
awk -v start="$AUTO_START" -v end="$AUTO_END" '
BEGIN { skip=0; section=0 }
{
    if ($0 == start) { skip=1; next }
    if (skip && $0 == end) { skip=0; next }
    if (!skip && $0 ~ /^##.*Repository Contents/) { section=1; next }
    if (!skip && $0 ~ /^##.*Contents/) { section=1; next }
    if (section && $0 ~ /^## /) { section=0; print; next }
    if (section) next
    if (!skip) print
}
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
