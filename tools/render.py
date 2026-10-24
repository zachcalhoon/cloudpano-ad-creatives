#!/usr/bin/env python3
"""Render HTML ad templates to JPG (1080x1350 default) with Playwright.
Usage: python3 tools/render.py templates/pav1.html out.jpg [width height] [--png-transparent]
Templates reference stock photos as stock/<file>.jpg relative to templates/.
"""
import sys, os, subprocess
from playwright.sync_api import sync_playwright
src, out = sys.argv[1], sys.argv[2]
w = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else 1080
h = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4].isdigit() else 1350
transparent = '--png-transparent' in sys.argv
png = out if out.endswith('.png') else out + '.tmp.png'
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={'width': w, 'height': h})
    pg.goto('file://' + os.path.abspath(src)); pg.wait_for_timeout(700)
    pg.screenshot(path=png, omit_background=transparent); b.close()
if not out.endswith('.png'):
    subprocess.run(['convert', png, '-strip', '-quality', '82', out], check=True); os.remove(png)
print(out)
