#!/usr/bin/env python3
"""
auto-link-pitfalls.py
Scan all pitfall markdown files and create gbrain links based on:
  1. [[slug]] wikilink patterns
  2. pitfall ID references like P-001, P-007 etc.
  3. slug substring mentions in body text

Run once: python3 D:/jamesclew/harness/scripts/auto-link-pitfalls.py
"""
import os, re, subprocess

PITFALL_DIR = 'D:/jamesclew/harness/pitfalls/'

# Build slug map: P-NNN → slug, and slug list
slug_map = {}   # "P-001" -> "pitfall-001-loading-lazy-headless"
all_slugs = []

for f in os.listdir(PITFALL_DIR):
    if not f.endswith('.md'):
        continue
    slug = f.replace('.md', '')
    all_slugs.append(slug)
    # Extract P-NNN from slug name (e.g. pitfall-001-...)
    m = re.match(r'pitfall-(\d+)-', slug)
    if m:
        num = int(m.group(1))
        pid = f'P-{num:03d}'
        slug_map[pid] = slug

def gbrain_link(from_slug, to_slug):
    r = subprocess.run(
        f'gbrain link {from_slug} {to_slug}',
        shell=True, capture_output=True, text=True
    )
    return r.returncode == 0

created = 0
skipped = 0

for f in sorted(os.listdir(PITFALL_DIR)):
    if not f.endswith('.md'):
        continue
    from_slug = f.replace('.md', '')
    filepath = os.path.join(PITFALL_DIR, f)

    with open(filepath, encoding='utf-8') as fh:
        content = fh.read()

    targets = set()

    # Pattern 1: [[some-slug]] wikilinks
    for wikilink in re.findall(r'\[\[([^\]]+)\]\]', content):
        candidate = wikilink.strip().replace(' ', '-').lower()
        if candidate in all_slugs and candidate != from_slug:
            targets.add(candidate)

    # Pattern 2: P-NNN references (e.g. P-001, P-014)
    for pid_num in re.findall(r'P-(\d{1,3})\b', content):
        pid_key = f'P-{int(pid_num):03d}'
        if pid_key in slug_map:
            target = slug_map[pid_key]
            if target != from_slug:
                targets.add(target)

    # Pattern 3: pitfall-NNN direct slug reference in body
    for candidate in all_slugs:
        if candidate == from_slug:
            continue
        # match "pitfall-001" or "pitfall-007" as substring in body
        num_match = re.match(r'pitfall-(\d+)-', candidate)
        if num_match:
            num_str = num_match.group(1)
            if re.search(rf'pitfall-{num_str}\b', content):
                targets.add(candidate)

    for to_slug in targets:
        if gbrain_link(from_slug, to_slug):
            print(f'  LINK  {from_slug} → {to_slug}')
            created += 1
        else:
            skipped += 1

print(f'\nDone: {created} links created, {skipped} skipped/failed')
