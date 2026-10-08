# Plain git, no ADE

The kit needs no ADE at all. From a worktree you just created:

```sh
git worktree add ../myapp-billing -b billing
cd ../myapp-billing
~/.laravel-worktree-kit/bin/worktree-setup
```

and when you are done with it:

```sh
~/.laravel-worktree-kit/bin/worktree-teardown
cd -
git worktree remove ../myapp-billing
```

With no ADE variables set, the kit finds the main checkout through
`git rev-parse --git-common-dir` and names the worktree after its branch.

This is also how to debug a hook that is not behaving: run the script by hand
in the worktree and read what it prints, instead of guessing from an ADE's log
pane.
