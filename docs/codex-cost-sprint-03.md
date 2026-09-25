# Where sprint-03's Codex tokens went — a four-part breakdown (#511)

**Sprint-03 was the first sprint run inside Codex, and it used up the owner's Codex allowance.** The
weekly usage meter went from 23% to 100% while it ran. #511 was filed with a headline of **352.7M
tokens**. This page splits that spend into the four parts #511 names: embedded preload, re-read,
per-turn re-send and polling. It gives the command behind every figure, chooses a change for each
part, and states the premise nobody has measured: how Codex counts cached tokens against the limit.

**The source is read-only**: the rollout logs Codex writes under `~/.codex/sessions/2026/09/23/` and
`~/.codex/sessions/2026/09/24/`, 51 files. Nothing here writes to `~/.codex`. The commands run only
on the machine that holds those logs. Anywhere else the glob matches nothing, and each command either
prints empty counters or fails. **An empty result there means nothing was scanned. It does not mean
the spend was zero.**

## The headline needs one correction before any split

| figure | tokens | how to read it |
|---|---|---|
| sum of the last `total_token_usage` of all 51 rollouts | **352,821,257** | the naive sum |
| the same, over the 50 that existed when #511 was filed | 352,744,366 | #511's 352.7M. The 51st started at 13:45 on 09-24, after intake, and carries 76,891 tokens |
| **the parent's history, replayed into a forked child** | **14,186,577** | **counted twice**. When Codex forks a sub-agent from its parent, the child's log begins with a replay of the parent's token events, and its running total starts from the parent's. Five of the 16 persona instances were forked |
| **tokens actually spent** | **338,634,680** | the base for every percentage below |

The replay shows up as a block of token events at the start of each forked child. Every event in the
block carries the same one-second timestamp as the child's first line, and the block's cumulative
total equals the parent's total at the moment of the fork. For the long agents-lead instance, the
parent root session's last total before the fork was 1,080,174 tokens, and so was the child's
inherited total:

```
python3 -c "
import json, glob, os
p = [(o['timestamp'], o['payload']['info']['total_token_usage']['total_tokens']) for l in open(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/23/*27736a.jsonl'))[0])
     for o in [json.loads(l)] if isinstance(o.get('payload'), dict) and o['payload'].get('type') == 'token_count' and o['payload'].get('info')]
print('parent, last total before 21:05:54Z:', [t for ts, t in p if ts < '2026-09-23T21:05:54'][-1])
c = [json.loads(l) for l in open(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/23/*8bdb93.jsonl'))[0])]
print('child, replayed total:', max(o['payload']['info']['total_token_usage']['total_tokens'] for o in c
      if o['timestamp'][:19] == c[0]['timestamp'][:19] and isinstance(o.get('payload'), dict) and o['payload'].get('type') == 'token_count' and o['payload'].get('info')))
"
# -> parent, last total before 21:05:54Z: 1080174
# -> child, replayed total: 1080174
```

## The breakdown

| # | component | tokens | share of spent | the change chosen | owner | status |
|---|---|---|---|---|---|---|
| 1 | **embedded preload** — the persona profile, brief plus every preload, sent in full on every request | 115,919,635 | **34.2%** | trim what a Codex profile embeds, starting with `agents-configuration` | agents-lead, in `scripts/codex-agent-build.py` | **deferred** — see §1 |
| 2 | **re-read** — tool output repeating text the profile or `AGENTS.md` already carries, re-sent on every later request until a compaction | 15,689,329 | **4.6%** | never ask a profile to re-read what it carries, and never re-read it unprompted | the orchestrator and every profile | **implemented in this repository only** — `AGENTS.md` rule 23; the `-io` copy is owed, see below |
| 3 | **per-turn re-send** — the rest of each request: the conversation so far plus the harness's own prefix | 168,382,786 | **49.7%** | short-lived instances: one task per instance, and a new task gets a new instance | agents-lead, for the dispatch protocol | **deferred** — see §3 |
| 4 | **polling** — every request made only to read the result of a `wait_agent`, `sleep` or `wait` | 38,043,267 | **11.2%** | one blocking wait per dispatch, with the longest timeout the tool accepts, and no sleep loops | the orchestrator | **implemented in this repository only** — `AGENTS.md` rule 7; the `-io` copy is owed, see below |
| — | output tokens outside polling | 515,423 | 0.2% | none — not a lever | — | — |
| — | five small rollouts that record a total only | 84,240 | 0.0% | none | — | — |

