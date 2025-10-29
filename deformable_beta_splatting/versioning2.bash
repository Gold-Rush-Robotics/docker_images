#!/bin/bash

# Exit on any error
set -e

# Check if setup.py exists
if [ ! -f "setup.py" ]; then
  echo "Error: setup.py not found in current directory"
  exit 1
fi

# Check if required tools are installed
command -v grep >/dev/null 2>&1 || { echo "Error: grep is required"; exit 1; }
command -v sed >/dev/null 2>&1 || { echo "Error: sed is required"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required"; exit 1; }

REQUIREMENTS_FILE="requirements.txt"
> "$REQUIREMENTS_FILE"  # Clear or create the file

# Function to get the latest commit hash from a GitHub repo
get_latest_commit() {
  local repo_url="$1"
  repo_path=$(echo "$repo_url" | sed -E 's|https://github.com/([^/]+)/([^/]+)(\.git)?$|\1/\2|')
  api_url="https://api.github.com/repos/$repo_path/commits"
  for attempt in {1..3}; do
    latest_commit=$(curl -s -f "$api_url" 2>/dev/null | grep '"sha":' | head -n 1 | cut -d '"' -f 4)
    if [ -n "$latest_commit" ]; then
      echo "$latest_commit"
      return 0
    fi
    sleep 5
  done
  return 1
}

# Initialize flag
in_install_requires=false

while IFS= read -r line || [ -n "$line" ]; do
  if [[ "$line" =~ install_requires[[:space:]]*=.*\[[[:space:]]*$ ]]; then
    in_install_requires=true
    continue
  fi

  if [[ "$in_install_requires" == true && "$line" =~ ^[[:space:]]*\][[:space:]]*(,|[[:space:]]*$|#.*)$ ]]; then
    in_install_requires=false
    continue
  fi

  if [ "$in_install_requires" == true ]; then
    if [[ "$line" =~ git\+https://github.com/ ]]; then
      full_dep=$(echo "$line" | sed -E 's/^[[:space:]]*"([^"]+)",?/\1/')
      package_name=$(echo "$full_dep" | cut -d' ' -f1)
      git_url=$(echo "$full_dep" | sed -nE 's|.*git\+(https://github\.com/[^@]+/[^@.]+).*|\1|p')
      old_commit=$(echo "$full_dep" | grep -o '[0-9a-f]\{40\}' || echo "")

    #   latest_commit=$(get_latest_commit "$git_url" || echo "")
      if [ -n "$git_url" ]; then
    #     dep_line="${package_name} @ git+${git_url}@${latest_commit}"

    #     echo "$dep_line" >> "$REQUIREMENTS_FILE"
        echo "Updated: $dep_line"
      else
        echo "Warning: Could not fetch latest commit for $package_name, using original line"
        echo "$full_dep" >> "$REQUIREMENTS_FILE"
      fi
    fi
  fi
done < setup.py

echo "✅ requirements.txt written with Git dependencies using latest commit hashes."
