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

# Temporary file for the new setup.py
TEMP_FILE=$(mktemp)

# Function to get the latest commit hash from a GitHub repo
get_latest_commit() {
  local repo_url="$1"
  # Extract owner and repo name (e.g., https://github.com/rmbrualla/pycolmap -> rmbrualla/pycolmap)
  repo_path=$(echo "$repo_url" | sed -E 's|https://github.com/([^/]+)/([^/]+)(\.git)?$|\1/\2|')
  api_url="https://api.github.com/repos/$repo_path/commits"
  # Try curl with retries (3 attempts, 5s delay)
  for attempt in {1..3}; do
    latest_commit=$(curl -s -f "$api_url" 2>/dev/null | grep '"sha":' | head -n 1 | cut -d '"' -f 4)
    if [ -n "$latest_commit" ]; then
      echo "$latest_commit"
      return 0
    fi
    echo "DEBUG: Failed to fetch commit for $repo_url (attempt $attempt)"
    sleep 5
  done
  echo "DEBUG: Could not fetch latest commit for $repo_url after 3 attempts"
  return 1
}

# Initialize flag
in_install_requires=false

# Read setup.py line by line
while IFS= read -r line || [ -n "$line" ]; do
  # Detect start of install_requires
  if [[ "$line" =~ install_requires[[:space:]]*=.*\[[[:space:]]*$ ]]; then
    echo "DEBUG: Found start of install_requires: $line"
    in_install_requires=true
    echo "$line" >> "$TEMP_FILE"
    continue
  fi

  # Detect end of install_requires
  if [[ "$in_install_requires" == true && "$line" =~ ^[[:space:]]*\][[:space:]]*(,|[[:space:]]*$|[[:space:]]*#.*$) ]]; then
    echo "DEBUG: Found end of install_requires: $line"
    in_install_requires=false
    echo "$line" >> "$TEMP_FILE"
    continue
  fi

  # Process lines within install_requires
  if [ "$in_install_requires" == true ]; then
    echo "DEBUG: Inside install_requires, processing line: $line"
    # Skip empty lines or comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
      echo "DEBUG: Skipping empty or comment line: $line"
      echo "$line" >> "$TEMP_FILE"
      continue
    fi
    # Check if the line contains a Git URL (with or without commit hash)
    if [[ "$line" =~ git\+https://github.com/ ]]; then
      echo "DEBUG: Found Git url: $line"
      # Extract the full dependency string
      full_dep=$(echo "$line" | sed -E 's/^[[:space:]]*"([^"]+)",?/\1/' || echo "")
      if [ -z "$full_dep" ]; then
        echo "DEBUG: Failed to extract full_dep from line: $line"
        echo "$line" >> "$TEMP_FILE"
        continue
      fi
      echo "DEBUG: Full Dependency: $full_dep"
      package_name=$(echo "$full_dep" | cut -d' ' -f1)
      echo "DEBUG: Package: $package_name"
      # Extract Git URL (up to .git or commit hash)
      git_url=$(echo "$full_dep" | sed -nE 's|.*git\+https://github\.com/([^/@]+/[^@.]+).*|https://github.com/\1|p'|| echo "")
      if [ -z "$git_url" ]; then
        echo "DEBUG: Failed to extract git_url from full_dep: $full_dep"
        echo "$line" >> "$TEMP_FILE"
        continue
      fi
      echo "DEBUG: Git URL: $git_url"
      # Extract old commit (if present)
      old_commit=$(echo "$full_dep" | grep -o '[0-9a-f]\{40\}' || echo "")
      echo "DEBUG: Old commit: $old_commit"
      
      echo "DEBUG: Found Git dependency: $package_name, URL: $git_url, Old commit: $old_commit"

      # Get the latest commit
      latest_commit=$(get_latest_commit "$git_url" || echo "")
      if [ -n "$latest_commit" ]; then
        echo "DEBUG: Updating $package_name to latest commit: $latest_commit"
        if [ -n "$old_commit" ]; then
            new_line=$(echo "$line" | sed -E "s|$old_commit|$latest_commit|")
        else
          # If no commit hash, append it
          new_line=$(echo "$line" | sed -E "s|$git_url|$git_url@$latest_commit|")
        fi
        new_line=$(echo "$new_line" | sed -E 's|\.git(@[0-9a-f]{40})?||')

      else
        echo "DEBUG: Failed to update $package_name, keeping original line"
        new_line="$line"
      fi
    #   echo "$new_line" >> "$TEMP_FILE"
    else
      # Non-Git dependency, keep unchanged
      echo "DEBUG: Non-Git dependency: $line"
      echo "$line" >> "$TEMP_FILE"
    fi
  else
    # Lines outside install_requires, keep unchanged
    echo "DEBUG: Outside install_requires: $line"
    echo "$line" >> "$TEMP_FILE"
  fi
done < setup.py

# Replace the original setup.py with the updated one
mv "$TEMP_FILE" setup.py
echo "Updated setup.py with latest Git commit hashes"

# Verify the update
echo "DEBUG: Contents of updated setup.py:"
cat setup.py	