**The two IMPLEMENTED rows do not reach the sessions this sprint ran in, and that is measured rather
than assumed.** Every one of the 45 rollouts that recorded a workspace state loaded the `AGENTS.md`
of **`tadeumendonca-io`**, because the sessions were rooted there. This page's edit is to this
repository's `AGENTS.md`, which such a session does not load. `tadeumendonca-io`'s `AGENTS.md` carries
no polling or re-read rule, not even the pipeline half of rule 7. **Until the same two obligations
land there, in that repository's own merge request, a Codex sprint rooted in `-io` runs exactly as
this one did.** That is a follow-up for the orchestrator to route; it is not done here.

```
python3 -c "
import json, glob, os, collections
c = collections.Counter()
for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/2[34]/*.jsonl'))):
    for l in open(f):
        o = json.loads(l)
        if o.get('type') == 'world_state':
            c[os.path.basename((o['payload']['state'].get('agents_md') or {}).get('directory') or '')] += 1; break
print(c)
"
# -> Counter({'tadeumendonca-io': 45})
```

**The rows add up to the independent total**: 338,634,680 spent plus 14,186,577 replayed is
352,821,257, the naive sum. **Cached input is 96.86% of all input** (327,372,672 of 337,985,527).

**By role**, spent tokens (row 1 is zero for root and guardian sessions, which carry no persona
profile):

| role | requests | preload | re-read | re-send | polling |
|---|---|---|---|---|---|
| agents-lead | 711 | 59,641,003 | 3,901,421 | 56,357,380 | 6,788,737 |
| quality-assurance | 463 | 46,128,644 | 7,358,559 | 30,563,235 | 1,166,167 |
| product-lead | 115 | 8,999,716 | 4,048,293 | 6,609,506 | 0 |
| scrum-master | 18 | 1,150,272 | 381,056 | 380,671 | 0 |
| root (orchestrator and others) | 779 | 0 | 0 | 66,892,485 | 30,088,363 |
| guardian (approval reviewer) | 140 | 0 | 0 | 7,579,509 | 0 |

### The instrument — every figure above, from one command

