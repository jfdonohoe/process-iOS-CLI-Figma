#!/usr/bin/env python3
"""Extract one weight layer (default Regular-S) of a custom .symbolset SVG as a plain SVG for Figma.
Usage: sf-symbolset-extract.py <symbol.svg> <out.svg> [layer-id]"""
import re, sys
src, out = sys.argv[1], sys.argv[2]; layer = sys.argv[3] if len(sys.argv) > 3 else 'Regular-S'
s = open(src).read(); m = re.search(r'<g id="%s"([^>]*)>(.*?)</g>' % re.escape(layer), s, re.S)
if not m: sys.exit(f'layer {layer} not found')
tr = re.search(r'transform="([^"]+)"', m.group(1)); paths = re.findall(r'<path[^>]*\sd="([^"]+)"', m.group(2))
open(out, 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="3300" height="2200" viewBox="0 0 3300 2200"><g transform="{tr.group(1) if tr else ""}">' + ''.join(f'<path fill="#000000" d="{d}"/>' for d in paths) + '</g></svg>')
print(f'{out}: {len(paths)} paths (trim to the glyph bounds after import)')
