# Portable prompt — regenerate a mirror from one release tag, and never touch what the mirror keeps

Use this prompt when one repository is the source of a body of text or configuration and another
repository carries a copy of it, and the copy also holds files of its own that the source does not
have.

## Behaviour to carry

Regenerate the copy with a script, never by hand, and make its output a function of one released tag
of the source:

- **Read the tag's objects, not a working tree.** A checkout can be dirty or on another commit; the
  tag's objects cannot. Refuse a name that is not a release tag, including a branch spelled like one.
- **Write a declared carrier map and nothing else.** Every source file maps to one target path through
  named transforms. A source file the map does not cover stops the run, so a new layout is a decision
  rather than a silent skip.
- **Never write or delete a file the script did not generate.** Record every generated path, with the
  tag and commit, in a watermark file. The only deletion is a path the previous watermark lists and the
  new tag dropped. A map path that already exists and was not generated before stops the run before
  anything is written; so does any path the copy declares its own.
- **Keep the source's text.** Transforms are mechanical (a key the copy's format forbids, a placeholder
  the copy resolves differently, quoting). Adapting prose to the copy's context grows a second source
  inside the mirror.
- **Commit the regeneration alone.** Script output in one commit, reproducible by re-running the script
  on the parent at the same tag; every change to a test, a generator or a document the regeneration
  makes necessary goes in its own reviewed commit that says why.

## Reasoning

A copy edited by hand drifts, and the drift is invisible until someone diffs the two. A script that
reads a working tree reproduces whatever that tree happened to hold. A script that deletes what it does
not recognise destroys the files the copy legitimately keeps, and the first run is when that is most
likely, because the copy has never been regenerated before. Separating script output from reviewed
changes is what stops a build from making its own checks green by editing the checks inside the same
diff they judge.

## The limit

The watermark protects only what it records. A file added to the copy under a path the source later
starts to carry is caught (the run stops), but a file the copy keeps under a path the source already
carried before the first regeneration is overwritten on that first run unless it is declared. Declare
the copy's own paths before the first run. Nothing here checks that the source's text is true for the
copy's context: that stays with review.

## Evidence owed

A fixture test per transform; a test that a non-generated file is untouched, that a declared path stops
the first run, that an undeclared existing path stops a later run, and that a second run writes nothing.
Then break each transform in the script, watch its test go red, restore, and watch it go green.
