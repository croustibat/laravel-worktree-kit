# Laravel subagents

Ten Claude Code subagents for a Laravel and TALL stack codebase. Drop them in
and `claude` will route work to the right one on its own — you do not call
them by name.

```sh
mkdir -p .claude/agents
cp ~/.laravel-worktree-kit/agents/*.md .claude/agents/
```

Project-scoped in `.claude/agents/`, or user-scoped in `~/.claude/agents/` if
you want them on every repository.

| Agent | Model | Reach for it when |
|---|---|---|
| `laravel-architect` | opus | an architecture decision, an ADR, a package choice, a design review |
| `tall-fullstack` | sonnet | a feature end to end: migration, model, action, Livewire, Blade, tests |
| `laravel-backend` | sonnet | APIs, Eloquent, queues, jobs, query optimisation |
| `livewire-frontend` | sonnet | UI, Blade components, Alpine, responsive, accessibility |
| `qa-pest` | haiku | writing tests, test strategy, static analysis |
| `security-laravel` | opus | audits, auth hardening, GDPR |
| `devops-laravel-cloud` | opus | deployment, pipelines, server config, runbooks |
| `git-expert` | opus | delicate git, conflicts, history forensics, purging a secret |
| `project-manager` | sonnet | breaking down epics, prioritising, planning, status |
| `wordpress-roots` | opus | WordPress on Bedrock, Sage, Acorn — never classic WP |

## About the models

The assignment is deliberate, not decorative. Anything that *decides* — an
architecture, a security verdict, a destructive git operation — gets opus,
because being wrong there is expensive and rare. Anything that *produces*
within an already-decided frame gets sonnet. `qa-pest` gets haiku because
writing a Pest test against an existing shape is the most mechanical work in
the list, and it is also the agent you call most often.

Change them to suit your own budget: the `model:` line in each file is read by
Claude Code and nothing else here depends on it.

## Why they are opinionated

These prompts assume a specific way of working — modular monolith over
microservices, framework conventions over clever abstractions, YAGNI as a
feature, and a solo or small-team context where shipping beats elegance. The
architect agent will push back on complexity you cannot maintain alone. If you
work in a twelve-person team on a service mesh, rewrite them; they are plain
markdown.
