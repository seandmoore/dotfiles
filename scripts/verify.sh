#!/usr/bin/env bash
# Syntax verification for all dotfile types.
# Usage: ./scripts/verify.sh [file...]
#   No args  → check all tracked files
#   --staged → check only git-staged files (used by pre-commit hook)
#   file...  → check specific files

set -euo pipefail

ERRORS=0
CHECKED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

pass() { printf "${GREEN}  ok${RESET}  %s\n" "$1"; }
fail() { printf "${RED}FAIL${RESET}  %s\n  └─ %s\n" "$1" "$2"; ERRORS=$((ERRORS + 1)); }
skip() { printf "${YELLOW}skip${RESET}  %s  (%s)\n" "$1" "$2"; }

check_lua() {
    local file="$1"
    local out
    if out=$(luac -p "$file" 2>&1); then
        pass "$file"
    else
        fail "$file" "$out"
    fi
    CHECKED=$((CHECKED + 1))
}

check_shell() {
    local file="$1"
    local out
    if out=$(bash -n "$file" 2>&1); then
        pass "$file"
    else
        fail "$file" "$out"
    fi
    CHECKED=$((CHECKED + 1))
}

check_qml() {
    local file="$1"
    if ! command -v qmllint &>/dev/null; then
        skip "$file" "qmllint not found"
        return
    fi
    local out
    if out=$(qmllint "$file" 2>&1); then
        pass "$file"
    else
        fail "$file" "$out"
    fi
    CHECKED=$((CHECKED + 1))
}

check_hypr_conf() {
    local file="$1"
    # Basic structural checks: balanced braces, no bare = signs outside blocks
    local out line_num=0 depth=0 errors=""
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Strip comments and trim
        local stripped="${line%%#*}"
        stripped="${stripped#"${stripped%%[![:space:]]*}"}"
        stripped="${stripped%"${stripped##*[![:space:]]}"}"
        [[ -z "$stripped" ]] && continue

        opens=$(grep -o '{' <<<"$stripped" 2>/dev/null | wc -l || true)
        closes=$(grep -o '}' <<<"$stripped" 2>/dev/null | wc -l || true)
        depth=$((depth + opens - closes))

        if [[ $depth -lt 0 ]]; then
            errors+="line $line_num: unexpected '}' (depth went negative)\n"
            depth=0
        fi
    done < "$file"

    if [[ $depth -ne 0 ]]; then
        errors+="unbalanced braces at end of file (unclosed blocks: $depth)\n"
    fi

    if [[ -n "$errors" ]]; then
        fail "$file" "$(printf '%b' "$errors" | head -5)"
    else
        pass "$file"
    fi
    CHECKED=$((CHECKED + 1))
}

check_kitty_conf() {
    local file="$1"
    local out line_num=0 errors=""
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local stripped="${line%%#*}"
        stripped="${stripped#"${stripped%%[![:space:]]*}"}"
        [[ -z "$stripped" ]] && continue
        # Valid lines: key value  OR  include path  OR  map key action
        if ! [[ "$stripped" =~ ^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]] || "$stripped" =~ ^include[[:space:]] || "$stripped" =~ ^map[[:space:]] || "$stripped" =~ ^mouse_map[[:space:]] ]]; then
            errors+="line $line_num: unrecognised syntax: ${stripped:0:60}\n"
        fi
    done < "$file"
    if [[ -n "$errors" ]]; then
        fail "$file" "$(printf '%b' "$errors" | head -5)"
    else
        pass "$file"
    fi
    CHECKED=$((CHECKED + 1))
}

dispatch() {
    local file="$1"
    [[ -f "$file" ]] || return

    case "$file" in
        *.lua)              check_lua "$file" ;;
        *.sh)               check_shell "$file" ;;
        *.qml)              check_qml "$file" ;;
        */hypr/*.conf)      check_hypr_conf "$file" ;;
        */kitty/*.conf)     check_kitty_conf "$file" ;;
        *)                  ;;  # unknown type — skip silently
    esac
}

# ── Entry point ────────────────────────────────────────────────────────────────

MODE="all"
FILES=()

for arg in "$@"; do
    case "$arg" in
        --staged) MODE="staged" ;;
        *)        FILES+=("$arg") ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ${#FILES[@]} -gt 0 ]]; then
    for f in "${FILES[@]}"; do dispatch "$f"; done
elif [[ "$MODE" == "staged" ]]; then
    while IFS= read -r f; do
        dispatch "$REPO_ROOT/$f"
    done < <(git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACMR)
else
    while IFS= read -r f; do
        dispatch "$REPO_ROOT/$f"
    done < <(git -C "$REPO_ROOT" ls-files)
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    printf "${GREEN}All checks passed${RESET} (%d file(s) checked)\n" "$CHECKED"
    exit 0
else
    printf "${RED}%d error(s)${RESET} in %d file(s) checked\n" "$ERRORS" "$CHECKED"
    exit 1
fi
