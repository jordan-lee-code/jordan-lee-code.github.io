#!/bin/bash
# Builds the site and generates assets/Jordan-Lee-CV.pdf from the rendered CV page.
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="$REPO_DIR/_site/assets/cv.html"
OUTPUT="$REPO_DIR/assets/Jordan-Lee-CV.pdf"

CHROMIUM=$(which chromium || which chromium-browser || which google-chrome || echo "")
if [[ -z "$CHROMIUM" ]]; then
  echo "Error: chromium not found. Install with: sudo apt-get install chromium" >&2
  exit 1
fi

echo "Building site..."
cd "$REPO_DIR" && bundle exec jekyll build --quiet

"$CHROMIUM" \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --print-to-pdf="$OUTPUT" \
  --print-to-pdf-no-header \
  "file://$INPUT" 2>/dev/null

echo "CV generated: $OUTPUT"
