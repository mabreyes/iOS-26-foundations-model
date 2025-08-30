#!/usr/bin/env bash
set -euo pipefail

# Ensure we have swiftlint
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "SwiftLint not installed; skipping SwiftLint hook."
  exit 0
fi

# Ensure Xcode is installed and DEVELOPER_DIR points to a full Xcode, not CommandLineTools
need_xcode=true
if [[ -n "${DEVELOPER_DIR:-}" ]]; then
  if [[ -d "$DEVELOPER_DIR/Platforms/iPhoneOS.platform" ]]; then
    need_xcode=false
  fi
fi

if $need_xcode; then
  # Try to find Xcode via Spotlight
  if command -v mdfind >/dev/null 2>&1; then
    xcode_app_path=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" | head -n 1 || true)
    if [[ -n "${xcode_app_path:-}" ]] && [[ -d "$xcode_app_path/Contents/Developer" ]]; then
      export DEVELOPER_DIR="$xcode_app_path/Contents/Developer"
      need_xcode=false
    fi
  fi
fi

if $need_xcode; then
  echo "Xcode not found or DEVELOPER_DIR not set to a full Xcode; skipping SwiftLint."
  echo "Install Xcode and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 0
fi

# Run SwiftLint and do not block commits initially; flip to enforce later
if swiftlint --strict; then
  exit 0
else
  echo "SwiftLint found violations. Not blocking commit (advisory mode)."
  # To enforce, change this script to `exec swiftlint --strict`
  exit 0
fi
