# OpenChamber

OpenChamber reads `.openchamber/project.json`, committed with the project.

```json
{
  "setupWorktree": ["~/.laravel-worktree-kit/bin/worktree-setup"],
  "setupWorktreeWait": true
}
```

`setupWorktreeWait` holds the agent until setup finishes. Leave it on.

## What OpenChamber exposes

One variable, `ROOT_PROJECT_PATH`, pointing at the main checkout. There is no
workspace name, so the kit falls back to the branch — which means renaming a
branch renames its site and its database. Tear down before you rename, or
accept an orphan.

## The trust prompt

The first time a setup command that came from the repository is about to run,
OpenChamber shows you the exact text and asks. A `git pull` that changes the
command asks again.

Worth knowing even if you use another ADE: a setup hook committed in a
repository is arbitrary code that runs on your machine every time an agent
opens a worktree. On your own projects that is fine. On a client repository
you did not write, read the hook before you let it run.

## No teardown

OpenChamber documents no destroy hook. Run `worktree-teardown` by hand before
removing a worktree, or the site and the database stay behind.
