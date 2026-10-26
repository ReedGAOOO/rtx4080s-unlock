#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Fetch pinned public EDK2 headers. No firmware or hardware access."""
import subprocess
from pathlib import Path
REV='c1415771ac592ad8509351c46cd3cda4f38d7d52'
root=Path(__file__).resolve().parents[1]
dest=root/'deps/edk2'
if dest.exists():raise SystemExit('deps/edk2 already exists; inspect it rather than overwrite it.')
dest.parent.mkdir(exist_ok=True)
subprocess.run(['git','clone','--filter=blob:none','--sparse','https://github.com/tianocore/edk2.git',str(dest)],check=True)
subprocess.run(['git','-C',str(dest),'sparse-checkout','set','MdePkg/Include'],check=True)
subprocess.run(['git','-C',str(dest),'checkout','--detach',REV],check=True)
assert subprocess.check_output(['git','-C',str(dest),'rev-parse','HEAD'],text=True).strip()==REV
print('Pinned headers ready:',dest)
