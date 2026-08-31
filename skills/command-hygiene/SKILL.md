---
description: Apply the platform's working-files and shell discipline in any `<project>` repo — where scratch files go, one atomic Bash call per invocation, the `gh --repo` flag position, and `--body-file` for any multi-line PR/issue body. Use whenever a persona writes a working file, runs a shell command, or composes a PR/issue comment. Not for the loop's state machine (see agents-configuration) or what a merge verdict must contain (see quality-gates).
purpose: state the working-file and shell discipline once, because the same procedure copied into every brief is exactly what a preloaded skill exists to remove
---

Apply this working-files and shell-command discipline in any `<project>` repo, for any persona dispatched
into it.

Context: $ARGUMENTS

## Why this is one skill

Two behaviors — where scratch files go, and how a shell command avoids tripping the permission matcher —
were independently restated, near-verbatim, in all five agent briefs the roster held at #225 (a content
drafter landed later that same day, making six; its reviewing pair at #317, making seven). A real skill is preloaded once and referenced; the same
procedure copy-pasted into five files is what it looks like when that fails (#225). Both behaviors are transversal — every persona that writes a file or runs `Bash` needs
them — so they're one preload, not a per-persona restatement.

## Working files — where they go

**Every scratch file a persona writes goes in the session scratchpad** — the path the harness hands you
at session start, session-specific and outside every tracked tree — for commit messages, PR/issue
bodies, drafts, verdict text.

**There used to be a repo-root `<repo-root>/.scratch/` directory here instead, retired at #245.** It
existed on the belief that WHERE a scratch file lived affected permission friction; #244 measured
directly that it does not — the friction was always the shell-redirect pattern used to write the file,
not its destination, and that is now denied mechanically regardless of location (see "Never redirect
stdout" below). Carrying a repo-side scratch directory bought nothing that fix didn't already buy, and
cost a sweep hook (`session-scratch.sh`) and a rule that lived only in agent-brief prose — exactly the
shape a preloaded skill exists to remove. If a brief still names `.scratch/`, that is stale and should be
fixed to point here instead.

**`Write` is the route — never a shell redirect (`>`/`>>`) into a stub file.** An `Edit` onto a file that
already exists is the other valid route where `Write` doesn't fit. If the file cannot be written by any
tool-granted route available, that is a posting failure to report as one — not a reason to fall back to
an inline argument that strips backticks and `$`, and not a reason to reach for `>` because it is
quicker.

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

**Never redirect stdout to create a file (`>`/`>>`) — mechanically enforced (#244), not advisory.**
`command > path` prompts a human regardless of destination — `.scratch/`, the session scratchpad,
anywhere — and regardless of whether `command` itself is allowlisted; measured directly, repeatedly, in
this session (`git show … > file`, `gh pr diff … > file`, a generator script's own stdout). Guidance
alone did not hold — the pattern kept recurring after it was already diagnosed — so
`hooks/scripts/permission-guard.sh` denies it outright now. Two routes cover everything `>` was used
for: content the agent is composing itself goes through `Write`; content that is a command's own stdout
is obtained by running the command *without* the redirect (the output already returns to the caller) and
`Write`-ing it from there if it needs to persist. `2>&1` / `1>&2` / `>&2` (redirecting one stream to
another) are unaffected — they create no file.

## `--body-file`, always, for anything longer than one line

**Get the content into a file in the session scratchpad, then post it with `--body-file <path>`** — `gh pr comment`,
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
