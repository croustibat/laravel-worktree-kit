#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
# Copy this to .worktreekit.sh at the root of your Laravel project.
# It is sourced by both scripts, from the MAIN checkout, before anything runs.
# Every value below is optional — the defaults shown are what you get without
# a config file at all.
# ---------------------------------------------------------------------------

# --- Site ------------------------------------------------------------------
WTK_SITE_TOOL=auto         # auto | herd | valet | none
WTK_SITE_TLD=test
WTK_PHP_VERSION=           # e.g. 8.4 — empty means "don't isolate"
WTK_SECURE=1               # serve the worktree over https

# --- Database --------------------------------------------------------------
WTK_DB_DRIVER=pgsql        # pgsql | mysql | mariadb | sqlite | none
WTK_DB_HOST=127.0.0.1
WTK_DB_PORT=               # empty means the client's default
WTK_DB_USER=root
WTK_SEED=1                 # migrate --seed rather than migrate

# --- Ports -----------------------------------------------------------------
# Each worktree gets a block of WTK_PORT_STRIDE consecutive ports, picked
# from a hash of its name. Declare which .env keys receive which port of the
# block as "<index>:KEY,KEY,KEY".
#
# Keys in one group all get the SAME port. That matters more than it looks:
# a websocket server binds one port and the browser dials another, and if
# they drift apart the page quietly talks to a different worktree.
WTK_PORT_BASE=8100
WTK_PORT_SLOTS=50          # how many worktrees before two share a block
WTK_PORT_STRIDE=10         # ports reserved per worktree
WTK_PORT_SERVICES="0:REVERB_SERVER_PORT,REVERB_PORT,VITE_REVERB_PORT"

# --- Files to carry over from the main checkout ----------------------------
# git does not move ignored files into a new worktree. These are copied.
WTK_COPY_FILES=".env .mcp.json"

# --- Values forced in every worktree ---------------------------------------
# Space-separated KEY=VALUE. This is a safety setting, not a convenience:
# five agents working in parallel must not send real mail, write to a shared
# bucket, or post to your error tracker.
WTK_FORCE_ENV="MAIL_MAILER=log"

# --- Front-end -------------------------------------------------------------
WTK_PACKAGE_MANAGER=auto   # auto | npm | yarn | pnpm | bun
WTK_BUILD=1

# ---------------------------------------------------------------------------
# Hooks. Define any of these as shell functions; they are called if present.
#
#   wtk_before            at the very start, in the new worktree
#   wtk_before_composer   with the composer command as $1
#   wtk_after             once everything else succeeded
#   wtk_before_teardown   before the site and database go
#   wtk_after_teardown    last thing before the worktree is removed
# ---------------------------------------------------------------------------

# Private Composer repositories — read credentials from the environment,
# never write them in a file you are going to commit.
# wtk_before_composer() {
#     local composer="$1"
#     [ -n "${FLUX_USERNAME:-}" ] && \
#         $composer config http-basic.composer.fluxui.dev \
#             "$FLUX_USERNAME" "$FLUX_LICENSE_KEY"
# }

# wtk_after() {
#     php artisan telescope:install --quiet || true
# }
