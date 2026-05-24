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

python3 - "$OUTPUT_DIR" << 'PYTHON_EOF'
import os
import re
import sys
import glob

output_dir = sys.argv[1]

# ── Collect test entries ──────────────────────────────────────────────────────
# Each rendered PNG gives us one test entry.
rendered_pngs = sorted(glob.glob(os.path.join(output_dir, "*-rendered.png")))

tests = []
for png_path in rendered_pngs:
    png_name   = os.path.basename(png_path)          # e.g. color-prop-01-b-rendered.png
    test_name  = png_name[:-len("-rendered.png")]    # e.g. color-prop-01-b

    # Derive group from the first two dash-separated words, e.g. "color-prop"
    parts = test_name.split("-")
    group = "-".join(parts[:2]) if len(parts) >= 2 else test_name

    # Determine pass/fail by comparing actual vs expected serialisation
    actual_path   = os.path.join(output_dir, f"{test_name}-actual.txt")
    expected_path = os.path.join(output_dir, f"{test_name}-expected.txt")
    passed = False
    if os.path.exists(actual_path) and os.path.exists(expected_path):
        with open(actual_path)   as f: actual   = f.read()
        with open(expected_path) as f: expected = f.read()
        passed = (actual == expected)

    # The SVG source is also saved as an attachment
    svg_filename = f"{test_name}.svg"
    svg_path     = os.path.join(output_dir, svg_filename)
    has_svg      = os.path.exists(svg_path)

    tests.append({
        "name":         test_name,
        "group":        group,
        "png":          png_name,
        "svg":          svg_filename if has_svg else None,
        "passed":       passed,
        "has_actual":   os.path.exists(actual_path),
    })

total  = len(tests)
passed = sum(1 for t in tests if t["passed"])
failed = total - passed

# ── Group for TOC ─────────────────────────────────────────────────────────────
from collections import defaultdict
groups = defaultdict(list)
for t in tests:
    groups[t["group"]].append(t)

# ── Build HTML ────────────────────────────────────────────────────────────────
def test_cards(test_list):
    cards = []
    for t in test_list:
        status_cls  = "pass" if t["passed"] else "fail"
        status_icon = "✅" if t["passed"] else "❌"

        svg_col = ""
        if t["svg"]:
            svg_col = f'<div class="col"><div class="col-label">Source SVG</div><img src="{t["svg"]}" alt="source svg" loading="lazy"></div>'
        else:
            svg_col = '<div class="col"><div class="col-label">Source SVG</div><span class="missing">not available</span></div>'

        png_col = f'<div class="col"><div class="col-label">Rendered PNG</div><img src="{t["png"]}" alt="rendered png" loading="lazy"></div>'

        cards.append(f'''
  <div class="card {status_cls}" id="{t["name"]}">
    <div class="card-header">
      <span class="icon">{status_icon}</span>
      <a class="card-name" href="#{t["name"]}">{t["name"]}</a>
    </div>
    <div class="card-body">
      {svg_col}
      {png_col}
    </div>
  </div>''')
    return "\n".join(cards)

group_sections = []
for group_name, group_tests in sorted(groups.items()):
    gpass = sum(1 for t in group_tests if t["passed"])
    gtotal = len(group_tests)
    group_sections.append(f'''
<section class="group" id="group-{group_name}">
  <h2><a href="#group-{group_name}">{group_name}</a> <span class="badge">{gpass}/{gtotal}</span></h2>
  {test_cards(group_tests)}
</section>''')

