#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Check distributable files, links, source guard and JSON. No hardware access."""
import ast,json,re,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
ignored={'local','deps','.git','build-candidate','__pycache__'}
files=[p for p in root.rglob('*') if p.is_file() and not any(x in ignored for x in p.relative_to(root).parts)]
failures=[]
for p in files:
    rel=p.relative_to(root).as_posix()
    if p.suffix.lower() in {'.bin','.rom','.efi','.cubin','.ptx','.dmp','.pfx','.p12','.key'}:failures.append(rel+': excluded binary/secret format')
    text=p.read_text(encoding='utf-8-sig')
    if re.search(r'(?i)(?:C:\\\\?Users\\|/home/[A-Za-z0-9_.-]+/|GPU-(?!00000000)[0-9a-f]{8}-|eui\.[0-9a-f]{12,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)',text):failures.append(rel+': possible private identifier/secret')
    if p.suffix=='.json':json.loads(text)
    if p.suffix=='.py':ast.parse(text,filename=rel)
    if p.suffix=='.md':
        for target in re.findall(r'\]\(([^)]+)\)',text):
            if '://' in target or target.startswith('#'):continue
            target=target.split('#')[0]
            if target and not (p.parent/target).exists():failures.append(rel+': broken link '+target)
fixed=(root/'source/unlock/fixed_source.h').read_text()
assert 'GU_PUBLIC_REFERENCE_BUILD' in fixed and 'return FALSE; /* Published builds' in fixed
assert '-DGU_PUBLIC_REFERENCE_BUILD=1' in (root/'source/build_candidate.py').read_text()
assert "throw 'Public reference:" in (root/'host/AutoUnlock.ps1').read_text()
assert all(not x['included'] for x in json.loads((root/'ASSETS-MANIFEST.json').read_text()).values())
if failures:raise SystemExit('\n'.join(failures))
print(json.dumps({'files_checked':len(files),'privacy_and_format_scan':'passed','relative_links':'passed','public_guards':'present','hardware_access':False},indent=2))
