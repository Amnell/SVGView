#!/usr/bin/env python3
"""Generate an HTML test report from SVGView test output.

Usage: python3 generate-test-report.py <output_dir> <project_dir>

  output_dir   — directory written by `swift test --attachments-path`
  project_dir  — project root containing w3c-coverage.md
"""
import os
import re
import sys
from collections import defaultdict, OrderedDict

output_dir  = sys.argv[1]
project_dir = sys.argv[2]

# ── Parse w3c-coverage.md ──────────────────────────────────────────────────────
# Builds: standards = OrderedDict of (std_label, version_dir) ->
#           OrderedDict of suite_name -> [(passing:bool, test_name), ...]
coverage_path = os.path.join(project_dir, "w3c-coverage.md")
with open(coverage_path) as f:
    cov_lines = f.readlines()

standards    = OrderedDict()   # (label, dir) -> OrderedDict(suite -> [(bool, name)])
current_std  = None            # (label, dir) tuple
current_suite = None

for line in cov_lines:
    s = line.strip()
    # Top-level standard: ## [SVG 1.1 ...] or ## [SVG Tiny 1.2]
    m = re.match(r'^## \[?(SVG [^\]\n]+?)\]?(?:\(.*?\))?\s*$', s)
    if m:
        title = m.group(1).strip()
        current_std = ('SVG 1.1', '1.1F2') if '1.1' in title else ('SVG Tiny 1.2', '1.2T')
        standards[current_std] = OrderedDict()
        current_suite = None
        continue
    # Suite header: ### ... [SuiteName](...)
    m = re.match(r'^###.*?\[(\w+)\]', s)
    if m and current_std:
        current_suite = m.group(1)
        standards[current_std][current_suite] = []
        continue
    # Test row: |✅| or |❌|
    m = re.match(r'^\|([✅❌])\|\[([^\]]+)\]\(', s)
    if m and current_std and current_suite:
        standards[current_std][current_suite].append((m.group(1) == '✅', m.group(2)))

# ── Build attachment lookup ────────────────────────────────────────────────────
att = defaultdict(dict)   # test_name -> {png, actual, expected, diff, svg_copy}
for fname in sorted(os.listdir(output_dir)):
    for suffix, key in [('-rendered.png', 'png'), ('-actual.txt', 'actual'),
                        ('-expected.txt', 'expected'), ('-diff.txt', 'diff')]:
        if fname.endswith(suffix):
            att[fname[:-len(suffix)]][key] = fname
    if fname.endswith('.svg'):
        att[fname[:-4]]['svg_copy'] = fname

def run_status(test_name):
    """Return 'pass', 'fail', or 'unimplemented' based on attachments."""
    a = att.get(test_name, {})
    if 'png' not in a:
        return 'unimplemented'
    ap = os.path.join(output_dir, a.get('actual', ''))
    ep = os.path.join(output_dir, a.get('expected', ''))
    if os.path.exists(ap) and os.path.exists(ep):
        with open(ap) as f: actual   = f.read()
        with open(ep) as f: expected = f.read()
        return 'pass' if actual == expected else 'fail'
    return 'fail'

def svg_src(test_name, version_dir):
    """Relative path from test-output/ to the original source SVG."""
    return f"../Tests/SVGViewTests/w3c/{version_dir}/svg/{test_name}.svg"

def w3c_ref_url(test_name):
    return f"https://www.w3.org/Graphics/SVG/Test/20110816/harness/htmlEmbed/{test_name}.html"

# ── Aggregate stats ────────────────────────────────────────────────────────────
total_pass = total_fail = total_unimpl = 0
for (_, vdir), suites in standards.items():
    for suite, tests in suites.items():
        for _, name in tests:
            s = run_status(name)
            if   s == 'pass':   total_pass  += 1
            elif s == 'fail':   total_fail  += 1
            else:               total_unimpl += 1
total = total_pass + total_fail + total_unimpl

# ── Card HTML ─────────────────────────────────────────────────────────────────
STATUS_ICON  = {'pass': '✅', 'fail': '❌', 'unimplemented': '🔲'}
STATUS_LABEL = {'pass': 'pass', 'fail': 'fail', 'unimplemented': 'unimplemented'}

def img(src, cls='', alt=''):
    return f'<img src="{src}" class="thumb {cls}" alt="{alt}" loading="lazy">'

