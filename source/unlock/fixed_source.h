/* SPDX-License-Identifier: GPL-2.0-only */
#pragma once
#define GU_LOCAL_DIRECTORY L"\\RTX-AUTO60"
#define GU_AUTO_TOKEN "RTX-AUTO-060-2702-f00dbaad\r\n"
#define GU_SOURCE_MARKER "RTX-UEFI-FIXED-V1-f00dbaad-2048-1048576\r\n"
static UINT32 GuSource32(const UINT8 *p){return p[0]|((UINT32)p[1]<<8)|((UINT32)p[2]<<16)|((UINT32)p[3]<<24);}
static UINT64 GuSource64(const UINT8 *p){return GuSource32(p)|((UINT64)GuSource32(p+4)<<32);}
/* Exact MBR signature, partition number, start/length; only one HD node,
   terminal immediately after that partition, no multi-instance paths. */
static BOOLEAN GuFixedSourceMatches(const UINT8 *p,UINTN limit) {
#ifdef GU_PUBLIC_REFERENCE_BUILD
  return FALSE; /* Published builds cannot match a boot partition. */
#endif
  if(!p || limit>4096)return FALSE;
  UINTN off=0,found=0;
  for(UINTN i=0;i<128 && off<=limit && limit-off>=4;i++) {
    UINTN n=p[off+2]+((UINTN)p[off+3]<<8);
    if(n<4 || n>limit-off)return FALSE;
    if(p[off]==0x7f)return p[off+1]==0xff && n==4 && found==1;
    if(found)return FALSE;
    if(p[off]==4 && p[off+1]==1) {
      if(n!=42 || GuSource32(p+off+4)!=2 || GuSource64(p+off+8)!=2048ULL ||
         GuSource64(p+off+16)!=1048576ULL || GuSource32(p+off+24)!=0xf00dbaad ||
         p[off+40]!=1 || p[off+41]!=1)return FALSE;
      for(UINTN j=28;j<40;j++)if(p[off+j])return FALSE;
      found=1;
    }
    off+=n;
  }
  return FALSE;
}