```
python3 - <<'PY'
import json, glob, os, re, collections
CPT = 4.26  # chars per token; the calibration line printed last is where it comes from
PFX = re.compile(r'^\s*(?:[^\s:]+:)?\d+[:\t-]\s?')  # strip "N:" / "path:N:" / "N<tab>" read prefixes
POLL = {'wait_agent', 'sleep', 'wait'}
R = collections.defaultdict(collections.Counter); cal = []

def body(p):
    x = p.get('content') or p.get('output') or []
    return x if isinstance(x, str) else ''.join(y.get('text', '') for y in x if isinstance(y, dict))

for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/2[34]/*.jsonl'))):
    it = [json.loads(l) for l in open(f)]
    m = it[0]['payload']; t0 = it[0]['timestamp'][:19]; forked = bool(m.get('forked_from_id'))
    s = m.get('source'); role = m.get('agent_role') or ('guardian' if isinstance(s, dict) else 'root')
    c = R[role.replace('tadeumendonca_', '')]
    prof = 0; emb = set(); rr = 0; prev = []; cur = []; last = [0, 0, 0, 0]
    pre = len(m.get('base_instructions', {}).get('text', '')); first = True
    for o in it:
        t = o.get('type'); p = o.get('payload'); pt = p.get('type') if isinstance(p, dict) else None
        if t == 'compacted':
            rr = 0
        elif t == 'world_state':
            emb |= {x.strip() for x in (p['state'].get('agents_md') or {}).get('text', '').split('\n') if len(x.strip()) >= 40}
            pre += len(json.dumps(p))
        elif pt in ('message', 'agent_message'):
            txt = body(p); pre += len(txt)
            if 'Canonical persona:' in txt and not prof:
                txt = txt[txt.index('Canonical persona:'):]; prof = len(txt)
                emb |= {x.strip() for x in txt.split('\n') if len(x.strip()) >= 40}
        elif pt in ('custom_tool_call', 'function_call'):
            n = p.get('name'); a = p.get('input') or p.get('arguments') or ''
            cur.append('sleep' if n == 'exec' and re.search(r'cmd\W{0,4}sleep \d', a) else n)
        elif pt in ('custom_tool_call_output', 'function_call_output'):
            d = sum(len(l) + 1 for l in body(p).split('\n') if len(PFX.sub('', l).strip()) >= 40 and PFX.sub('', l).strip() in emb)
            rr += d; c['re-read, chars read (once)'] += d
        elif pt == 'token_count' and p.get('info'):
            u = p['info']['total_token_usage']; now = [u['input_tokens'], u['cached_input_tokens'], u['output_tokens'], u['total_tokens']]
            di, dc, do, dt = (now[i] - last[i] for i in range(4)); last = now
            if di + do == 0:
                c['6 total only, no split'] += dt; continue
            if forked and o['timestamp'][:19] == t0:  # the parent's history, replayed into the fork
                c['0 replay (counted twice)'] += di + do; prev, cur = [], []; continue
            if first and prof and not forked:
                cal.append(round(pre / di, 2))
            first = False
            c['requests'] += 1; c['input cached'] += dc; c['input uncached'] += di - dc
            if any(x in POLL for x in prev):
                c['4 polling'] += di + do; c['polling requests'] += 1
            else:
                e = min(round(prof / CPT), di); r = min(round(rr / CPT), di - e)
                c['1 embedded preload'] += e; c['2 re-read'] += r
                c['3 per-turn re-send'] += di - e - r; c['5 output'] += do
            prev, cur = cur, []
T = collections.Counter()
for k, v in sorted(R.items()):
    T.update(v); print(k, dict(sorted(v.items())))
print('TOTAL', dict(sorted(T.items())))
print('chars/token at the first request of each non-forked, profile-bearing rollout:', sorted(cal))
PY
# TOTAL {'0 replay (counted twice)': 14186577, '1 embedded preload': 115919635, '2 re-read': 15689329,
#        '3 per-turn re-send': 168382786, '4 polling': 38043267, '5 output': 515423,
#        '6 total only, no split': 84240, 'input cached': 327372672, 'input uncached': 10612855,
#        'polling requests': 282, 're-read, chars read (once)': 3491588, 'requests': 2226}
# chars/token …: [4.24, 4.24, 4.24, 4.24, 4.25, 4.26, 4.27, 4.27, 4.27, 4.29, 4.3]
```

**How a request is assigned to a row.** One request is one change in a rollout's cumulative token
counter. The rows are a partition, applied in this order:

1. a replayed event in a forked child goes to row 0;
2. a request whose previous request called `wait_agent`, `sleep` or `wait` goes whole to polling;
3. any other request's input is split: the profile's length goes to preload, re-read text still in
   context goes to re-read, and the remainder goes to re-send. Its output goes to the output row.

The order matters. A different order would move tokens between rows without changing the total.

**Each selector can return non-zero, and the zeros are structural rather than dead patterns.**
Preload and re-read are zero for root and guardian sessions because those carry no persona profile,
and the same selectors return 59.6M and 3.9M on agents-lead. The re-read detector is independent of
file paths: it matches output lines, 40 characters or longer, that appear verbatim in the profile or in
`AGENTS.md`. The replay row matches exactly one block per forked child.

## §1 · Embedded preload — 34.2%, and the one row that grows with every request

**What was measured.** Each profile embeds its brief and every declared preload verbatim: 272,676 to
433,133 characters, about 64k to 102k tokens. It is sent on every model request the instance makes.
Every profile in the sprint declares **`Source version: 2.0.44`**, and **`agents-configuration` alone is
154,571 characters in all four** — about 36k tokens per request, whichever persona is running.

