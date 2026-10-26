#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Compile a non-deployable reference EFI. Never install or execute it."""
import argparse, hashlib, json, os, struct, subprocess
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--zig',required=True,help='Path to Zig 0.14.1 executable')
p.add_argument('--edk2',type=Path,required=True,help='Pinned EDK2 tree containing MdePkg/Include')
a=p.parse_args()
r=Path(__file__).resolve().parent
edk=a.edk2.resolve(); assert (edk/'MdePkg/Include/Uefi.h').is_file()
os.chdir(r)
names=['app','app_io','ownership','format','runtime','sha256','checks','port','compat','vendor/unlock_610','vendor/prep_610','vendor/layout_610','vendor/vbios_610','vendor/gfw_eval']
out=r/'build-candidate/RTXAUTO.EFI';out.parent.mkdir(exist_ok=True)
cmd=[a.zig,'cc','-target','x86_64-uefi','-std=c11','-ffreestanding','-fno-builtin','-fno-stack-protector','-mno-red-zone','-fshort-wchar','-Os','-g0','-Wall','-Wextra','-Werror','-Wno-unused-parameter','-D__KERNEL__','-DGU_UEFI_PORT','-DGU_PUBLIC_REFERENCE_BUILD=1','-DGU_RTX4080SUPER_EXPERIMENTAL=1','-DGU_TARGET_PCI_ID=0x270210deU','-Iunlock/compat','-I'+str(edk/'MdePkg/Include'),'-I'+str(edk/'MdePkg/Include/X64'),'-nostdlib']
subprocess.run(cmd+['unlock/'+x+'.c' for x in names]+['-o',str(out)],check=True)
b=out.read_bytes();u16=lambda o:struct.unpack_from('<H',b,o)[0];u32=lambda o:struct.unpack_from('<I',b,o)[0]
pe=u32(60);opt=pe+24
assert b[:2]==b'MZ' and b[pe:pe+4]==b'PE\0\0' and u16(pe+4)==0x8664 and u16(opt+68)==10
for i in (1,12,13):assert b[opt+112+i*8:opt+120+i*8]==b'\0'*8
report={'artifact':'source/build-candidate/RTXAUTO.EFI','bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'version':'0.6.2-public.1','reference_only':True,'partition_matching_disabled':True,'hardware_execution_tested':False,'unsigned':True,'system_settings_changed':False,'zig_version':subprocess.check_output([a.zig,'version'],text=True).strip()}
(out.parent/'build-result.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
