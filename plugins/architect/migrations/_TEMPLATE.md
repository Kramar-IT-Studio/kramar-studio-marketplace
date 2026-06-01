---
migration: NNNN
from: X.Y.Z
to: A.B.C
mutates_frontmatter: false
scope: project-docs
---

# Migration NNNN: X.Y.Z → A.B.C

## Summary

<One line: what changes in the user's project at this version step.>

## Preconditions

- `docs/architecture/` exists (project initialized for this role).
- <other invariants the Transform assumes>

## Transform

<Ordered, imperative steps the runner executes. Examples:>
1. <move / rename a file>
2. <add a section to an existing doc>
3. <add an OPTIONAL front-matter field to artifacts of type X>

If there are no structural changes, write exactly: `No structural changes. Marker bump only.`

## Backup

Not applicable — no front-matter mutation.
<When mutates_frontmatter: true, instead describe which files are copied to
`docs/architecture/.upgrade-backup/<from>-to-<to>/` before mutation.>

## Verification

- <post-condition the runner checks before writing the marker>

## Rollback note

The runner refuses on a dirty working tree, so `git` is the rollback: inspect the diff,
`git restore` / `git checkout` to revert. When `mutates_frontmatter: true`, a copy of the
affected files is also written to `docs/architecture/.upgrade-backup/<from>-to-<to>/`.

## Never

- Never delete artifacts; transition status instead.
- Never renumber IDs (ADR-NNNN).