```
python3 - <<'PY'
import json, glob, os, re
for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/2[34]/*.jsonl'))):
    it = [json.loads(l) for l in open(f)]; m = it[0]['payload']
    if not m.get('agent_role'):
        continue
    t0 = it[0]['timestamp'][:19]; fk = bool(m.get('forked_from_id'))
    own = [o for o in it if not (fk and o['timestamp'][:19] == t0)]
    pay = [o['payload'] for o in own if isinstance(o.get('payload'), dict)]
    prof = next((t[t.index('Canonical persona:'):] for p in (o['payload'] for o in it if isinstance(o.get('payload'), dict))
                 if p.get('type') == 'message' and p.get('role') == 'developer'
                 for t in [''.join(x.get('text', '') for x in p['content'])] if 'Canonical persona:' in t), '')
    tc = [p['info']['total_token_usage']['total_tokens'] for p in pay if p.get('type') == 'token_count' and p.get('info')]
    base = max([p['info']['total_token_usage']['total_tokens'] for o in it if fk and o['timestamp'][:19] == t0
                for p in [o['payload']] if isinstance(p, dict) and p.get('type') == 'token_count' and p.get('info')] or [0])
    print('%-18s %-6s profile %6d chars (source %s)  tasks %2d  inbound %2d  own tokens %11d' % (
        m['agent_role'].replace('tadeumendonca_', ''), 'forked' if fk else '', len(prof),
        (re.search(r'Source version: ([\d.]+)', prof) or [None, '?'])[1],
        sum(p.get('type') == 'task_started' for p in pay),
        sum(p.get('type') == 'agent_message' for o in own if o.get('type') == 'response_item' for p in [o['payload']]),
        max(tc) - base))
PY
# 16 lines; the fourth is: agents_lead forked profile 380883 chars (source 2.0.44)  tasks 12  inbound 61  own tokens 118636430

git show v2.0.44:skills/agents-configuration/SKILL.md | wc -c      # -> 154571
```

**The change chosen: trim what a Codex profile embeds, starting with `agents-configuration`.** Cutting
that one preload from every profile would have removed roughly 36k tokens from each of the 1,307
persona requests, about 47M tokens, before any other trim. This is an estimate: requests multiplied by
that preload's token count. A Codex re-run is what would measure it. What goes in its place is a design
question, not a figure: a shorter Codex-only statement of the loop, or a pointer the profile follows
only when a dispatch needs it. **Reading the file on demand is not free.** Once read, the text sits in
context and is re-sent the same way the embedded copy was. On demand helps only for dispatches that
never need the text.

**Why it is deferred.** It changes the contents of the profiles `scripts/codex-agent-build.py`
generates, and it can only be verified by another Codex run. It is also tied to the snapshot-staleness
work: every profile in this sprint embedded **2.0.44**, many releases behind the plugin in use, so a
trimmed profile built from an old snapshot is still old. Trim and freshness belong in the same
generator change.

## §2 · Re-read — 4.6%, and cheaper than #511 expected

**What was measured.** Tool output repeating profile or `AGENTS.md` text totals 3,491,588 characters,
about 0.82M tokens as read. **Because it stays in context, the carried cost is 15,689,329 tokens.**
That is less than one sixth of the embedded preload, so #511's warning holds: *"the re-read is not the
main cost."* The dispatches did ask for it. The opening message of the quality-assurance instance that
started at 19:55 local time on 09-23 announces reading the local brief, its profile and all of its
preloads before starting the review.

**The change chosen, and IMPLEMENTED here: rule 23 in `AGENTS.md`.** The dispatch brief never asks a
profile to re-read a file its instructions already carry, and the profile does not re-read one on its
own. **The rule leaves one exit on purpose, because of the staleness above:** where the carried copy
may be stale, read only the section needed and say why. Without that exit, the rule would turn a
2.0.44 snapshot into the only brief. That is the dependency #511 names, and this page does not settle
it.

## §3 · Per-turn re-send — 49.7%, and one instance was a third of the sprint

**What was measured.** One agents-lead instance ran for 14 hours, took **12 tasks and 61 inbound
messages**, went through 7 compactions, and spent **118,636,430 tokens: 35.0% of the whole sprint**.
Its history grew between compactions, so late requests re-sent 140k to 230k tokens each. The next
largest instance, a quality-assurance one with 7 tasks, spent 19,076,996. The per-instance command in
§1 prints these figures.

**Part of this row belongs to the harness.** A root session's very first request, with no persona,
no history and one short prompt, already costs about **30k tokens**. Codex's own instructions,
workspace state and plugin list are in that figure:

```
python3 -c "
import json, glob, os
for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/2[34]/*.jsonl'))):
    it = [json.loads(l) for l in open(f)]; m = it[0]['payload']
    if isinstance(m.get('source'), dict): continue
    fi = next((p['info']['last_token_usage']['input_tokens'] for o in it for p in [o.get('payload')] if isinstance(p, dict) and p.get('type') == 'token_count' and p.get('info') and p['info']['last_token_usage']['input_tokens']), None)
    if fi: print(os.path.basename(f)[8:27], fi)
"
# -> 31137, 35594, 30279, 29668, 30321
```

