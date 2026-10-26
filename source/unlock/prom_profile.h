#ifndef GU_PROM_PROFILE_H
#define GU_PROM_PROFILE_H
/* RUN04 hardware dump: BAR0+0x300000 already begins at AD103.rom+0x9400.
 * PROM[0,0xd6c00) == full ROM[0x9400,0xe0000), byte for byte.
 * Share this mapping between preflight verification and FWSEC extraction. */
#define GU_PROM_BAR_OFFSET 0x300000U
#define GU_PROM_VIEW_BYTES 0xd6c00U
#if defined(GU_RTX4080SUPER_OFFLINE) || defined(GU_RTX4080SUPER_EXPERIMENTAL)
/* Local 2702/18cc captured PROM: RTXPF003.LOG, 2026-10-25 23:19.
 * Also repeated byte-for-byte by RTXPF006.LOG at 23:48. */
#define GU_PROM_VIEW_SHA256 "afd0dceca20af1ffa87b847422b2e51017811dd60e99e5326813211aa031eec7"
#else
#define GU_PROM_VIEW_SHA256 "603baffea2842b3d553e766146f498bff26413b9868f67f6b650aaaa37005526"
#endif
#endif
