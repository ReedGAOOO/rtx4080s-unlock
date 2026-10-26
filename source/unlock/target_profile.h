/* SPDX-License-Identifier: GPL-2.0-only */
/* Local identity/path and bounded cold MMIO observed on 2026-10-25.
   Booter/FWSEC signature slots pass CPU replay. Hardware acceptance,
   driver release/recovery and Windows handoff remain unverified. */
#pragma once
#if defined(GU_RTX4080SUPER_OFFLINE) && defined(GU_RTX4080SUPER_EXPERIMENTAL)
#error Choose the disabled build OR the explicit single-attempt experimental build
#endif
#if defined(GU_RTX4080SUPER_OFFLINE) || defined(GU_RTX4080SUPER_EXPERIMENTAL)
#define GU_PROFILE_LOCAL 1
#define GU_BOARD_ID 0x270210deU
#define GU_BOARD_SUBSYSTEM 0x18cc10deU
#define GU_BOARD_CHIP 0x193000a1U /* observed in RTXPF003.LOG and RTXPF006.LOG */
#define GU_PROFILE_SEGMENT 0U
#define GU_PROFILE_BUS 2U
#define GU_PROFILE_DEVICE 0U
#define GU_PROFILE_FUNCTION 0U
#define GU_PROFILE_RTX_ROOT_PORT 6U
#define GU_PROFILE_GOP_ADR 0x80010370U
#define GU_PROFILE_BAR0 0x8c000000U
#define GU_PROFILE_SS1 3U
#ifdef GU_RTX4080SUPER_EXPERIMENTAL
#define GU_PROFILE_OFFLINE_ONLY 0
#else
#define GU_PROFILE_OFFLINE_ONLY 1
#endif
#else
#define GU_PROFILE_LOCAL 0
#define GU_BOARD_ID 0x270410deU
#define GU_BOARD_SUBSYSTEM 0x179510deU
#define GU_BOARD_CHIP 0x193000a1U
#define GU_PROFILE_SEGMENT 0U
#define GU_PROFILE_BUS 1U
#define GU_PROFILE_DEVICE 0U
#define GU_PROFILE_FUNCTION 0U
#define GU_PROFILE_RTX_ROOT_PORT 1U
#define GU_PROFILE_OFFLINE_ONLY 0
#define GU_PROFILE_BAR0 0x80000000U
#define GU_PROFILE_SS1 7U
#endif
/* The default local build stays disabled; the candidate requires its own build macro. */
#define GU_PROFILE_LOCATION_MATCH(S,B,D,F) \
  ((S)==GU_PROFILE_SEGMENT && (B)==GU_PROFILE_BUS && \
   (D)==GU_PROFILE_DEVICE && (F)==GU_PROFILE_FUNCTION)
