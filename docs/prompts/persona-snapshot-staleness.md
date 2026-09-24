# Portable prompt: a pinned persona snapshot must say when it is behind

**Who this is for.** An engineer whose agent harness loads personas (role briefs, reviewer contracts)
from a **pinned copy** rather than from the live source. A pinned copy is reproducible, and a review
in flight keeps the exact contract it started under. It also falls behind every release until someone
rebuilds it. **This prompt asks for behaviour and gives the reasoning and the limits.** It names no
file, hook or product from the loop it came from.

---

## The behaviour to adopt

> **Before you dispatch a persona, compare the version its pinned copy was built from with the
> version of the source you currently have installed. If the copy is older, or its version cannot be
> read, say so before dispatching. Treat every rule newer than the copy as absent from that persona.
> Do not refuse to work because of it.**

- **Report. Do not refuse.** A stale persona is a quality risk. A refusal is an outage. Be clear about
  which way an error runs. A missed report costs one stale review. A check that crashes into a
  refusal costs the session. If a failed check can block anything, turn every failure into silence
  plus a log line.
- **"Unknown" is not "current".** A copy that does not record the version it was built from must be
  reported, not assumed fresh.
- **Do not ask the persona to re-read the source.** It is expensive, and nothing can verify the
  re-read happened. The fix is to rebuild the copy, not to add a ritual.

## Updating without breaking a review in flight

Measure two facts on your own runtime before you trust any procedure. They decide everything:

1. **When does a running session read the registration?** Once per session, once per thread, or on
   every dispatch?
2. **When is a persona's content read?** When the registration is loaded, or when the persona is
   dispatched?

On the runtime this came from, the registration was fixed **per thread**. The content was read from
disk **at dispatch**. That produces this procedure, and a different answer to either question
produces a different one:

1. Build the new copy into a **new** location. Never overwrite the old copy in place.
2. Verify the new copy against its source.
3. Point the registration at the new copy. Threads already open keep the old one.
4. Continue the work in a **new** thread.
5. **Keep the old copy until every thread that started before step 3 has finished.** Deleting it
   breaks the next dispatch in those threads. On the measured runtime, that dispatch produced no
   child at all.

## The limits

- **A check that reads the registration file cannot see a thread's registration.** After an update,
  the check reads the new file and goes quiet, while an old thread keeps using the old copy. Say this
  where the check is documented. Silence after an update does not mean every open thread is current.
- **A registration passed any other way is invisible to a file check**, for example flags given at
  launch or a user-level configuration. The check stays silent for those. Name them rather than
  implying full coverage.
- **Where you carry the report is itself a decision about cost.** A hook that runs on every prompt
  repeats the report on every prompt. A session-start hook fires once, but adding one may need a new
  approval or trust step, and until that happens it may be skipped silently. Choose knowingly, and
  write the choice down.
- **Nothing here verifies that the model acts on the report.** Delivering the text to the model can be
  measured. Whether the model obeys it cannot. By the test *would something stop me, or only my
  memory?*, this is an instruction.
