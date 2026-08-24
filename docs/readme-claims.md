# The README claim registry — what each labelled section claims, and what falsifies it

**This file holds the falsifiers. `README.md` holds the claims.** A section of the README carries a
marker naming an **id** and a **class**; the entry under that id, here, says what would prove the
section wrong. The split is the containment: **a command this repository executes never lives in the
README**, so an edit to the front door cannot introduce one.

The defect this exists against is **a claim published with no falsifier beside it** — not *a number
that disagrees with a directory listing*, which `hooks/scripts/inventory-counts.test.sh` already
caught. Measured on [#324](https://github.com/tedeuxx/tadeumendonca-skills/issues/324): the three
drift examples that justified the work all sat in the **authored** half of the README, and the count
arms were green through every one of them.

## The four classes

| class | what it means | what the gate does |
|---|---|---|
| `VERIFIED` | A **local, deterministic** command over tracked files, plus its expected output, declared here. | **Runs it and compares.** Output ≠ `expects` is red. |
| `MEASURED` | A command that cannot run in CI — it reaches the network, or a machine this repository does not have. | **Shape only**: the entry declares a date, and the README section carries a fenced block and an ISO date. The command is never run. |
| `DERIVED` | An existing arm of `inventory-counts.test.sh` already owns the fact. The entry names the arm. | Asserts the named arm exists **as a two-sided assertion** — a label appearing in both an `ok` and a `bad` branch. |
| `JUDGEMENT` | Authored, unfalsifiable, and declared so. | Asserts only that it claims no falsifier: an entry declaring `JUDGEMENT` while carrying a command or an arm is red, because it should have declared one of the other three. |

**`VERIFIED` and `MEASURED` split on where the command can run, never on how important the claim is.**
The rule, applied in that order:

| the command reads | class |
|---|---|
| tracked files in this repository — `grep`, `find`, `ls`, `jq`, `wc` | `VERIFIED` |
| the network — `gh issue list`, `gh pr list`, an HTTP fetch | `MEASURED` |
| a machine CI does not have — the Kiro bundle, an AWS account, the owner's laptop | `MEASURED` |

The network row is not a convenience. **A red caused by an API outage teaches everyone to ignore
red**, and a gate people have learned to ignore is worse than one that never ran, because its green is
still being counted.

## Containment — what the gate is allowed to execute, and what that cannot hold

Running a command that came out of a markdown file is executing shell in CI. Three containments, and
they are gated themselves (`inventory-counts.test.sh`, the *README claim contract* arms) rather than
being decoration:

1. **The command lives here, never in `README.md`.** The README marker carries an id and a class and
   nothing else. This is the containment that matters most, because the README is the file most
   likely to be edited by someone who is not thinking about CI at all.
2. **A closed allow-list of command heads.** Every stage of the pipeline must begin with one of:
   `grep` · `find` · `ls` · `jq` · `wc` · `sort` · `uniq` · `head` · `cat` · `tr` · `basename`.
   A head outside the set is refused before anything runs.
3. **A character allow-list, not a metacharacter denylist.** The command must match
   `[A-Za-z0-9 ._/*'"|=:+,^#-]` end to end — so `$`, backtick, `;`, `&`, `<`, `>`, `(`, `)`, `{`, `}`,
   `\`, `!` and newline cannot appear at all. Command substitution, redirection and chaining are
   unreachable rather than forbidden. Plus a token denylist for the two heads whose *flags* are the
   hole: `-exec`, `-execdir`, `-ok`, `-okdir`, `-delete`, `-fls`, `-fprint`, `-fprintf`.

**`awk` and `sed` are deliberately absent from the allow-list**, and their absence is the argument for
the whole shape: they are general-purpose languages, so a head-only allow-list containing them would
contain nothing (`sed -i` writes files, `awk`'s `system()` runs anything). A head is a meaningful unit
of containment only for programs whose flags are enumerable, which is why rule 3 exists to cover the
two — `find` and `grep` — where it nearly isn't.

**What the containment cannot hold**, named because this column is the most transferable thing here:

- **It binds a command to a number, never a number to a sentence.** The gate compares stdout to
  `expects`. Nothing reads the prose around the marker. A section whose sentence contradicts its own
  entry passes — the reviewer is the only instrument for that, exactly as `propósito` is unfalsifiable
  in `docs/blueprint-registry.md`.
- **It does not bound resources.** No timeout, no output limit. `find / -name x` is refusable by rule
  3 only because of what it *contains*, not because of what it *costs*; a slow but well-formed command
  hangs CI and this file has no answer for it.
- **`VERIFIED` reads the working tree, not the index.** An untracked file can change a `find` or
  `grep -r` result, so a claim can be green locally and red in CI, or the reverse. Every command here
  is scoped to a tracked directory to keep the window small; nothing enforces that it stays scoped.
- **`DERIVED` asserts the arm exists, never that it is the arm that owns the claim.** A marker naming
  a real but unrelated arm passes.
- **`MEASURED` is a shape check and says nothing about truth.** That is the whole of its contract, and
  it is still worth having: the Kiro figures at `README.md`'s Power-export section went stale with no
  fenced command beside them, and a shape check is what would have made the absence visible.
- **The class itself is authored.** Nothing stops a `VERIFIED`-able claim being filed as `JUDGEMENT`
  to avoid the work. The coverage table below makes an *unlabelled* section visible; it cannot make a
  *mislabelled* one visible.

## Coverage — which sections carry a class, and which do not

**`partial` is declared, never left to look finished**, and the gate reads this table in both
directions: `complete` with an unlabelled section reddens, **and `partial` with nothing unlabelled
reddens too**, because an under-claiming declaration goes stale in exactly the silence that finishing
the last section produces.

| surface | enumerated from | claimed |
|---|---|---|
| `readme-section` | every `## ` heading in `README.md` | partial |

**What `partial` means here, exactly.** Five of the eighteen top-level sections carry a marker. The
five were chosen to exercise all four classes and to sit on the two claims that were measurably false
at `4ad4dfc` — not because they are the five most important sections. **Labelling the remaining
thirteen is not this slice**, and padding the table to `complete` with thin `JUDGEMENT` markers would
be the failure the class set exists to prevent: `JUDGEMENT` is a declaration that no falsifier exists,
and using it to clear a coverage row makes it a declaration that nobody looked.

## Ids

**Zero-padded, assigned once, never reused, never re-sorted** — the same discipline
`docs/blueprint-registry.md` states for its rows, and reused rather than re-invented so a reader who
has learned one has learned both. A section reflow changes nothing; retitling a heading changes
nothing. **An id leaves this registry only as a tombstone under `## History`, never as an absence.**

The id is the reason the sync prompt this contract exists to make writable *is* writable: a second run
over another harness's README reports *ids added, ids removed, ids whose class changed*, and nothing
else. Keyed on prose, it could only re-emit the file.

**To find a claim's section:** `grep -n 'claim id=NNNN' README.md`. There is deliberately no heading
text in an entry — storing it here would rebuild the coupling the ids exist to break.

---

## 0001 · what the repository ships, and how many personas preload from `skills/`

- **class:** VERIFIED
- **command:** `find agents -maxdepth 1 -name '*.md' -type f | wc -l`
- **expects:** `7`
- **limit:** It counts brief **files**, not personas the roster claims — a brief added and never registered anywhere still moves this number, and a persona described in prose with no file does not. It also says nothing about the section's actual assertion, which is that those briefs preload only paths under `skills/`; that half is unfalsified here.

## 0002 · what travels to another harness, and who reads the gate's own verdict

- **class:** VERIFIED
- **command:** `grep -lF gatekeeper-verdict hooks/scripts/session-wip.sh hooks/scripts/zombie-loop-detect.sh | wc -l`
- **expects:** `2`
- **limit:** It cannot tell **mentioning** the marker from **reading** it — a file that only names it in a comment counts. And it names its two files rather than discovering them, so a **third** reader appearing is invisible; what it does catch, which is the direction that was false, is a reader **disappearing** or never having existed.

## 0003 · the Kiro Power export and the element-by-element gap

- **class:** MEASURED
- **command:** `/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" /Applications/Kiro.app/Contents/Info.plist` — the first line of the fenced block the section already carries; the other two read `product.json` and the `kiro-agent` extension manifest out of the same installed application
- **on:** 2026-08-23
- **limit:** CI has no Kiro install, so nothing here runs. The shape check asserts that the section carries a date and a fenced command and **nothing about whether the figures are still true** — the honest reading of a green is "this claim is dated and re-runnable by someone with the machine", never "this claim holds".

## 0004 · the skill library and what each persona preloads

- **class:** DERIVED
- **arm:** `README skill table`
- **limit:** The arm owns the **table**, in both directions — every skill has a row, every row names a real skill. It owns none of the surrounding prose about *why* a persona preloads what it does, and it cannot see a row whose `WIELDER` cell is wrong, only one whose skill does not exist.

## 0005 · the problem this harness is built against

- **class:** JUDGEMENT
- **limit:** Unfalsifiable by construction, and that is the declaration rather than an apology for one. Whether trust is really the bottleneck, and whether these three failures are the ones that matter, is the owner's argument — a reader who disagrees has nothing to run, and should be told that plainly instead of being handed a number that looks like evidence for a claim it does not test.

---

## History

No id has been abandoned. A row here carries the bare four-digit id, what the claim asserted, and why
it was abandoned — written **bare**, never `ADR`-style prefixed, for the same reason the registry's
tombstones are: a prefixed number in a tracked file reads as a live citation to the next gate that
greps for one.

| id | what it claimed | why it was abandoned |
|---|---|---|
