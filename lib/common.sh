#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
# laravel-worktree-kit — shared helpers.
# This file is *sourced* by bin/worktree-setup and bin/worktree-teardown.
# It never runs on its own and never writes anything.
# ---------------------------------------------------------------------------

wtk_say()  { printf '%s\n' "$*"; }
wtk_warn() { printf '!  %s\n' "$*" >&2; }
wtk_die()  { printf '✗  %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Host detection.
#
# Every ADE names its variables differently, and none of them is guaranteed
# to be there — you may well be running this by hand in a plain terminal.
# So we read whichever is set and always keep a git fallback. This is the
# whole reason the kit is portable: nothing below this function knows which
# ADE it is running under.
# ---------------------------------------------------------------------------
wtk_detect_host() {
    if   [ -n "${ORCA_ROOT_PATH:-}" ];      then WTK_HOST=orca
    elif [ -n "${SUPERSET_ROOT_PATH:-}" ];  then WTK_HOST=superset
    elif [ -n "${ROOT_PROJECT_PATH:-}" ];   then WTK_HOST=openchamber
    else                                         WTK_HOST=git
    fi
}

# Absolute path of the MAIN checkout (not this worktree).
wtk_main_root() {
    case "${WTK_HOST}" in
        orca)        printf '%s' "${ORCA_ROOT_PATH}" ;;
        superset)    printf '%s' "${SUPERSET_ROOT_PATH}" ;;
        openchamber) printf '%s' "${ROOT_PROJECT_PATH}" ;;
        *)
            # .git/worktrees/<name> -> .git -> repo root
            local common
            common="$(git rev-parse --git-common-dir 2>/dev/null)" \
                || wtk_die "Not inside a git repository."
            printf '%s' "$(dirname "$(cd "$common" && pwd)")"
            ;;
    esac
}

# Human name of THIS worktree. Falls back to the branch, which is what you
# get in a bare terminal and under hosts that expose no name of their own.
wtk_workspace_name() {
    local name=""
    case "${WTK_HOST}" in
        orca)     name="${ORCA_WORKSPACE_NAME:-}" ;;
        superset) name="${SUPERSET_WORKSPACE_NAME:-}" ;;
    esac
    if [ -z "$name" ]; then
        name="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    fi
    if [ -z "$name" ] || [ "$name" = "HEAD" ]; then
        name="$(basename "$PWD")"
    fi
    printf '%s' "$name"
}

# a-z0-9 and dashes — safe in a hostname.
wtk_slug() {
    printf '%s' "$1" | sed 's#[^a-zA-Z0-9]#-#g' | tr '[:upper:]' '[:lower:]' \
        | sed 's#-\{2,\}#-#g; s#^-##; s#-$##'
}

