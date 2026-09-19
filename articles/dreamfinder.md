---
title: Dreamfinder
layout: page
permalink: /articles/dreamfinder/
---

## Dreamfinder — the vault gateway

Several different assistants — a chat interface, a coding agent, a
messaging bot — all need to read and write the same personal knowledge
base. Dreamfinder is the one door all of them go through to do that: an
MCP server that fronts the vault and gives every consumer the same read,
search, and write tools, instead of each one holding its own credentials
and inventing its own rules for what a "safe" write looks like.

### Why one gateway

Before Dreamfinder, every consumer that touched the vault held its own
access token, and each one had slightly different opinions about what was
safe to write. That produces two chronic problems: credential sprawl —
every new consumer is another secret to provision, rotate, and eventually
find leaking — and drift, where each consumer's private idea of "a valid
note" slowly diverges from everyone else's.

Consolidating behind one gateway fixes both. There's one identity that
actually touches the vault's storage, and one place where "is this write
safe" gets decided, regardless of which assistant asked for it.

### What's enforced vs. what's advised

Dreamfinder draws a hard line between two kinds of rule:

- **Invariants** — structural things that must always be true: a filename
  has to be legal on disk, frontmatter has to parse as valid YAML, a path
  has to stay inside the vault, a write has to say explicitly whether it's
  creating or updating. These are enforced in the gateway's own code. A
  write that violates one is rejected outright.
- **Conventions** — everything softer: which frontmatter fields a given
  note type expects, filename casing, which folder a note belongs in, tag
  naming. These live in a companion skill the gateway hands out to
  consumers, not in the gateway's code.

The reasoning: conventions change constantly as the vault's owner refines
how he organizes things, and baking that into the server would mean every
taxonomy tweak becomes a deploy. Structural invariants almost never change
and exist to prevent actual damage — a malformed file, a path escape — so
those live where they're enforced consistently rather than trusted to each
consumer's judgment. A consumer that ignores the convention skill still
produces a syntactically valid note; it's just stylistically off, and
something to catch with a periodic pass rather than a hard rejection.
Being liberal about what's accepted and conservative about what's advised
keeps the gateway from becoming brittle every time a convention shifts.

### Search is more than one shape

Five read paths, each answering a different kind of question: fetch a
note you already know the path to, browse a folder, find notes by
filename pattern, grep note bodies for an exact string, or search by
meaning across the whole vault. Keyword and semantic search aren't
competing with each other — one finds strings, the other finds ideas, and
a consumer picks whichever the question actually calls for.

### Small design choices that mattered

A few decisions came out of running this in production rather than
planning it on paper:

- **Binary files are returned by reference, not inline, by default.** A
  400&nbsp;KB image costs real context if it's stuffed into a response as
  base64 — and the model almost never needs the bytes, only the human-facing
  surface does. So a read returns a short-lived fetch URL instead, and a
  consumer opts in to inline bytes only when it genuinely needs them, still
  capped so a misbehaving request can't blow the budget by accident.
- **Deploys promote only after they prove themselves.** A new version
  takes zero production traffic at first, gets a real health check against
  its own private URL, and only then gets the traffic switch flipped. A
  broken deploy stays contained — nothing that was already working is ever
  put at risk to test the new thing.
- **Per-consumer attribution survives a single write identity.** Every
  write is authored by the same one gateway identity, but the commit
  carries a trailer naming which consumer actually asked for it — so the
  audit trail down at the version-control layer still knows who did what,
  even though only one identity ever touches storage.

