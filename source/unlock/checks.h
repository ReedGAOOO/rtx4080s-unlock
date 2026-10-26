#pragma once

#include "port.h"

typedef struct {
  UINT16 pm, pcie, msi, msix;
  UINT8 pcie_version;
} GU_CAPS;

/* Config is a complete, CPU-owned 256-byte snapshot. Out is cleared on failure. */
BOOLEAN GuCheckConfig(const UINT32 Config[64], UINTN Segment, UINTN Bus,
                      UINTN Device, UINTN Function, GU_CAPS *Out);

/* Replay/capture boundary: incomplete snapshots must never be zero-padded and
   treated as observed capability data. Does not touch Config unless size=256. */
BOOLEAN GuCheckConfigSnapshot(const UINT32 *Config, UINTN ConfigBytes,
                             UINTN Segment, UINTN Bus, UINTN Device,
                             UINTN Function, GU_CAPS *Out);

/* Path must point to readable memory through its terminator, up to MaxBytes.
   MaxBytes is a read bound, not necessarily the exact allocation length.
   Returns 1 for the reference Intel route, 2 for the profile RTX route, and 0
   otherwise. The local offline profile admits only the observed GPU path and
   its one observed GOP ADR child; this does not prove driver ownership. */
int GuDisplayPath(const EFI_DEVICE_PATH_PROTOCOL *Path, UINTN MaxBytes);