# Site name for <repo> + <workspace>, at most WTK_SITE_MAX_LEN (58) characters.
# `herd secure` puts the domain in the certificate CN, capped at 64: past that
# it writes the .key without the .crt, and the orphan nginx config then stops
# nginx from starting — every .test site goes down. A name that is too long is
# cut and suffixed with a hash of the workspace, so it stays unique and stable.
wtk_site_name() {
    local repo="$1" workspace="$2" name hash keep
    local max="${WTK_SITE_MAX_LEN:-58}"
    name="$(wtk_slug "${repo}-${workspace}")"
    if [ "${#name}" -gt "$max" ]; then
        hash="$(printf '%s' "$workspace" | cksum | awk '{print $1}')"
        keep=$(( max - ${#hash} - 1 ))
        name="$(printf '%s' "$name" | cut -c1-"$keep" | sed 's#-*$##')-${hash}"
    fi
    printf '%s' "$name"
}

# a-z0-9 and underscores — safe as a database identifier.
wtk_ident() {
    printf '%s' "$1" | sed 's#[^a-zA-Z0-9]#_#g' | tr '[:upper:]' '[:lower:]' \
        | sed 's#_\{2,\}#_#g; s#^_##; s#_$##'
}

# ---------------------------------------------------------------------------
# Port allocation.
#
# Each worktree gets a contiguous block of ports, picked deterministically
# from its own name: the same worktree always lands on the same ports, with
# no shared state file to keep in sync and nothing to clean up afterwards.
#
#   slot  = hash(site_name) % WTK_PORT_SLOTS
#   port  = WTK_PORT_BASE + slot * WTK_PORT_STRIDE + <index>
#
# Services inside one worktree can never collide. Two different worktrees
# collide only if they hash to the same slot — raise WTK_PORT_SLOTS if you
# routinely run more worktrees than slots.
# ---------------------------------------------------------------------------
wtk_port_slot() {
    local key="$1" hash
    hash="$(printf '%s' "$key" | cksum | awk '{print $1}')"
    printf '%s' "$(( hash % WTK_PORT_SLOTS ))"
}

wtk_port() {
    local slot="$1" index="$2"
    printf '%s' "$(( WTK_PORT_BASE + slot * WTK_PORT_STRIDE + index ))"
}

# ---------------------------------------------------------------------------
# .env editing.
#
# Writes through a temp file rather than `sed -i`, whose syntax differs
# between BSD (macOS) and GNU sed. Values are written verbatim; quote them
# yourself if they contain spaces.
# ---------------------------------------------------------------------------
wtk_set_env() {
    local key="$1" val="$2" file="${3:-.env}"
    [ -f "$file" ] || wtk_die "No $file to write to."
    if grep -q "^${key}=" "$file"; then
        awk -v k="$key" -v v="$val" \
            'BEGIN{FS=OFS="="} $1==k {print k "=" v; next} {print}' \
            "$file" > "$file.wtk.tmp" && mv "$file.wtk.tmp" "$file"
    else
        printf '%s=%s\n' "$key" "$val" >> "$file"
    fi
}

# ---------------------------------------------------------------------------
# Safety rail.
#
# The teardown script drops a database and unregisters a site. Running it in
# the main checkout by mistake would take out your real development setup,
# so both scripts refuse to touch a directory that *is* the main checkout.
# ---------------------------------------------------------------------------
wtk_assert_not_main_checkout() {
    local here main
    here="$(cd "$PWD" && pwd -P)"
    main="$(cd "$1" && pwd -P)"
    [ "$here" != "$main" ] \
        || wtk_die "Refusing to run inside the main checkout ($main). This belongs in a worktree."
}

# Load <repo>/.worktreekit.sh if present. Config lives in the MAIN checkout so
# it is read even before this worktree has been populated.
wtk_load_config() {
    local main_root="$1"
    WTK_PORT_BASE="${WTK_PORT_BASE:-8100}"
    WTK_PORT_SLOTS="${WTK_PORT_SLOTS:-50}"
    WTK_PORT_STRIDE="${WTK_PORT_STRIDE:-10}"
    WTK_PHP_VERSION="${WTK_PHP_VERSION:-}"
    WTK_DB_DRIVER="${WTK_DB_DRIVER:-pgsql}"
    WTK_DB_HOST="${WTK_DB_HOST:-127.0.0.1}"
    WTK_DB_PORT="${WTK_DB_PORT:-}"
    WTK_DB_USER="${WTK_DB_USER:-root}"
    WTK_PACKAGE_MANAGER="${WTK_PACKAGE_MANAGER:-auto}"
    WTK_BUILD="${WTK_BUILD:-1}"
    WTK_SEED="${WTK_SEED:-1}"
    WTK_SECURE="${WTK_SECURE:-1}"
    WTK_COPY_FILES="${WTK_COPY_FILES:-.env .mcp.json}"
    WTK_PORT_SERVICES="${WTK_PORT_SERVICES:-}"
    WTK_FORCE_ENV="${WTK_FORCE_ENV:-MAIL_MAILER=log}"
    # shellcheck source=/dev/null
    [ -f "$main_root/.worktreekit.sh" ] && . "$main_root/.worktreekit.sh"
    return 0
}
