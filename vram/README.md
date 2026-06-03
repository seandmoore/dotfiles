# VRAM foreground boosting (dmemcg)

Gives the **focused** window priority on real GPU VRAM, pushing background apps
(browsers, etc.) into slower system RAM (GTT) first when VRAM is contended. This is
the Hyprland counterpart to KDE's `plasma-foreground-booster`, built on Valve dev
Natalie Vock's DRM device-memory cgroup controller (`CONFIG_CGROUP_DMEM`, mainline
since Linux 6.14 — often called "Valve's VRAM patch").

## Pieces

| File | Deployed to | Role |
|------|-------------|------|
| `hypr-dmemcg-foreground` | `~/.local/bin/` | Daemon: watches Hyprland `socket2`; on focus change writes `dmem.low=capacity` on the focused window's cgroup and `0` on the previous one. |
| `hypr-dmemcg-foreground.service` | `~/.config/systemd/user/` | Runs the daemon, bound to `graphical-session.target`. |
| `steam.desktop` | `~/.local/share/applications/` | Overrides the system entry to launch Steam via `uwsm app -s app.slice`, so it lands **directly under `app.slice`** (the dmem-protected branch) instead of `app-graphical.slice`/`session.slice`, whose `dmem.low=0` would clamp the boost to nothing. |

## Requirements (installed by `install.sh`)

- A kernel with `CONFIG_CGROUP_DMEM=y` (verified on every kernel update by
  `scripts/check-dmem-config.sh` via `etc/pacman.d/hooks/95-vram-dmem-check.hook`).
- AUR `dmemcg-booster` — enables the `dmem` controller across the cgroup tree and
  sets the baseline `dmem.low` protection on `app.slice`. Its system + user services
  must both be active.

## Notes

- Benefits scale with VRAM pressure; on a 16 GB card it only matters in the heaviest
  titles that actually exhaust VRAM. The upstream work targets ≤8 GB GPUs.
- Only apps under `app.slice` (e.g. anything launched via `uwsm app`) can be
  effectively boosted; protection is ancestor-clamped like `memory.low`.
