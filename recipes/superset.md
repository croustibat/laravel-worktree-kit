# Superset

Superset reads `.superset/config.json` at the root of the repository.

```json
{
  "setup":    ["~/.laravel-worktree-kit/bin/worktree-setup"],
  "teardown": ["~/.laravel-worktree-kit/bin/worktree-teardown"]
}
```

Turn on *Wait for workspace setup before starting agents* in Settings, or the
agent starts talking to a half-built worktree.

## What Superset exposes

`SUPERSET_ROOT_PATH`, `SUPERSET_WORKSPACE_NAME` and `SUPERSET_WORKSPACE_PATH`.
The kit reads the first two.

## Config cascade

Superset layers several config files, which is useful on a client repository
you would rather not commit your own setup into:

```
~/.superset/projects/<repo-path>/config.json   # yours, highest priority
<worktree>/.superset/config.json
<repo>/.superset/config.json                   # the project's
```

There is also `config.local.json`, gitignored, with a `before`/`after` split:

```json
{ "setup": { "before": ["~/.laravel-worktree-kit/bin/worktree-setup"] } }
```

## Teardown actually runs

Superset runs `teardown` even when the workspace is deleted from the CLI, the
SDK or over MCP; a failure comes back as a warning rather than blocking the
delete. That is the behaviour you want here — a database left behind is
cheaper than a workspace you cannot remove.
