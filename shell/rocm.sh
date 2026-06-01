# ROCm environment for interactive shells.
# Sourced from ~/.bashrc and ~/.zshrc (install.sh wires in the source line).
# Covers bare TTY/SSH logins; uwsm session shells also get this via environment.d.
# POSIX-portable (case instead of [[ ]]) so it works under bash and zsh.

export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm

case ":$PATH:" in
    *":/opt/rocm/bin:"*) ;;
    *) export PATH="/opt/rocm/bin:$PATH" ;;
esac

# Expose only the RX 7800 XT (gfx1101); hide the unsupported Raphael iGPU (gfx1036).
export HIP_VISIBLE_DEVICES=0
