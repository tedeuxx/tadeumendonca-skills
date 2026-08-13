---
description: Apply the platform's working-files and shell discipline in any `<project>` repo — where scratch files go, one atomic Bash call per invocation, the `gh --repo` flag position, and `--body-file` for any multi-line PR/issue body. Use whenever a persona writes a working file, runs a shell command, or composes a PR/issue comment. Not for the loop's state machine (see harness-engineering) or what a merge verdict must contain (see verification-and-gates).
---

Apply this working-files and shell-command discipline in any `<project>` repo, for any persona dispatched
into it.

Context: $ARGUMENTS

## Why this is one skill

Two behaviors — where scratch files go, and how a shell command avoids tripping the permission matcher —
were independently restated, near-verbatim, in all five current agent briefs. A real skill is preloaded
once and referenced; the same procedure copy-pasted into five files is what it looks like when that
fails (#225). Both behaviors are transversal — every persona that writes a file or runs `Bash` needs
them — so they're one preload, not a per-persona restatement.

## Working files — where they go

**Every scratch file a persona writes goes in `<repo-root>/.scratch/`** — commit messages, PR/issue
bodies, drafts, verdict text. Not `/tmp`, not a session scratchpad directory the harness may offer, not a
stray path in the tracked tree. `session-scratch.sh` empties `.scratch/` at the start of each new
session; it reaches nowhere else, so a file written elsewhere outlives every sweep and is invisible to
the owner.

**The harness may say otherwise**, naming a session scratchpad under `/tmp` and calling it the place for
temporary files. **This rule overrides that.** The instruction exists because it was once absent: on
2026-08-06, subagents wrote working files to the harness scratchpad all day, correctly, since it was the
only instruction they had been given.

**Any tool grant reaches the file** — `Write` is the direct route where a persona holds it;
`printf '%s' … > <path>` or an `Edit` onto a stub file are equally valid where it doesn't. How the file
gets written is not part of the rule; that it lands in `.scratch/` is. If the file cannot be written by
any route available, that is a posting failure to report as one — not a reason to fall back to an inline
argument that strips backticks and `$`.

## Command hygiene — one atomic Bash call

**Run one atomic command per `Bash` call.** Do NOT chain with `&&` / `;` / pipes, and avoid `$(...)` /
backticks and `VAR=x cmd` env-var prefixes — the permission matcher can't decompose a compound or
substituted command, so it prompts a human even for an otherwise-allowlisted tool. Prefer the repo's own
scripts (`npm --prefix <app> run <script>`, a project's own test entrypoint) over inline env-prefixed
commands. A few extra calls is the price of zero permission prompts.

**`git -C <dir>` and `npm --prefix <dir>`, never `cd X && …`.** The workspace root is not a repository
itself in a multi-repo layout, and a `cd` compound both chains commands (tripping the rule above) and
risks leaving a shell in the wrong directory for the next call.

**Target another repo with `gh <subcommand> --repo <owner/repo>`, never `gh -R <owner/repo> <subcommand>`.**
The permission matcher reads a command **prefix**, and an allowlist is typically spelled per-subcommand
(`Bash(gh issue view:*)`); a flag placed *before* the subcommand changes the prefix to `gh -R`, which
matches none of them — a working, read-only command that stops for a human over its punctuation alone.
Put the flag after the subcommand and it matches.

## `--body-file`, always, for anything longer than one line

**Get the content into a file in `.scratch/`, then post it with `--body-file <path>`** — `gh pr comment`,
`gh pr create`, `gh issue create`, `gh issue comment`, any command taking a `--body`/`--message` flag with
multi-line or backtick-bearing content. This has no per-case exception: backticks and `$` are silently
eaten from an inline `--body` string by shell interpolation, and this platform has paid for that failure
more than once in a single session before the rule was written down. `--body` is not a fallback — if the
file genuinely cannot be written by any route, that's a posting failure to report as one, not a prompt to
start deleting characters until the inline command survives the shell.

## Using this skill

Preload this in any persona's `skills:` list that writes files or runs shell commands — which, in
practice, is every persona in the roster. When a brief's own prose restates any of the three behaviors
above, that's duplication this skill exists to remove; the brief should cite this skill instead of
re-deriving the rule.
