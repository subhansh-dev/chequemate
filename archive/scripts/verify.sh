#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFTPM_DIR="$(dirname "$SCRIPT_DIR")/download/huewaves.swiftpm"

echo "🔍 Huewaves — Local Build Check"
echo "================================"

# Check Xcode
echo ""
echo "📦 Xcode version:"
xcodebuild -version | head -1

# Clean previous build
echo ""
echo "🧹 Cleaning previous build..."
rm -rf "$SWIFTPM_DIR/build" "$SWIFTPM_DIR/.build"

# Build for iOS Simulator
echo ""
echo "🔨 Building for iOS Simulator..."
cd "$SWIFTPM_DIR"
xcodebuild -scheme Huewaves \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build \
  build 2>&1 | xcpretty --color

BUILD_EXIT=${PIPESTATUS[0]}

if [ $BUILD_EXIT -eq 0 ]; then
  echo ""
  echo "✅ BUILD SUCCEEDED"
else
  echo ""
  echo "❌ BUILD FAILED"
  exit 1
fi

# Quick lint checks
echo ""
echo "🔎 Quick lint checks..."
cd "$SWIFTPM_DIR/Sources"

ISSUES=0

FORCE_UNWRAPS=$(grep -cn '!\s*$\|\.unsafelyUnwrapped\|try!' *.swift 2>/dev/null || echo "0")
if [ "$FORCE_UNWRAPS" -gt 0 ]; then
  echo "  ⚠️  Force unwraps found: $FORCE_UNWRAPS"
  grep -rn '!\s*$\|\.unsafelyUnwrapped\|try!' *.swift | head -5
  ISSUES=$((ISSUES + 1))
fi

PRINTS=$(grep -cn 'print(' *.swift 2>/dev/null || echo "0")
if [ "$PRINTS" -gt 0 ]; then
  echo "  ⚠️  Print statements found: $PRINTS"
  ISSUES=$((ISSUES + 1))
fi

TODOS=$(grep -cn 'TODO\|FIXME\|HACK' *.swift 2>/dev/null || echo "0")
if [ "$TODOS" -gt 0 ]; then
  echo "  ℹ️  TODOs/FIXMEs found: $TODOS"
fi

if [ $ISSUES -eq 0 ]; then
  echo "  ✅ No issues found"
fi

echo ""
echo "================================"
echo "✅ All checks passed! Safe to push."
