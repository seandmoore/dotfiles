#!/usr/bin/env bash
# check-dmem-config.sh — pacman PostTransaction helper.
#
# Verifies the DRM device-memory cgroup controller (CONFIG_CGROUP_DMEM) is enabled
# in any kernel that was just installed or upgraded. That option IS "Valve's VRAM
# patch" (Natalie Vock's dmemcg work, mainline since Linux 6.14); the dmemcg-booster
# + hypr-dmemcg-foreground stack is useless without it. This is purely advisory — it
# never blocks the transaction, it just warns if a kernel ships without the option so
# a future regression or a switch to a custom kernel doesn't silently break VRAM
# foreground boosting.
#
# Invoked by etc/pacman.d/hooks/95-vram-dmem-check.hook with NeedsTargets, so the
# matched kernel vmlinuz paths arrive on stdin (one per line).
set -uo pipefail

OPT="CONFIG_CGROUP_DMEM"
YELLOW='\033[33m'; GREEN='\033[32m'; RESET='\033[0m'

running_has_it() { zcat /proc/config.gz 2>/dev/null | grep -q "^${OPT}=y"; }

while IFS= read -r target; do
    # target looks like: usr/lib/modules/<version>/vmlinuz
    moddir="/${target%/vmlinuz}"
    ver="${moddir##*/modules/}"
    cfg="$moddir/config"   # present only if the kernel was built with CONFIG_IKCONFIG and ships it

    if [[ -f "$cfg" ]]; then
        if grep -q "^${OPT}=y" "$cfg"; then
            printf "  ${GREEN}dmem cgroup OK${RESET}  %s  (VRAM foreground boosting supported)\n" "$ver"
        else
            printf "  ${YELLOW}WARNING${RESET}  %s does NOT enable %s — dmemcg-booster / hypr-dmemcg-foreground will not work on it.\n" "$ver" "$OPT"
        fi
    elif running_has_it; then
        printf "  ${GREEN}dmem cgroup OK${RESET}  running kernel has %s (re-verify %s after rebooting into it)\n" "$OPT" "$ver"
    else
        printf "  ${YELLOW}NOTE${RESET}  could not verify %s for %s offline; after reboot run:  zcat /proc/config.gz | grep %s\n" "$OPT" "$ver" "$OPT"
    fi
done

exit 0
