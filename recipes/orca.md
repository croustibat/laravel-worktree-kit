# Orca

Orca runs a script after it creates a worktree and another before it archives
one. Both live in **Settings → Repository → Hooks**, per repository.

**Setup Script**

```sh
~/.laravel-worktree-kit/bin/worktree-setup
```

**Archive Script**

```sh
~/.laravel-worktree-kit/bin/worktree-teardown
```

That is the whole integration — the scripts work out where they are from the
environment Orca gives them.

## What Orca exposes

Three variables, readable in the hook:

| Variable | What it holds |
|---|---|
| `ORCA_ROOT_PATH` | the main checkout |
| `ORCA_WORKTREE_PATH` | the worktree being set up |
| `ORCA_WORKSPACE_NAME` | the name you gave the worktree |

These are documented in the Settings panel rather than in the online docs, so
they are easy to miss. `ORCA_WORKSPACE_NAME` is the one that matters: it is
what names your site and your database, and it keeps a worktree's identity
stable even when the branch is renamed.

## Shared paths

Orca can share ignored directories into each worktree, which saves a full
`composer install` and `npm install` per worktree. Three mechanisms, and they
do different things:

- **Worktree Shared Paths** (Settings → Repository) — APFS clone when it can,
  symlink otherwise.
- **`worktree.sharedDirectories`** in `orca.yaml` — the same, committed.
- **`.worktreeinclude`** — a real copy, for files that must not be shared,
  like `.env`.

Share `node_modules` and `vendor`, copy nothing else. If you share `vendor`,
drop `WTK_BUILD=0` and let `composer install` run anyway — it is fast when the
directory is already populated and it keeps the autoloader honest.

## Running one from the CLI

```sh
orca worktree create --name billing-audit --agent claude --json
```

The setup hook fires on creation, so an agent dispatched this way lands in a
worktree that already has its site, its database and its ports.
