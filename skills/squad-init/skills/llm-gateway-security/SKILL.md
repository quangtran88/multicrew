---
name: llm-gateway-security
description: Use when reviewing a diff that touches LLM prompt construction, tool/function-calling, RAG/retrieval, rendering of model output, AI credentials, or any path where model or tool output flows onward — the LLM-gateway attack class. Supplies the sink patterns and severity/FP rules for that lens. Do not use for generic web vulns the base review already covers, or for writing code.
---

<!--
Provenance: re-authored (not copied) and retargeted from gstack cso/sections/audit-phases.md Phase 7 (grep set :112-132, FP guard :130-132) @ 14fc086 (gstack is MIT) + oh-my-openagent .agents/skills/security-research/SKILL.md severity standard (:21-37) @ 6ca975e. Adapted to a Multica squad: dropped the team-mode orchestration (team_create / 5-member roster) and the CWE/OWASP URL frame; findings feed the squad canonical finding grammar, verdict deferred to the agent's existing convention. The generic sink-category list below is the portable attack-class framework; this repo's concrete sink inventory (the exact file:function pairs each category resolves to here) is earned as real diffs hit them, not pre-seeded.
-->

# LLM-gateway security

An LLM gateway's highest-value security defects are the ones generic SQLi/XSS/CSRF review misses. When the diff touches model or tool I/O, audit these sinks before signing off.

## Grep / trace for these sinks
- **User input → system prompt or tool schema:** user-controlled text concatenated into the *system* role, a tool `description`, or a function-calling schema (string interpolation near system-prompt/tool-schema construction).
- **Unsanitized model output rendered as markup:** `dangerouslySetInnerHTML`, `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `v-html` — any HTML/markdown render of a model response without sanitization.
- **eval/exec of model output:** `eval(`, `new Function(`, `Function(`, `exec(`, dynamic `import()` over a model/tool response.
- **Model output → SQL / shell / path:** model or tool output interpolated into a query string, `execFile`/`spawn` argv, or a filesystem path (injection / path traversal).
- **Tool/function calls without validation:** `tool_choice`, `tools:`, `function_call`, tool dispatch — are arguments validated/authorized **before** execution? For fetch-style tools, is the target URL/host checked against an allowlist (SSRF)?
- **Secrets/PII egress via model output or tool results:** model output or `tool_result` text reaching a user-facing channel without redaction — a new egress channel, or a weakening/flip of an existing redact-or-scrub path, that lets secret-shaped values through.
- **Hardcoded AI keys:** `sk-`/provider key literals instead of `process.env` (cross-check the eager secrets rule).

This repo's specific sink inventory (the exact file:function pairs the categories above resolve to here) is earned as real diffs hit them:
<!-- EARNED:sink-inventory -->
<!-- ships empty on purpose — the retro/harvest loop fills this from real deliveries -->
<!-- /EARNED -->

## Trace beyond grep
- **Indirect injection:** can retrieved documents **or tool/function-call results** carry instructions the model then obeys? (Tool results are a common channel.)
- **Output trust boundary:** is model output treated as trusted — rendered as HTML, run as code, or used to build a query/path/URL?
- **Tool-call authorization:** are model-requested tool calls checked against the caller's permissions?
- **Multi-tenant / object-ownership isolation:** does a RAG/memory lookup — or an id-addressed CRUD fetch — scope to the caller's tenant/agent/epoch and 404 (not 403) on a miss, or does it fetch-then-serve another tenant's object (IDOR/BOLA)?
- **Cost/resource amplification:** can one user request fan out into unbounded model calls?
- **Fail-closed on authz/policy error:** in a tools-policy or before-tool-call evaluator, does the catch/throw or unresolved-scope/unknown-action branch DENY, or does it pass through and fail OPEN on that error path? Carve-out: an intentional no-opinion allow (a tool the lane genuinely does not own) is correct-by-design, NOT a finding — flag only an error/exception/unresolved-ownership branch that falls through to allow.
- **Auth brute-force regression:** on any brute-forceable verify/signed-download endpoint, does the per-token failed-attempt lockout survive? Flag ONLY a diff that removes/weakens it or adds a NEW unguarded OTP/PIN/signed-download verify endpoint — never absence-on-every-diff (an existing lockout already ships and isn't itself a finding).

## Severity mapping
This lens emits **CRITICAL / HIGH / MEDIUM** only — the FP gate caps bare suspicion at MEDIUM, so there is no LOW here.
- **CRITICAL** — user input reaching a system prompt; unsanitized model output rendered as HTML; eval/exec of model output.
- **HIGH** — model output → SQL/shell/path injection; missing tool-call validation/authorization; SSRF via a model-influenced fetch target; secrets/PII egress through model output or tool results; cross-tenant data surfaced via retrieval or an id-addressed object fetch (IDOR/BOLA); an authz/policy evaluator whose error/exception branch fails open instead of blocking; removal or weakening of a brute-force lockout on an auth/verify endpoint; exposed AI API key.
- **MEDIUM** — unbounded model-call amplification; RAG / indirect-injection surface without input validation.

## False-positive guard (load-bearing — keep in sync with the eager copy in {{CONTRACT_SEAT_NAME}}'s instructions)
A user's message sitting in the user-role slot of a model call is the intended input channel, not injection — never flag that alone. Treat it as injection only when user-controlled text crosses into a *privileged* position: a system prompt, a tool/function schema, or a function-calling argument. Severity gate: every finding needs a concrete attack path; reserve HIGH/CRITICAL for cases with real exploit preconditions and impact; downgrade bare suspicion to MEDIUM and the AUDIT block.

## Evidence discipline
Prove a finding by reading the sink line and naming the path from attacker-controlled input to impact. Use static or illustrative evidence only — never run a destructive PoC against a live service or third party.

## Report
Render each finding in the squad canonical finding grammar:

`[SEVERITY] (confidence: N/10) {file}:{line} — {sink + attack path} | Fix: {concrete mitigation}`

Emit your verdict and end-marker per your agent's own VERDICT FORMAT block (`## REVIEW VERDICT` … `{{{END-REVIEW}}}`) — do not restate the verdict token here.
