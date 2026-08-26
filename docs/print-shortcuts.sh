#!/usr/bin/env bash
# Render docs/shortcuts.md to a two-column PDF and print it.
#
#   ./docs/print-shortcuts.sh            # render + print to the default printer
#   ./docs/print-shortcuts.sh --pdf-only # just build /tmp/shortcuts.pdf
#
# Chrome does the HTML->PDF step because it is already installed and honours
# @page and CSS columns. pandoc/wkhtmltopdf would both be extra dependencies for
# a job that runs twice a year.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD="$HERE/shortcuts.md"
HTML=/tmp/shortcuts.html
PDF=/tmp/shortcuts.pdf
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

[ -f "$MD" ] || { echo "missing $MD" >&2; exit 1; }
[ -x "$CHROME" ] || { echo "Google Chrome not found; needed for HTML->PDF" >&2; exit 1; }

MD="$MD" HTML="$HTML" python3 <<'PYEOF'
import os, re, html

src = open(os.environ['MD']).read()

def inline(t):
    t = html.escape(t)
    t = re.sub(r'`([^`]+)`', r'<kbd>\1</kbd>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', t)
    return re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', t)

def is_sep(cells):
    for c in cells:
        if not re.fullmatch(r'[-: ]+', c or '-'):
            return False
    return True

out, lines, i = [], src.split('\n'), 0
while i < len(lines):
    l = lines[i]
    if l.startswith('|'):
        rows = []
        while i < len(lines) and lines[i].startswith('|'):
            rows.append([c.strip() for c in lines[i].strip('|').split('|')]); i += 1
        rows = [r for r in rows if not is_sep(r)]
        out.append('<table>')
        if rows:
            out.append('<thead><tr>')
            for c in rows[0]:
                out.append(f'<th>{inline(c)}</th>')
            out.append('</tr></thead><tbody>')
            for r in rows[1:]:
                out.append('<tr>')
                for c in r:
                    out.append(f'<td>{inline(c)}</td>')
                out.append('</tr>')
            out.append('</tbody>')
        out.append('</table>')
        continue
    if l.startswith('#'):
        n = len(l) - len(l.lstrip('#'))
        out.append(f'<h{n}>{inline(l[n:].strip())}</h{n}>'); i += 1
    elif l.startswith('> '):
        buf = []
        while i < len(lines) and lines[i].startswith('> '):
            buf.append(lines[i][2:].strip()); i += 1
        out.append(f'<blockquote>{inline(" ".join(buf))}</blockquote>')
    elif l.startswith('- '):
        items = []
        while i < len(lines) and (lines[i].startswith('- ') or (items and lines[i].startswith('  '))):
            if lines[i].startswith('- '):
                items.append(lines[i][2:].strip())
            else:
                items[-1] += ' ' + lines[i].strip()
            i += 1
        out.append('<ul>')
        for x in items:
            out.append(f'<li>{inline(x)}</li>')
        out.append('</ul>')
    elif l.strip() == '---':
        i += 1
    elif l.strip():
        buf = []
        while i < len(lines) and lines[i].strip() and not lines[i].startswith(('|','#','- ','> ')) \
              and lines[i].strip() != '---':
            buf.append(lines[i].strip()); i += 1
        out.append(f'<p>{inline(" ".join(buf))}</p>')
    else:
        i += 1

css = """
@page { size: Letter; margin: 0.45in; }
body { font: 9.5pt/1.35 -apple-system,"Helvetica Neue",sans-serif; color:#111; margin:0;
       column-count:2; column-gap:22px; }
h1 { font-size:18pt; margin:0 0 4pt; column-span:all; letter-spacing:-0.4pt; }
h2 { font-size:10pt; margin:9pt 0 3pt; padding-bottom:2pt; border-bottom:1.5px solid #111;
     text-transform:uppercase; letter-spacing:0.5pt; break-after:avoid; }
h3 { font-size:9.5pt; margin:6pt 0 2pt; break-after:avoid; }
p { margin:3pt 0; }
blockquote { margin:4pt 0; padding:4pt 6pt; background:#f2f2f2; border-left:2px solid #888;
             break-inside:avoid; }
table { width:100%; border-collapse:collapse; margin:2pt 0 6pt; }
th { text-align:left; font-size:7pt; text-transform:uppercase; letter-spacing:0.3pt;
     color:#666; border-bottom:1px solid #bbb; padding:2pt 3pt; }
td { padding:2.2pt 3pt; border-bottom:0.5px solid #e5e5e5; vertical-align:top; }
tr { break-inside:avoid; }
kbd { font:8.5pt ui-monospace,Menlo,monospace; background:#eee; border:0.5px solid #ccc;
      border-radius:2px; padding:0 2.5px; white-space:nowrap; }
td:first-child kbd { background:#111; color:#fff; border-color:#111; font-weight:600; }
ul { margin:3pt 0; padding-left:12pt; }
li { margin:2pt 0; break-inside:avoid; }
strong { font-weight:650; }
"""
open(os.environ['HTML'], 'w').write(
    f"<!doctype html><meta charset=utf-8><style>{css}</style>" + "\n".join(out))
PYEOF

"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
          --print-to-pdf="$PDF" "$HTML" >/dev/null 2>&1
echo "built $PDF"

if [ "${1:-}" = "--pdf-only" ]; then
  exit 0
fi
lpr -o sides=two-sided-long-edge -o fit-to-page "$PDF"
echo "sent to $(lpstat -d | sed 's/.*: //')"
