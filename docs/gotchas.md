# Gotchas

## The `claude-review` check never appears on PRs

`claude-code-review.yml` triggers on each PR in this repo, but every run so far
has concluded `failure` with zero jobs, so no `claude-review` check run is ever
posted. As of 2026-11-12 that is all four runs (PRs #2, #3, #4 and #5); the
latest, run 41259808058 on PR #5, has `jobs: []`. A PR's check list shows only
`CodeQL` and `Analyze (actions)`.

**What this means:** a missing `claude-review` check on a PR here is expected.
It is not evidence that the PR skipped review, and "CI green" on a PR covers
only CodeQL.

**Root cause: unconfirmed.** The workflow file's own comment describes a
`startup_failure` caused by missing job-level `permissions:`, which was
supposedly fixed. The runs don't show whether that fix took effect or whether
there is a second cause. Don't assume either until it has been investigated.
