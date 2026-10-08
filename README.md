# laravel-worktree-kit

**Laravel worktrees that boot themselves — a site, a database and ports of
their own, for every agent.**

Coding agents got good at working in parallel, one git worktree each. Every
tool that does this assumes a worktree is a working project. In Node it very
nearly is. In Laravel it is not: a fresh worktree has no `.env`, no database,
no site in Herd, no `vendor/`, and the websocket server it starts fights the
one next door over a port.

So you do it by hand, once per worktree, and in practice you stop at one
agent. This kit is the twenty minutes of plumbing, written down once.

```sh
cd ../myapp-billing          # a worktree you just created
worktree-setup
#   site  https://myapp-billing.test
#   db    myapp_billing
#   port  8142  →  REVERB_SERVER_PORT,REVERB_PORT,VITE_REVERB_PORT
```

Wire it into your ADE's setup hook and that happens on its own, every time an
agent opens a worktree.

## Install

```sh
git clone https://github.com/croustibat/laravel-worktree-kit ~/.laravel-worktree-kit
```

Nothing to compile and nothing to add to your PATH — the hooks call the
scripts by their full path.

## Configure

Copy the example to the root of your Laravel project and keep the handful of
lines you actually need:

```sh
cp ~/.laravel-worktree-kit/.worktreekit.example.sh .worktreekit.sh
```

A typical TALL project on Herd and PostgreSQL with Reverb:

```sh
WTK_PHP_VERSION=8.4
WTK_DB_DRIVER=pgsql
WTK_PORT_SERVICES="0:REVERB_SERVER_PORT,REVERB_PORT,VITE_REVERB_PORT"
WTK_COPY_FILES=".env .mcp.json"
```

With no config file at all you get PostgreSQL, Herd if it is installed, no
port allocation, and `.env` copied from the main checkout.

## Wire it into your ADE

| | |
|---|---|
| [Orca](recipes/orca.md) | Settings → Repository → Hooks |
| [Superset](recipes/superset.md) | `.superset/config.json` |
| [OpenChamber](recipes/openchamber.md) | `.openchamber/project.json` |
| [plain git](recipes/plain-git.md) | run it yourself |

The scripts read whichever variables the host exposes and fall back to git, so
the same two commands work everywhere — including in a bare terminal, which is
where you debug them.

## What setup does, in order

1. Copies the files git will not carry into a worktree — `.env`, `.mcp.json`,
   whatever you list — falling back to `.env.example`.
2. Derives this worktree's identity: `APP_URL`, database name, and one block
   of ports.
3. Registers a site in Herd or Valet, isolates the PHP version, secures it.
4. Creates the database.
5. `composer install`, then `key:generate`, `migrate --seed`, `storage:link`.
6. Installs and builds the front end with whichever package manager the
   lockfile implies.

`worktree-teardown` undoes 3 and 4. Run it from the archive hook, before the
worktree is removed.

## Four decisions worth explaining

**Ports come in blocks, from a hash of the name.** No shared state file, no
allocation table to repair, and the same worktree always lands on the same
ports. Every key in a group gets the *same* port, because a websocket server
binds one port and the browser dials another — let those drift and your page
quietly talks to a different worktree. That bug costs an afternoon.

**Some values are forced in every worktree.** `MAIL_MAILER=log` by default.
Five agents working in parallel must not send real mail to real customers, and
this is the one failure in this list you cannot take back. Add your error
tracker and your object storage to `WTK_FORCE_ENV`.

**Both scripts refuse to run in the main checkout.** Teardown drops a database
and unregisters a site. Run it one directory too high and you have just
deleted your actual development setup.

**Nothing here knows which ADE it is running under.** Host detection is twelve
lines at the top of `lib/common.sh`; everything below it is plain git. Adding
another ADE means adding two lines, not a fork.

## Also in here

[Ten Claude Code subagents](agents/README.md) for Laravel and the TALL stack —
architect, full-stack, backend, Livewire, Pest, security, devops, git, PM, and
WordPress on Roots. Independent from the scripts; take one, both or neither.

## Requirements

macOS with [Herd](https://herd.laravel.com) or Valet, or neither — site
registration is skipped if it finds no tool. `bash`, `git`, `php`, `composer`,
and the client for your database. Tested against PostgreSQL and Herd; MySQL
and Valet are supported by design but less travelled, so issues are welcome.

## Status

Extracted from a setup that runs daily on client Laravel projects. The shape
is stable; the breadth is not — it has mostly been exercised on one stack.
Issues and pull requests welcome, especially "it does not fit my stack".

MIT.
