---
name: architecture-review-method
description: Use when reviewing a diff for cross-file coherence, coupling, or abstraction-boundary regressions — the architecture lens. Supplies precise vocabulary (depth/seam/locality), the deletion test, the adapter-count seam rule, and a code-graph-first caller-impact recipe with a graph-free fallback. Do not use for writing code, style policing, or other reviewers' lenses.
---

<!--
Provenance: re-authored (not copied) from mattpocock skills/engineering/improve-codebase-architecture/{SKILL,LANGUAGE,DEEPENING}.md @ 694fa30 (MIT, © Matt Pocock). Companion files (LANGUAGE.md, DEEPENING.md) are INLINED here because Multica ships only this single body. Retargeted for a Multica squad: a refactoring workflow becomes the Architecture reviewer's REVIEW lens — the vocab + deletion test name coupling/abstraction regressions a diff introduces; findings feed the squad canonical grammar; the caller-impact recipe is code-graph-tool-first, with an in-house graph-free recipe retained as a fallback for when that tool is unavailable or the runtime can't reach it. Dropped: the HTML/Tailwind/Mermaid report, the interactive grilling loop, the CONTEXT.md/ADR side-effect writes (this seat is strictly read-only), and the Explore/Agent subagent (single seat).
-->

# Architecture review method

Your lens is whole-repo coherence: coupling, abstraction-boundary violations, and maintainability regressions a diff introduces. This skill gives you the **vocabulary** to name them precisely and a **method** to trace them — not a new verdict format (keep your agent's verdict convention).

## Vocabulary — use these terms exactly in findings
Don't drift into "component", "service", "API", or "boundary". Consistent language is the point.

- **Module** — anything with an interface and an implementation: a function, class, package, or tier-spanning slice. (Avoid: unit, component, service.)
- **Interface** — *everything a caller must know to use the module correctly*: the type signature, plus invariants, ordering constraints, error modes, required config, performance characteristics. Not just the signature. (Avoid: API, signature — too narrow.)
- **Implementation** — the code inside the module.
- **Depth** — leverage at the interface: how much behavior a caller (or test) exercises per unit of interface they must learn. **Deep** = a lot of behavior behind a small interface. **Shallow** = the interface is nearly as complex as the implementation.
- **Seam** (Michael Feathers) — a place you can alter behavior *without editing in that place*; the location where an interface lives. Use this, not "boundary" (overloaded with DDD's bounded context).
- **Adapter** — a concrete thing that satisfies an interface at a seam (describes the role it fills, not what's inside).
- **Leverage** — what callers get from depth: more capability per unit of interface learned.
- **Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrated in one place. Fix once, fixed everywhere.

## Principles
- **The deletion test.** Imagine deleting the module. If complexity *vanishes*, it was a pass-through (shallow). If complexity *reappears across N callers*, it was earning its keep. Apply this to anything a diff makes you suspect is shallow indirection.
- **The interface is the test surface.** Callers and tests cross the same seam. If a change forces tests to reach *past* the interface (asserting on internal state), the module is the wrong shape.
- **One adapter = a hypothetical seam. Two adapters = a real one.** A seam with a single implementation is just indirection. Flag a diff that adds a port/abstraction with only one concrete implementation, and flag a diff that hard-couples logic across what should be a real seam (two adapters justified — typically production + test).

## Is a seam even warranted? (dependency categories)
Classify a dependency before recommending a port — this turns the adapter-count rule into a concrete `Fix:`. Concrete dependency examples for this stack are part of the {{STACK_DESCRIPTION}} scan; the categories:
- **In-process** (pure compute, in-memory state) — merge the modules and test through the new interface directly; **no port**.
- **Local-substitutable** (a dependency with an in-memory or embedded stand-in) — the seam is *internal*; test with the stand-in in the suite, **no port at the module's external interface**. A diff that adds a public port here is needless indirection — say so.
- **Remote but owned** (an internal service across the network) — define a port; a live adapter for prod, an in-memory adapter for tests. Logic stays in one deep module.
- **True external** (third-party services you don't control) — inject a port; tests use a mock adapter.

## Method on a diff
Do the read per your eager instructions (fresh full-repo+diff pass, your largest-in-panel context). This skill only adds *what to look for* through the vocabulary above — friction the diff introduces or worsens:
- Understanding one concept now requires bouncing between many small modules.
- A module made **shallow** — its interface nearly as complex as its implementation.
- Pure functions extracted only for testability, where the real bug lives in *how they're called* (no **locality**).
- Tightly-coupled modules leaking across their seams. Known recurring coupling shapes for this repo (filled by the retro loop as they're found):
<!-- EARNED:recurring-coupling-shape -->
<!-- ships empty on purpose — the retro/harvest loop fills this from real deliveries -->
<!-- /EARNED -->
- Code the diff leaves untested or hard to test through its current interface.

Apply the deletion test, the dependency-category check, and the adapter-count rule to each suspect.

## Caller-impact: code-graph tool first, grep fallback
Prefer your seat's code-graph tool ({{CODE_GRAPH_TOOL}}) for out-of-diff caller-impact: its impact/context/detect-changes equivalents for callers, callers+callees+flows, and the diff's affected scope. FALLBACK when the code-graph tool is unavailable or unreliable on your runtime: trace with a repo-wide grep to enumerate call sites outside the diff, check each for drift (arity, param/return types, ordering/invariant, error modes), and resolve each new/changed import path to catch "referenced-but-missing module" gaps. Either way your accuracy guards hold: tag VERIFIED vs INFERRED, and a graph hit is INFERRED until you read the cited code.

## Findings
Render each finding in the squad canonical finding grammar:

`[SEVERITY] (confidence: N/10) {file}:{line} — {coupling/seam/locality defect, named in the vocabulary above + why it's wrong} | Fix: {the deepening or decoupling that closes it}`

Confidence follows the evidence: a VERIFIED finding you read end-to-end rates higher; an INFERRED one is capped lower. Emit your verdict and end-marker **per your agent's own VERDICT FORMAT (already in your instructions)** — do not restate the verdict token here, and do not adopt a different skill's verdict spelling. Strictly read-only: never edit files, write CONTEXT.md/ADRs, run a PoC against a live service, push, or merge.