def card_html(test_name, status, version_dir):
    a       = att.get(test_name, {})
    src_svg = svg_src(test_name, version_dir)
    ref_url = w3c_ref_url(test_name)

    rendered_col = ''
    if 'png' in a:
        rendered_col = f'''<div class="col">
          <div class="col-label">Rendered</div>
          {img(a["png"], alt="rendered")}
        </div>'''

    source_col = f'''<div class="col">
      <div class="col-label">Source SVG</div>
      {img(src_svg, alt="source svg")}
    </div>'''

    ref_col = f'''<div class="col">
      <div class="col-label">W3C Reference</div>
      <a href="{ref_url}" target="_blank" rel="noopener">{img(ref_url, alt="W3C reference")}</a>
    </div>'''

    diff_col = ''
    if status == 'fail' and 'diff' in a:
        diff_path = os.path.join(output_dir, a['diff'])
        try:
            with open(diff_path) as f:
                diff_text = f.read(4000)
            diff_col = f'''<div class="col diff-col">
              <div class="col-label">Diff</div>
              <pre class="diff">{diff_text[:3000]}</pre>
            </div>'''
        except Exception:
            pass

    return f'''<div class="card {status} open" id="{test_name}">
  <div class="card-header" data-w3c-url="{w3c_ref_url(test_name)}">
    <span class="icon">{STATUS_ICON[status]}</span>
    <span class="card-name">{test_name}</span>
    <span class="card-badge {status}">{STATUS_LABEL[status]}</span>
    <span class="expand-icon">▾</span>
  </div>
  <div class="card-body">{rendered_col}{source_col}{ref_col}{diff_col}</div>
</div>'''

# ── Build Standard > Suite sections + sidebar TOC ─────────────────────────────
std_sections_html = []
toc_html = ''

for (std_label, vdir), suites in standards.items():
    std_id = std_label.replace(' ', '-').lower()
    suite_sections = []
    toc_suites = []

    for suite, tests in suites.items():
        suite_id = f"{std_id}-{suite.lower()}"
        s_pass = s_fail = s_unimpl = 0
        cards = []
        for _, name in tests:
            s = run_status(name)
            if   s == 'pass':   s_pass  += 1
            elif s == 'fail':   s_fail  += 1
            else:               s_unimpl += 1
            cards.append(card_html(name, s, vdir))

        s_total  = s_pass + s_fail + s_unimpl
        badge_cls = ('suite-all-pass' if s_fail == 0 and s_unimpl == 0 else
                     'suite-has-pass' if s_pass > 0 else 'suite-none')

        suite_sections.append(f'''
<section class="suite" id="{suite_id}">
  <h3 class="suite-header">
    <a href="#{suite_id}">{suite}</a>
    <span class="suite-stats">
      <span class="s-pass">{s_pass}✅</span>
      <span class="s-fail">{s_fail}❌</span>
      <span class="s-unimpl">{s_unimpl}🔲</span>
      <span class="s-total">/ {s_total}</span>
    </span>
  </h3>
  <div class="cards">{"".join(cards)}</div>
</section>''')

        toc_suites.append(
            f'<li><a href="#{suite_id}" class="{badge_cls}">'
            f'{suite} <span class="toc-nums">{s_pass}/{s_total}</span></a></li>'
        )

    std_sections_html.append(f'''
<section class="standard" id="{std_id}">
  <h2 class="standard-header"><a href="#{std_id}">{std_label}</a></h2>
  {"".join(suite_sections)}
</section>''')

    toc_html += f'''<li class="toc-std"><a href="#{std_id}">{std_label}</a>
  <ul>{"".join(toc_suites)}</ul>
</li>'''

