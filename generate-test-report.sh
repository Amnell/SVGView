#!/bin/bash
# Runs all SVG tests, saves rendered PNGs, and generates an HTML comparison report.
# Output goes to test-output/ (gitignored).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/test-output"

# ── 1. Clear and create output directory ──────────────────────────────────────
echo "Clearing $OUTPUT_DIR ..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# ── 2. Run tests ──────────────────────────────────────────────────────────────
echo "Running tests (this may take a while)..."
cd "$SCRIPT_DIR"
swift test --attachments-path "$OUTPUT_DIR" 2>&1 | tee "$OUTPUT_DIR/test-run.log" || true

# ── 3. Generate HTML report ───────────────────────────────────────────────────
echo "Generating report..."

python3 "$SCRIPT_DIR/generate-test-report.py" "$OUTPUT_DIR" "$SCRIPT_DIR"

echo ""
echo "Opening report..."
open "$OUTPUT_DIR/report.html"