That floor is not ours to trim, and it is included in row 3 rather than split out. The split would
rest on a character-to-token ratio for escaped JSON, which this page did not calibrate.

**The change chosen: short-lived instances** — one task per instance, closed when it returns, with a
fresh instance for the next task instead of a follow-up message to an old one. **Why it is deferred.**
It changes the dispatch protocol, in particular a gate's re-review after changes. In this sprint the
re-review went back to the same instance: one quality-assurance instance took 7 tasks. Its saving also has to be weighed against a new instance paying its first request
again, about 120k tokens for quality-assurance. Only a Codex re-run can price that trade, so it is
recorded here as the choice and left to agents-lead as its own change.

## §4 · Polling — 11.2%, and 71% of the waits returned nothing

**What was measured.** 282 requests existed only to read a wait's result, and they cost 38,043,267
tokens, 30.1M of them in root sessions. **167 of 235 `wait_agent` calls timed out**, and 178 of the
235 used a 60-second timeout. On top of those came 47 `sleep` calls of 30 to 45 seconds.

```
python3 - <<'PY'
import json, glob, os, collections
calls = {}; c = collections.Counter()
for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/2[34]/*.jsonl'))):
    for l in open(f):
        p = json.loads(l).get('payload')
        if not isinstance(p, dict):
            continue
        if p.get('type') == 'function_call' and p['name'] in ('wait_agent', 'sleep'):
            a = json.loads(p.get('arguments') or '{}')
            calls[p['call_id']] = (p['name'], a.get('timeout_ms', a.get('duration_ms')))
        elif p.get('type') == 'function_call_output' and p.get('call_id') in calls:
            name, ms = calls[p['call_id']]; out = str(p.get('output'))
            st = 'timed out' if '"timed_out":true' in out.replace(' ', '') else 'returned'
            c[(name, ms, st + (', clamped to the minimum' if 'clamped to the minimum' in out else ''))] += 1
for k, v in sorted(c.items(), key=lambda x: (x[0][0], x[0][1] or 0, x[0][2])):
    print('%4d  %-10s %7s ms  %s' % (v, *k))
print('wait_agent timed out:', sum(v for k, v in c.items() if k[0] == 'wait_agent' and k[2].startswith('timed out')),
      'of', sum(v for k, v in c.items() if k[0] == 'wait_agent'))
PY
# ->    1  wait_agent    1000 ms  timed out, clamped to the minimum
#     ...
#     123  wait_agent   60000 ms  timed out
#       1  wait_agent  180000 ms  returned
#       5  wait_agent  180000 ms  timed out
#     wait_agent timed out: 167 of 235
```

**The change chosen, and IMPLEMENTED here: rule 7 in `AGENTS.md`**, which already forbade
sleep-and-poll on a pipeline. It now covers a dispatched agent too: wait once, blocking, with the
longest timeout the tool accepts, and never sleep, list or re-wait in between. **One limit of that
instruction is unmeasured.** The logs show that the tool clamps a timeout below 10,000 ms up to 10,000
ms, and that 180,000 ms was accepted without a clamp message. **The ceiling was never reached, so it
is unknown**, and "the longest the tool accepts" is written that way for that reason.

## The unmeasured premise — how Codex counts cached tokens against the limit

**What is measured:** the meter the rollouts record, `rate_limits.primary`, a 10,080-minute weekly
window, went from **23% to 100%** during the sprint. In the same period the logs record 10,563,150
uncached input tokens, 325,618,816 cached and 561,345 output.

**What is not measured: how much each class weighs on that meter.** A least-squares fit of meter points
against the three classes does not identify it. The weights change sign and scale with the window size
chosen, because cached and uncached input move together (96.9% cached throughout):

