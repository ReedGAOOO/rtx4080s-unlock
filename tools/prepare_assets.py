#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Locally obtain pinned firmware inputs. No installation or GPU access."""
import hashlib,json,subprocess,sys
from pathlib import Path
r=Path(__file__).resolve().parents[1];f=r/'source/firmware-tools';cache=r/'local/cache';out=r/'local/ASSETS'
if sys.version_info<(3,14):raise SystemExit('Python 3.14+ required for tar.zst extraction.')
m=json.loads((f/'artifacts-610.43.03.json').read_text());entries=m['source_artifacts']
def run(*args):subprocess.run([sys.executable,*map(str,args)],check=True)
run(f/'fetch_artifacts.py',cache)
run(f/'generate_v67.py',cache/entries[2]['filename'],out)
run(f/'extract_boot_assets.py',cache/entries[0]['filename'],out,'--arch','ad102','--gsp',out/'gsp_ga10x.bin')
for name,entry in json.loads((r/'ASSETS-MANIFEST.json').read_text()).items():
    b=(out/name).read_bytes()
    assert len(b)==entry['bytes'] and hashlib.sha256(b).hexdigest()==entry['sha256'],name
print('Local assets validated; keep local/ private. No hardware operation performed.')