# ── Full HTML document ─────────────────────────────────────────────────────────
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
      background: #f5f5f7; color: #1d1d1f; line-height: 1.5;
    }}
    header {{
      background: #1d1d1f; color: #f5f5f7;
      padding: 0.9rem 1.5rem;
      position: sticky; top: 0; z-index: 100;
      display: flex; align-items: center; gap: 1.5rem; flex-wrap: wrap;
    }}
    header h1 {{ font-size: 1.1rem; font-weight: 700; flex: 1; }}
    .stats {{ font-size: 0.85rem; display: flex; gap: 0.75rem; }}
    .stat {{ display: flex; flex-direction: column; align-items: center; }}
    .stat-num {{ font-size: 1.1rem; font-weight: 700; }}
    .stat-num.pass   {{ color: #34c759; }}
    .stat-num.fail   {{ color: #ff3b30; }}
    .stat-num.unimpl {{ color: #8e8e93; }}
    .stat-label {{ font-size: 0.65rem; color: #8e8e93; text-transform: uppercase; letter-spacing: .05em; }}
    .filter-bar {{ display: flex; gap: 0.4rem; align-items: center; flex-wrap: wrap; }}
    .filter-bar button {{
      padding: 0.25rem 0.65rem; border-radius: 999px; border: none;
      cursor: pointer; font-size: 0.8rem; background: #3a3a3c; color: #f5f5f7;
    }}
    .filter-bar button.active {{ background: #0071e3; }}
    #search {{
      padding: 0.25rem 0.65rem; border-radius: 999px; border: none;
      font-size: 0.8rem; width: 180px; background: #3a3a3c; color: #f5f5f7;
    }}
    #search::placeholder {{ color: #6e6e73; }}
    main {{ display: flex; }}
    nav {{
      width: 210px; flex-shrink: 0; background: #fff;
      border-right: 1px solid #e5e5ea;
      height: calc(100vh - 52px); overflow-y: auto;
      position: sticky; top: 52px;
      padding: 0.75rem 0; font-size: 0.8rem;
    }}
    nav ul {{ list-style: none; }}
    nav li.toc-std {{ margin-top: 0.5rem; }}
    nav li.toc-std > a {{
      display: block; padding: 0.2rem 0.75rem;
      font-weight: 700; text-decoration: none;
      font-size: 0.75rem; text-transform: uppercase;
      letter-spacing: .05em; color: #6e6e73;
    }}
    nav li.toc-std > ul {{ padding-left: 0.5rem; }}
    nav a {{
      display: flex; justify-content: space-between;
      padding: 0.18rem 0.75rem;
      text-decoration: none; color: #1d1d1f;
    }}
    nav a:hover {{ background: #f5f5f7; }}
    nav a.suite-all-pass .toc-nums {{ color: #34c759; }}
    nav a.suite-has-pass .toc-nums {{ color: #ff9f0a; }}
    nav a.suite-none     .toc-nums {{ color: #8e8e93; }}
    .toc-nums {{ font-size: 0.75rem; color: #8e8e93; }}
    .content {{ flex: 1; padding: 1.25rem 1.5rem; min-width: 0; }}
    .standard {{ margin-bottom: 2rem; }}
    .standard-header {{
      font-size: 1.15rem; font-weight: 700;
      padding: 0.6rem 0; margin-bottom: 0.75rem;
      border-bottom: 3px solid #1d1d1f;
    }}
    .standard-header a {{ color: inherit; text-decoration: none; }}
    .suite {{ margin-bottom: 1.5rem; }}
    .suite-header {{
      font-size: 0.95rem; font-weight: 600;
      display: flex; align-items: center; gap: 0.6rem;
      padding: 0.4rem 0; margin-bottom: 0.5rem;
      border-bottom: 1px solid #e5e5ea;
    }}
    .suite-header a {{ color: inherit; text-decoration: none; }}
    .suite-header a:hover {{ text-decoration: underline; }}
    .suite-stats {{ display: flex; gap: 0.4rem; font-size: 0.8rem; margin-left: auto; }}
    .s-pass  {{ color: #34c759; }}
    .s-fail  {{ color: #ff3b30; }}
    .s-unimpl {{ color: #8e8e93; }}
    .s-total  {{ color: #8e8e93; }}
    .cards {{ display: flex; flex-direction: column; gap: 0.4rem; }}
    .card {{
      background: #fff; border-radius: 10px;
      border: 1px solid #e5e5ea; overflow: hidden;
    }}
    .card.pass          {{ border-left: 4px solid #34c759; }}
    .card.fail          {{ border-left: 4px solid #ff3b30; }}
    .card.unimplemented {{ border-left: 4px solid #c7c7cc; }}
    .card-header {{
      padding: 0.45rem 0.9rem;
      display: flex; align-items: center; gap: 0.5rem;
      background: #fafafa; border-bottom: 1px solid transparent;
      cursor: pointer; user-select: none;
    }}
    .card.open .card-header {{ border-bottom-color: #f0f0f0; }}
    .icon {{ font-size: 0.85rem; }}
    .card-name {{
      font-weight: 600; font-size: 0.85rem;
      font-family: "SF Mono", ui-monospace, monospace;
      color: #1d1d1f; flex: 1;
    }}
    .card-badge {{
      font-size: 0.7rem; font-weight: 600;
      padding: 0.1rem 0.45rem; border-radius: 999px;
    }}
    .card-badge.pass          {{ background: #d1f5d3; color: #1a7a2e; }}
    .card-badge.fail          {{ background: #ffd5d3; color: #9b1c1c; }}
    .card-badge.unimplemented {{ background: #efefef; color: #6e6e73; }}
    .card-header:hover {{ background: #f0f0f0; }}
    .expand-icon {{ font-size: 0.75rem; color: #8e8e93; margin-left: 0.25rem; transition: transform 0.15s; padding: 0.25rem; }}
    .card.open .expand-icon {{ transform: rotate(180deg); }}
    .card-body {{
      display: flex; overflow: hidden;
      max-height: 0; transition: max-height 0.2s ease;
    }}
    .card.open .card-body {{ max-height: 600px; }}
    .col {{
      flex: 1; padding: 0.75rem;
      display: flex; flex-direction: column; gap: 0.4rem; min-width: 0;
    }}
    .col + .col {{ border-left: 1px solid #f0f0f0; }}
    .col-label {{
      font-size: 0.65rem; font-weight: 700; color: #8e8e93;
      text-transform: uppercase; letter-spacing: 0.06em;
    }}
    .thumb {{
      max-width: 100%; height: auto; max-height: 220px;
      object-fit: contain; display: block;
      background: repeating-conic-gradient(#e0e0e0 0% 25%, #fff 0% 50%) 0 0 / 10px 10px;
      border-radius: 5px;
    }}
    .diff-col {{ flex: 2; }}
    pre.diff {{
      font-size: 0.7rem; font-family: "SF Mono", ui-monospace, monospace;
      white-space: pre-wrap; overflow-y: auto; max-height: 180px;
      background: #f5f5f7; padding: 0.5rem; border-radius: 5px; line-height: 1.4;
    }}
    .hidden {{ display: none !important; }}
  </style>
</head>
<body>
<header>
  <h1>SVGView Test Report</h1>
  <div class="stats">
    <div class="stat"><span class="stat-num pass">{total_pass}</span><span class="stat-label">Pass</span></div>
    <div class="stat"><span class="stat-num fail">{total_fail}</span><span class="stat-label">Fail</span></div>
    <div class="stat"><span class="stat-num unimpl">{total_unimpl}</span><span class="stat-label">Not impl.</span></div>
    <div class="stat"><span class="stat-num">{total}</span><span class="stat-label">Total</span></div>
  </div>
  <div class="filter-bar">
    <button data-filter="all"           class="active">All</button>
    <button data-filter="pass"                        >✅ Passing</button>
    <button data-filter="fail"                        >❌ Failing</button>
    <button data-filter="unimplemented"               >🔲 Unimplemented</button>
    <input id="search" type="search" placeholder="Filter by name…" spellcheck="false">
  </div>
</header>
<main>
  <nav>
    <ul>{toc_html}</ul>
  </nav>
  <div class="content">
    {"".join(std_sections_html)}
  </div>
</main>
<script>
  // ── Card header: navigate to W3C; expand icon toggles ───────────────────────
  document.querySelectorAll('.card-header').forEach(header => {{
    header.addEventListener('click', () => {{
      const url = header.dataset.w3cUrl;
      if (url) window.open(url, '_blank', 'noopener');
    }});
    header.querySelector('.expand-icon').addEventListener('click', e => {{
      e.stopPropagation();
      header.closest('.card').classList.toggle('open');
    }});
  }});

  // ── Filter + search ────────────────────────────────────────────────────────
  const cards  = Array.from(document.querySelectorAll('.card'));
  const suites = Array.from(document.querySelectorAll('.suite'));
  const stds   = Array.from(document.querySelectorAll('.standard'));
  let activeFilter = 'all';
  let searchTerm   = '';

  function applyFilters() {{
    cards.forEach(card => {{
      const matchFilter = activeFilter === 'all' || card.classList.contains(activeFilter);
      const matchSearch = !searchTerm || card.id.includes(searchTerm);
      card.classList.toggle('hidden', !(matchFilter && matchSearch));
    }});
    suites.forEach(s => s.classList.toggle('hidden',
      s.querySelectorAll('.card:not(.hidden)').length === 0));
    stds.forEach(s => s.classList.toggle('hidden',
      s.querySelectorAll('.suite:not(.hidden)').length === 0));
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

print(f"  {total_pass} pass  |  {total_fail} fail  |  {total_unimpl} unimplemented  |  {total} total")
print(f"Report: {report_path}")
