#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""CPU-only complete experimental EFI app with captured inputs and fake EFI services."""
import argparse,hashlib,json,os,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser()
for n in ('evidence','assets','out'):p.add_argument('--'+n,type=Path,required=True)
p.add_argument('--edk2',type=Path,required=True)
a=p.parse_args();root=Path(__file__).resolve().parent;out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
capture=(a.evidence/'RTXPF006.LOG').read_bytes()
assert sha(capture)=='693e13cdb7858de8d213ff4ff017332a9fd840c59443b54a23550620713c9a2e'
rows=[json.loads(s) for s in capture.decode('ascii').splitlines()]
assert rows[-1]['preflight_complete'] and rows[-1]['errors']==0
configs=[bytes.fromhex(r['config256_hex']) for r in rows if r['record']=='target_config'];assert len(set(configs))==1
regs={r['offset']:int(r['value'],16) for r in rows if r['record']=='register'}
prom=a.evidence/'PROM-0x300000-0xd6c00.bin'
assert len(prom.read_bytes())==879616 and sha(prom.read_bytes())=='afd0dceca20af1ffa87b847422b2e51017811dd60e99e5326813211aa031eec7'
pins=json.loads((root.parent/'ASSETS-MANIFEST.json').read_text(encoding='utf-8'))
for n,m in pins.items():
    b=(a.assets/n).read_bytes();assert len(b)==m['bytes'] and sha(b)==m['sha256'],n
fixture='/* Captured initial values. Responses to writes are fake. */\n'
fixture+='#define GU_TEST_PROM_BYTES 879616\n#define GU_TEST_FWSEC_SIG_OFF 0x45848\n'
fixture+=f'#define GU_TEST_INITIAL_SS0 0x{regs[0x82381c]:x}U\n#define GU_TEST_INITIAL_SS1 0x{regs[0x823820]:x}U\n'
fixture+='static const UINT8 LocalConfig[256]={'+','.join(hex(b) for b in configs[0])+'};\n'
fixture+='static const UINT32 LocalRegisters[][2]={'+','.join('{'+f'0x{k:x},0x{v:x}'+'}' for k,v in regs.items())+'};\n'
(out/'transaction-capture-fixture.h').write_text(fixture,encoding='utf-8')
core=['port','compat','vendor/unlock_610','vendor/prep_610','vendor/layout_610','vendor/vbios_610','vendor/gfw_eval']
names=['unlock/tests/test_ad103_app.c']+['unlock/'+n+'.c' for n in ['app','app_io','ownership','format','sha256','checks']+core]
cmd=['gcc','-std=c11','-O1','-g','-Wall','-Wextra','-Wno-unused-parameter','-Wno-misleading-indentation','-Wno-format','-Wno-unused-function','-fshort-wchar','-mno-red-zone','-fno-omit-frame-pointer','-fsanitize=address,undefined','-fno-sanitize-recover=all','-D__KERNEL__','-DGU_UEFI_PORT','-DGU_RTX4080SUPER_EXPERIMENTAL=1','-DGU_LOCAL_CAPTURE_REPLAY=1','-I'+str(out),'-Iunlock/compat','-I'+str(a.edk2.resolve()/'MdePkg/Include'),'-I'+str(a.edk2.resolve()/'MdePkg/Include/X64')]
cmd+=['-DGU_TARGET_PCI_ID=0x270210deU']
r=subprocess.run(cmd+names+['-o',str(out/'application-tests')],cwd=root,capture_output=True,text=True)
(out/'compile.log').write_text(r.stdout+r.stderr,encoding='utf-8');r.check_returncode()
r=subprocess.run([str(out/'application-tests'),str(prom.resolve()),str(a.assets.resolve()),str((a.evidence/'target-config256.bin').resolve())],cwd=root,capture_output=True,text=True,env={**os.environ,'ASAN_OPTIONS':'detect_leaks=1'})
(out/'run.log').write_text(r.stdout+r.stderr,encoding='utf-8');r.check_returncode()
cases=re.findall(r'^AD102 APP (.+) local=(\d+) injected=(.+) disconnect=(\d+) Windows=(\d+) halt=(\d+) PASS$',r.stdout,re.M)
assert cases and int(re.search(r'(\d+) AD102 app \+ core scenarios passed',r.stdout)[1])==len(cases)
report={'scenarios_passed':len(cases),'cases':cases,'capture_sha256':sha(capture),'asan_ubsan':True,
 'hardware_access':False,'actual_observations':['256-byte PCI configuration','20 initial registers','859 KiB PROM'],
 'simulated':['PCI/MMIO writes and responses','DMA addresses/mapping','firmware success/failure','resets','hardware ownership/display approval'],
 'not_tested':['Actual GPU/firmware signature acceptance','Actual GOP release/reconnect','Actual Windows handoff'], 'application_scenario_coverage':['Fixed partition and marker validation','SecureBoot=1 and SetupMode=0','single-attempt durable record','driver ownership and release','local BAR/PROM/cold guards','DMA/firmware/FLR success and failure','GOP reconnect and Windows LoadImage/StartImage'],
 'source_sha256':{n:sha((root/n).read_bytes()) for n in names+['replay_application.py','unlock/tests/test_efi_transaction.c','unlock/tests/ad102_cases.h','unlock/fixed_source.h','unlock/target_profile.h','unlock/handoff.inc']},
 'stderr':r.stderr}
(out/'result.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('cases','source_sha256')},indent=2))
