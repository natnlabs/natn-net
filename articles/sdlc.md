---
title: The NatnLabs SDLC
layout: page
permalink: /articles/sdlc/
---

## The NatnLabs SDLC

A small fleet of Claude Code sessions writes, reviews, and ships code across
a set of personal projects with a human only in the loop for judgment calls.
This is a description of how that fleet is put together.

### The shape of it

Two roles run continuously, roaming across every project in the org rather
than being pinned to one repo each:

- **Product Owner (PO)** — files issues from bug reports and ideas, reviews
  implementation plans posted by Engineers, checks finished work against
  acceptance criteria, and merges what passes.
- **Engineer** — picks up an issue, posts a plan, implements it, opens a
  pull request, and responds to review feedback.

Each pickup — one issue, from claim to close — runs as its own
process-scoped session. A session starts, does one unit of work, and exits;
it does not idle waiting for something to happen. A lightweight supervisor
around each role restarts it for the next pickup and wakes it on demand via
MQTT rather than polling.

### The issue is the source of truth

Nothing about a piece of work lives in a chat transcript, a side channel, or
a model's memory. The GitHub issue *is* the record: its labels encode who
owns it and what state it's in, its comments carry the plan, the review, and
the reasoning behind any judgment call. Any session — the one that started
the work or a completely fresh one three days later — can read the issue and
pick up exactly where the last one left off. That's what makes the
process-per-pickup model workable: state doesn't need to survive in a
running process, because it was never kept there.

A `Blocked-by: #N` trailer in an issue body is the one piece of explicit
dependency wiring; everything else — priority, ownership, review status —
is a label.

### Blast radius sets the autonomy

Not every repo gets the same amount of unsupervised trust. A new repo starts
gated: every pull request needs a human to review and merge it. After a
run of clean merges with no reverts and no red CI, a repo can be promoted to
self-merge, where the Engineer's PR goes in once it passes review and CI —
still reviewed, just not by a human, unless the issue itself flags something
that needs one.

The repo that hosts this tooling — the one every other session reads its
scripts and prompts from fresh at the start of every pickup — earned that
promotion the slow way: 23 clean pull requests with zero reverts before it
was downgraded from gated to self-merge. Its own bad merge would have a
wider blast radius than any single project's, so it had to prove itself
first.

### Safety invariants

A short list of rules sits above the normal autonomy model and can't be
argued around by a plan, an approval, or a persuasive comment thread —
things like never force-pushing over another session's work, never
bypassing a required review gate, never taking an irreversible action
without it being visible in the issue thread first. Everything else is
negotiable through the normal PO/Engineer conversation; these aren't.

### What the human actually does

Mostly: unblock. Decisions that need real-world judgment — a security
tradeoff, a scope call that isn't in either the issue or the code, an
external account or credential nothing in the fleet can provision itself —
get flagged onto a person and everything else keeps moving around that one
blocked issue. The rest of the loop — filing, planning, implementing,
reviewing, merging — runs without a person watching it happen.