```
python3 - <<'PY'
import json, glob, os, numpy as np
ev = []
for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/2026/09/2[34]/*.jsonl'))):
    it = [json.loads(l) for l in open(f)]; t0 = it[0]['timestamp'][:19]; fk = it[0]['payload'].get('forked_from_id')
    last = [0, 0, 0]
    for o in it:
        p = o.get('payload')
        if isinstance(p, dict) and p.get('type') == 'token_count' and p.get('info'):
            u = p['info']['total_token_usage']; now = [u['input_tokens'] - u['cached_input_tokens'], u['cached_input_tokens'], u['output_tokens']]
            d = [now[i] - last[i] for i in range(3)]; last = now
            pr = (p.get('rate_limits') or {}).get('primary') or {}
            if not (fk and o['timestamp'][:19] == t0):
                ev.append((o['timestamp'], d, pr.get('used_percent')))
ev.sort(key=lambda e: e[0]); cum = np.zeros(3); steps = []; prev = None
for ts, d, pct in ev:
    cum += d
    if pct is not None and (prev is None or pct > prev[0]):
        if prev is not None:
            steps.append([pct - prev[0], *(cum - prev[1])])
        prev = (pct, cum.copy())
S = np.array(steps)
print('meter %.0f%% -> %.0f%% of the weekly window; points %d; uncached %d cached %d output %d' % (
    next(e[2] for e in ev if e[2] is not None), prev[0], S[:, 0].sum(), *S[:, 1:].sum(0)))
for w in (2, 3, 4, 5, 6, 8, 10):
    n = len(S) // w; B = S[:n * w].reshape(n, w, 4).sum(1)
    k = np.linalg.lstsq(B[:, 1:] / 1e6, B[:, 0], rcond=None)[0]
    print('window %2d steps: points per million  uncached %6.2f  cached %6.3f  output %7.2f' % (w, *k))
PY
# meter 23% -> 100% of the weekly window; points 77; uncached 10563150 cached 325618816 output 561345
# window  2 steps: points per million  uncached   2.18  cached  0.096  output   14.18
# window  8 steps: points per million  uncached   0.70  cached  0.228  output  -28.24
# window 10 steps: points per million  uncached  -1.21  cached  0.230  output    5.43
```

**The small windows suggest cached input weighs roughly a tenth of uncached. Treat that as a
hypothesis:** the same fit gives negative weights at larger windows. **What would settle it** is a
controlled run with nothing else running. One session sends many requests over a large, stable prefix
and records the meter before and after. A second sends a similar number of fresh tokens. Vendor
documentation that states the weighting would also settle it. Neither exists here.

**Why the choices do not depend on it.** Polling and short-lived instances reduce the *number of
requests*, and that cuts cached and uncached input together. Trimming the preload cuts cached input
mostly. That one pays off in full only if cached tokens weigh something, and at 96.9% cached even a
tenth weight makes cached input the largest single class on the meter. So the changes still rank the
same way under either reading of the premise. The size of the saving on the meter is what stays
unknown.

## What this method cannot see

- **Characters to tokens is a ratio, not a tokenizer.** Profile and re-read tokens are character counts
  divided by 4.26. That value is the median of 11 first requests, which ranged from 4.24 to 4.30. Over
  that range, row 1 moves by less than 1%.
- **The profile is assumed to survive compaction.** This is consistent with the logs rather than
  proven: on the long agents-lead instance, the smallest request after its first compaction was
  112,460 tokens, above the profile's roughly 89k.
- **The re-read count is a lower bound.** Only verbatim lines of 40 characters or more are matched, so
  reformatted or partial reads are missed. The count also resets at every compaction, even where a
  compaction kept some of that text.
- **Root sessions reading skill files are counted in re-send, not re-read.** A root session carries no
  profile, so for it such a read is not a *re-*read.
- **Polling includes the waits that were needed.** The 282 polling requests are exactly the 235
  `wait_agent` results plus the 47 `sleep` results. 68 of those waits returned a finished agent, and
  one blocking wait per dispatch would still cost those requests. The avoidable part is the 167 that
  timed out plus the 47 sleeps: **214 of 282 requests, 76% by count.** It is not 76% of the tokens,
  because the cost of each wait was not taken separately.
- **The meter covers the whole account.** No rollout from the previous day on this machine was still
  being written when the meter's first sample was taken: the last one was modified at 23:11 local time
  on 09-22 (`ls -la ~/.codex/sessions/2026/09/22/`), which is 02:11Z, and the first sample is 11:38Z on
  09-23. Usage from any other device or cloud task in that window would also move the meter, and is
  invisible here.
- **A fork is detected by its timestamp.** A forked child's replayed events share its first line's
  second. A child that did real work within that same second would have that work counted as replay.
