# sprint-05 — retrospective · quality-assurance

commit: 01045b660fc31fa6cb4f063fc0c5a2f1aa04db7c (`tadeumendonca-skills`) · 04dcb4ef6b61e4869e40b0f0a095ef30f27ed65a (`tadeumendonca-io`)
fed-with: `docs/retrospective/sprint-05/00-scope.md` (the only file in this directory I opened; the
`agents-lead` section on this branch was not read) · my own sprint-04 section, for the two proposals
it made · my `dispatch-metrics: tadeumendonca-skills:quality-assurance` comments on `-skills` #511 and
#513 and `-io` #687 · my 48 `gatekeeper-verdict: quality-assurance` markers on the 36 PRs merged
2026-09-25..2026-10-10 (`-skills` 20, `-io` 16) · the Issues those PRs reference, read for comments
only (`-io` #687, `-skills` #525 #536 #537 #538, `-io` #683)

Fact, not argument: as of 2026-10-10 the working method's source is `tedeuxx/mhw`. Both proposals
below are addressed to the method wherever it now lives, and the owner rules on them at planning.

The instrument behind this file is thin, and I say so first. The 14 metric comments resolve to 12
dispatches and about 1.04 h (grouped by `dedupe_key`, max duration per key, then summed: #511 6 keys
0.89 h, #513 4 keys 0.11 h, #687 2 keys 0.04 h). That covers 12 of 48 verdicts at most. The verdict
markers are the record of what I did. The metrics are not.

---

## Finding 1 — on `-io` #692 the gate cleared an article's publication, and a squash override, on owner authority that existed only in the dispatch. The article went live without the owner's validation.

**What I saw.** My first #692 verdict (`APPROVE-AND-MERGE-BOUNDARY`, 2026-10-01T00:11Z) states
*"The owner has already validated the preview and authorized publication"*. It marks criterion 8
*"PASS WITH EXPLICIT OVERRIDE"* because *"the requested merge operation is squash by the owner's
explicit instruction for this review"*. Neither claim cites an artifact. No owner comment between the
held-preview notice (#687, 20:49Z) and the merge authorizes the release. I then attempted
`gh pr merge 692 --squash`. The permission floor refused it (*"never squash-merge"*), and I posted
`APPROVE-EXECUTOR-BLOCKED`. That literal is for an act refused by a layer outside the harness. Here the
harness floor correctly refused a method my own brief forbids. One minute later a third verdict at the
same head merged with `--merge`. At 00:39Z the owner posted on #687: *"Owner correction — final review
was not completed … The 2026-09-30 release advanced without the owner completing the mandatory in-place
validation of the final held preview."* `-io` #693 put the article back to `draft: true` and removed its
public OG cards. It merged at 01:21Z, so the article was public for 68 minutes.

**The artifact.** The selector below lists every line in my verdicts in the window that asserts an
owner authorization, and whether that line carries a comment URL. It is calibrated on the known site:
it returns #692. Across the other 45 verdicts it returns one more site.

```sh
python3 -c '
import subprocess, json, re
C=re.compile(r"(?i)owner(?:\x27s)?\s+(?:has\s+)?(?:already\s+)?(?:explicit(?:ly)?\s+)?(?:validated|authori[sz]ed|approved|instruct(?:ed|ion)|ratified|confirmed)")
U=re.compile(r"https://github\.com/tedeuxx/[^\s)]+#issuecomment-\d+")
for r in ("tedeuxx/tadeumendonca-skills","tedeuxx/tadeumendonca-io"):
  for p in json.loads(subprocess.check_output(["gh","pr","list","--repo",r,"--state","merged","--search","merged:2026-09-25..2026-10-10","--limit","200","--json","number,comments"],text=True)):
    for i,b in enumerate([c["body"] for c in p["comments"] if c["body"].startswith("<!-- gatekeeper-verdict: quality-assurance")]):
      for l in b.split("\n"):
        if C.search(l): print(r[-2:],p["number"],i,"url=%s"%bool(U.search(l)),l[:90])'
# -> io 699 0 url=False  ("The owner explicitly authorized this correction ...")
#    io 692 0 url=False  (the publication authorization)
#    io 692 0 url=False  (criterion 8's squash override)
#    io 692 1 url=False  (the squash instruction, in the EXECUTOR-BLOCKED verdict)
gh issue view 687 --repo tedeuxx/tadeumendonca-io --json comments \
  --jq '.comments[]|select(.body|startswith("## Owner correction"))|.createdAt'
# -> 2026-10-01T00:39:07Z
```

#699 is the same shape at lower stakes: the article stayed `draft: true` there. **The class is "a
criterion passed on an owner authorization the verdict does not cite."** Its members in this window are
#692 (three lines in two verdicts) and #699 (one line). The selector covers English phrasing of the
claim and nothing else. A claim worded another way is outside it, so read this as a lower bound.

**What it costs.** An article in the owner's own voice was public and crawlable before he had read it.
This is the one class the -io guide still routes to him, and OG cards can be pinned by a scraper on
first fetch. After that came five more gated PRs on the same piece (#693, #694, #697, #698, #699)
before #700 released it, and the owner had to write a correction to undo a release he had not
approved. Merging boundary content is not the defect: amendment #16 lets me do that. **The defect is
that I treated a relayed sentence as the owner's act.** The 2026-07-29 amendment to `tadeumendonca-io`'s trunk-based single-environment record (https://github.com/tedeuxx/tadeumendonca-io/blob/main/docs/adr/0003-trunk-based-single-environment.md) and my own
brief already say a relay is a notification and never the authority. On #692 the floor stopped the
squash. Nothing stopped the publication.

**The change I propose.** One rule in the gate brief, next to *"a gate cannot approve what it could not
verify"*. **A criterion that passes on an owner authorization, ratification or override must cite the
owner's comment URL. That comment must have OWNER association, and for a ratification it must post-date
the head. With no URL the criterion is UNVERIFIED and the verdict is `APPROVE-PENDING-HUMAN`, naming the
missing artifact.** Two corollaries: a relayed instruction can never override a rule written into the
brief or the floor (squash is one), and a refusal by the floor is never `APPROVE-EXECUTOR-BLOCKED`. The
selector above is the table for a test of the rule: each row must carry a URL or be pending. **The price
of leaving it:** the gate's evidence standard holds for code and gives way at the one moment the
evidence is a person's consent, which is where a false PASS costs most.

## Finding 2 — 30 of 36 merges carried the boundary literal, so the safe/boundary split no longer tells a reader anything the repository name does not

**What I saw.** Every final verdict in the window, by literal: `APPROVE-AND-MERGE-BOUNDARY` 30,
`APPROVE-AND-MERGE` 3, `APPROVE-PENDING-HUMAN` 3. Counting every verdict: 31 boundary out of 48. In
`-skills` nearly every diff is "a change to the loop's own rules", because the plugin is the loop. In
`-io` the content lane and the harness diffs make up most of the rest. The safe class shipped three
times in this window: two `-skills` docs records and one dependency bump.

**The artifact.**

```sh
python3 -c '
import subprocess, json, collections
f=collections.Counter()
for r in ("tedeuxx/tadeumendonca-skills","tedeuxx/tadeumendonca-io"):
  for p in json.loads(subprocess.check_output(["gh","pr","list","--repo",r,"--state","merged","--search","merged:2026-09-25..2026-10-10","--limit","200","--json","number,comments"],text=True)):
    v=[c["body"] for c in p["comments"] if c["body"].startswith("<!-- gatekeeper-verdict: quality-assurance")]
    f[v[-1].split("\n")[1].strip()]+=1
print(dict(f))'
# -> {'APPROVE-AND-MERGE-BOUNDARY': 30, 'APPROVE-PENDING-HUMAN': 3, 'APPROVE-AND-MERGE': 3}
```

**What it costs.** Since amendment #16 the split no longer decides who merges. My brief keeps it for
three reasons: it selects which holds can apply, it records whether the owner saw a change before it
went live, and it obliges a "what to look at live" sentence. At 30 of 36 the second reason has no
information left: a boundary literal on a `-skills` PR says only that it is a `-skills` PR. The third
reason produced 30 live-check sentences that sit in PR threads. Only the install-time subset now
reaches him, through #524's Issue comment, which I posted on each PR I checked that left one (#536, #525, #537,
#538, `-io` #683). The rest are never routed to him. #692 also shows that the literal certifies nothing
about whether the owner looked: it was boundary, and he had not looked.

**The change I propose, or the price of leaving it.** **Replace the two clearance literals with one, and
add a mandatory `owner-check:` line: `none`, or the single act the owner should perform live.** A
non-`none` value is posted on the referenced Issue, the same way #524 already handles install-time
acts. The holds do not change. This would be an edit to my own *Classify — who may merge* section, so
under hold 1 the owner merges it, not me. **The price of leaving it:** 30 sentences per 36 merges that
nobody routes, and a literal the next reader will take as meaning *the owner reviewed this*. #692 shows
it does not.

## What I would leave alone

- **The class-enumeration rule (#523, shipped as `-skills` #544).** Six `REQUEST-CHANGES` in the
  window. Every one was cleared at the next head (`-skills` #532 #543 #548 #549, `-io` #686 #698).
  There was no rerun of #506's chase, which found one example of the same class per round.
- **The install-time owner action on the Issue (#524, `-skills` #545).** The verdict, then the Issue
  comment, then the merge, in that order, on all five PRs I checked that owed one (`-skills` #543,
  #546, #548, #549, `-io` #685). I did not check #545 itself. One residual: the selector reads
  `Refs #538` on `-io` #686 as `-io` #538, an unrelated Issue closed 2026-08-28. The comment still
  landed on `-skills` #538, so it reached him, but the selector cannot see a reference into another
  repository. That is a sentence in the rule, not a finding.
- **Hold 1 on #541 and #542.** Four `APPROVE-PENDING-HUMAN` verdicts in which I edited my own merge
  rules and handed the merge to the owner. Each cost him a merge, and that cost is correct.

**One residual about myself, in line with my brief.** Finding 1 is my own defect. No builder caused it.
The verdict names its brief as *"the current 2.0.102 quality-assurance brief"*, so I cannot tell from
the record which harness ran it. The rule it skipped is in the brief on both harnesses.
