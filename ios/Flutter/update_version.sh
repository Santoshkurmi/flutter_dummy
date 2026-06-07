#!/bin/sh

# Paths relative to the script's directory
SRCROOT="$(cd "$(dirname "$0")" && pwd)"
TOML_PATH="$SRCROOT/../../assets/changelog.toml"
CONFIG_PATH="$SRCROOT/Generated.xcconfig"

if [ -f "$TOML_PATH" ] && [ -f "$CONFIG_PATH" ]; then
  max_code=0
  latest_name=""
  current_name=""
  current_code=0

  while IFS= read -r line || [ -n "$line" ]; do
    line=$(echo "$line" | xargs)
    if [ "$line" = "[[versions]]" ]; then
      if [ "$current_code" -gt "$max_code" ]; then
        max_code=$current_code
        latest_name=$current_name
      fi
      current_name=""
      current_code=0
    fi
    if [[ "$line" =~ ^version[[:space:]]*=[[:space:]]*(.*) ]]; then
      val="${BASH_REMATCH[1]}"
      val="${val%,}"
      val="${val#\"}"
      val="${val%\"}"
      val="${val#\'}"
      val="${val%\'}"
      current_name="$val"
    fi
    if [[ "$line" =~ ^versionCode[[:space:]]*=[[:space:]]*(.*) ]]; then
      val="${BASH_REMATCH[1]}"
      val="${val%,}"
      current_code=$((val))
    fi
  done < "$TOML_PATH"

  if [ "$current_code" -gt "$max_code" ]; then
    max_code=$current_code
    latest_name=$current_name
  fi

  if [ "$max_code" -gt 0 ]; then
    echo "FLUTTER_BUILD_NAME=$latest_name" >> "$CONFIG_PATH"
    echo "FLUTTER_BUILD_NUMBER=$max_code" >> "$CONFIG_PATH"
    echo "Successfully updated version to $latest_name ($max_code) inside Generated.xcconfig"
  else
    echo "Error: No valid version found in TOML"
  fi
else
  echo "Error: Required files not found"
fi