toc_items = "".join(
    f'<li><a href="#group-{g}">{g} ({sum(1 for t in ts if t["passed"])}/{len(ts)})</a></li>'
    for g, ts in sorted(groups.items())
)

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SVGView Test Report</title>
  <style>
    *, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #f5f5f7;
      color: #1d1d1f;
      line-height: 1.5;
    }}
    header {{
      background: #1d1d1f;
      color: #f5f5f7;
      padding: 1.5rem 2rem;
      position: sticky; top: 0; z-index: 100;
      display: flex; align-items: center; gap: 2rem; flex-wrap: wrap;
    }}
    header h1 {{ font-size: 1.25rem; font-weight: 700; flex: 1; }}
    .stats {{ font-size: 0.95rem; white-space: nowrap; }}
    .stats .pass-count {{ color: #34c759; font-weight: 600; }}
    .stats .fail-count {{ color: #ff3b30; font-weight: 600; }}
    .filter-bar {{ display: flex; gap: 0.5rem; flex-wrap: wrap; }}
    .filter-bar button {{
      padding: 0.3rem 0.75rem; border-radius: 999px; border: none;
      cursor: pointer; font-size: 0.85rem; background: #3a3a3c; color: #f5f5f7;
      transition: background 0.15s;
    }}
    .filter-bar button.active {{ background: #0071e3; }}
    #search {{
      padding: 0.3rem 0.75rem; border-radius: 999px; border: none;
      font-size: 0.85rem; width: 200px; background: #3a3a3c; color: #f5f5f7;
    }}
    #search::placeholder {{ color: #8e8e93; }}
    main {{ display: flex; gap: 0; }}
    nav {{
      width: 220px; flex-shrink: 0;
      background: #fff; border-right: 1px solid #e5e5ea;
      height: calc(100vh - 60px); overflow-y: auto;
      position: sticky; top: 60px;
      padding: 1rem 0;
    }}
    nav h3 {{ font-size: 0.75rem; font-weight: 600; color: #8e8e93;
              text-transform: uppercase; letter-spacing: 0.06em;
              padding: 0 1rem 0.5rem; }}
    nav ul {{ list-style: none; }}
    nav a {{
      display: block; padding: 0.3rem 1rem;
      text-decoration: none; color: #1d1d1f; font-size: 0.85rem;
    }}
    nav a:hover {{ background: #f5f5f7; }}
    .content {{ flex: 1; padding: 1.5rem 2rem; overflow: hidden; }}
    .group {{ margin-bottom: 2.5rem; }}
    .group > h2 {{
      font-size: 1rem; font-weight: 700; margin-bottom: 1rem;
      padding-bottom: 0.4rem; border-bottom: 2px solid #e5e5ea;
      display: flex; align-items: center; gap: 0.5rem;
    }}
    .group > h2 a {{ color: inherit; text-decoration: none; }}
    .group > h2 a:hover {{ text-decoration: underline; }}
    .badge {{
      font-size: 0.75rem; font-weight: 600; background: #e5e5ea;
      padding: 0.1rem 0.5rem; border-radius: 999px;
    }}
    .card {{
      background: #fff;
      border-radius: 12px;
      border: 1px solid #e5e5ea;
      margin-bottom: 1rem;
      overflow: hidden;
    }}
    .card.fail {{ border-left: 4px solid #ff3b30; }}
    .card.pass {{ border-left: 4px solid #34c759; }}
    .card-header {{
      padding: 0.6rem 1rem;
      display: flex; align-items: center; gap: 0.5rem;
      background: #fafafa; border-bottom: 1px solid #e5e5ea;
    }}
    .icon {{ font-size: 1rem; }}
    .card-name {{
      font-weight: 600; font-size: 0.9rem; font-family: "SF Mono", monospace;
      color: #1d1d1f; text-decoration: none;
    }}
    .card-name:hover {{ text-decoration: underline; }}
    .card-body {{
      display: flex; gap: 0; overflow: hidden;
    }}
    .col {{
      flex: 1; padding: 1rem;
      display: flex; flex-direction: column; gap: 0.5rem;
      min-width: 0;
    }}
    .col + .col {{ border-left: 1px solid #e5e5ea; }}
    .col-label {{
      font-size: 0.75rem; font-weight: 600; color: #8e8e93;
      text-transform: uppercase; letter-spacing: 0.06em;
    }}
    .col img {{
      max-width: 100%; height: auto; max-height: 300px;
      object-fit: contain; background: repeating-conic-gradient(#e0e0e0 0% 25%, #fff 0% 50%) 0 0 / 12px 12px;
      border-radius: 6px;
      display: block;
    }}
    .missing {{ color: #8e8e93; font-size: 0.85rem; font-style: italic; }}
    .hidden {{ display: none !important; }}
  </style>
</head>
<body>
<header>
  <h1>SVGView Test Report</h1>
  <div class="stats">
    <span class="pass-count">{passed} passed</span> &nbsp;/&nbsp;
    <span class="fail-count">{failed} failed</span>
    &nbsp;&nbsp;({total} total)
  </div>
  <div class="filter-bar">
    <button data-filter="all"   class="active">All</button>
    <button data-filter="pass"           >Passing</button>
    <button data-filter="fail"           >Failing</button>
    <input id="search" type="search" placeholder="Filter by name…" spellcheck="false">
  </div>
</header>
<main>
  <nav>
    <h3>Groups</h3>
    <ul>{toc_items}</ul>
  </nav>
  <div class="content">
    {"".join(group_sections)}
  </div>
</main>
<script>
  const cards   = Array.from(document.querySelectorAll('.card'));
  const sections = Array.from(document.querySelectorAll('.group'));
  let activeFilter = 'all';
  let searchTerm   = '';

  function applyFilters() {{
    cards.forEach(card => {{
      const matchFilter = activeFilter === 'all' || card.classList.contains(activeFilter);
      const matchSearch = !searchTerm || card.id.includes(searchTerm);
      card.classList.toggle('hidden', !(matchFilter && matchSearch));
    }});
    sections.forEach(section => {{
      const visible = section.querySelectorAll('.card:not(.hidden)').length > 0;
      section.classList.toggle('hidden', !visible);
    }});
  }}

  document.querySelectorAll('[data-filter]').forEach(btn => {{
    btn.addEventListener('click', () => {{
      document.querySelectorAll('[data-filter]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeFilter = btn.dataset.filter;
      applyFilters();
    }});
  }});

  document.getElementById('search').addEventListener('input', e => {{
    searchTerm = e.target.value.trim().toLowerCase();
    applyFilters();
  }});
</script>
</body>
</html>"""

report_path = os.path.join(output_dir, "report.html")
with open(report_path, "w") as f:
    f.write(html)

print(f"Report written: {report_path}")
print(f"  {passed}/{total} tests passing")
PYTHON_EOF

echo ""
echo "Done. Opening report..."
open "$OUTPUT_DIR/report.html"
