#!/usr/bin/env bash
# assemble-lib.sh — the reusable assembly engine (sourced, never executed).
# Extracted 2026-07-07 from the donor squad's build-and-apply.sh. Policy: freeze-and-diverge
# (§10.5) — donor evolution is NOT auto-backported.
#
# What lives here: the portable machinery a thin generated wrapper sources — verify-by-readback,
# the delete-before-add byte linter, and collect-and-continue error handling. What does NOT live
# here: the per-seat cap table (donor's budget_cap() case-list) — those were per-seat DATA; the
# template MEASURES each cap at init and the wrapper supplies it fail-closed as {{seat.cap}}
# (design F3/R13). This engine takes the cap as a function argument instead.

set -uo pipefail   # NOT -e: a single seat failing must not abort the batch — that all-or-nothing
                   # abort (a 25KB Lead card choking) is the #1 config-drift vector. Failures are
                   # collected and the sourcing wrapper exits non-zero at the end if any seat failed.

# Collect-and-continue accumulator. The wrapper reads/exits on it via report_fails.
fails=()

# verify: re-fetch the live agent and confirm its instructions equal what we just applied — catches a
# silent partial/empty apply that still returned 0. $() strips the trailing newline from both sides.
verify() {
  local id="$1" name="$2" exp="$3" got
  got="$(multica agent get "$id" --output json | jq -r '.instructions')"
  if [[ "$got" == "$(cat "$exp")" ]]; then echo "   ✓ verified live"
  else echo "   ✗ DRIFT: live instructions != $exp"; fails+=("$name"); fi
}

# over_budget NAME SIZE CAP → true (and records a fail) when SIZE exceeds NAME's measured cap and no
# override set. Prose-budget gate: growing a card past its cap requires deleting something first (or a
# deliberate MCA_OVERBUDGET=1 override + re-measuring the cap in the manifest). Fires in --dry too — a
# budget linter. CAP is supplied by the caller (measured at init + ~5% headroom, keyed by seat).
over_budget() {
  local name="$1" size="$2" cap="$3"
  if (( size > cap )) && [[ -z "${MCA_OVERBUDGET:-}" ]]; then
    echo "   ✗ OVER BUDGET: $size > $cap bytes — delete before you add (MCA_OVERBUDGET=1 overrides)"
    fails+=("$name(budget)"); return 0
  fi
  return 1
}

# over_platform_limit NAME SIZE LIMIT → true (and records a fail) when an assembled card exceeds the
# platform's hard instruction-size limit (probed at P0, a holes.json value). This is a floor no card
# may cross regardless of its measured cap — an assembled prompt above it is silently truncated live.
over_platform_limit() {
  local name="$1" size="$2" limit="$3"
  if (( size > limit )); then
    echo "   ✗ PLATFORM LIMIT: $size > $limit bytes — the engine will truncate this prompt (hard cap, no override)"
    fails+=("$name(platform-limit)"); return 0
  fi
  return 1
}

# assemble_card OUT PREPEND CARD → write the assembled prompt for one seat to OUT.
# PREPEND: 0 = card only (standalone seat), 1 = constitution + card (pipeline seat),
#          2 = constitution + _reviewer-common + card (reviewer bench seat).
# constitution.md / roles/_reviewer-common.md are cat'd VERBATIM into the live prompt — never put
# editorial/maintainer comments inside them or any roles/*.md (they ship byte-for-byte into every
# prompt); provenance belongs in the scripts + git history.
assemble_card() {
  local out="$1" prepend="$2" card="$3"
  case "$prepend" in
    2) { cat constitution.md; printf '\n\n'; cat roles/_reviewer-common.md; printf '\n\n'; cat "$card"; } > "$out" ;;
    1) { cat constitution.md; printf '\n\n'; cat "$card"; } > "$out" ;;
    *) cat "$card" > "$out" ;;
  esac
}

# apply_seat DRY ID NAME PREPEND CARD CAP LIMIT → assemble one seat, run both byte gates, apply + verify.
# Never aborts the batch on a single-seat failure (set -uo, not -e); records into fails and returns.
apply_seat() {
  local dry="$1" id="$2" name="$3" prepend="$4" card="$5" cap="$6" limit="$7"
  local asm="${MCA_ASSEMBLE_OUT:-/tmp/mca-assembled}/${name}.md" sz src
  mkdir -p "$(dirname "$asm")"
  assemble_card "$asm" "$prepend" "$card"
  sz=$(wc -c <"$asm" | tr -d ' ')
  case "$prepend" in
    2) src="constitution.md + roles/_reviewer-common.md + $card" ;;
    1) src="constitution.md + $card" ;;
    *) src="$card (standalone — no constitution)" ;;
  esac
  echo "== $name  ($sz bytes)  <- $src"
  over_platform_limit "$name" "$sz" "$limit" && return 0
  over_budget "$name" "$sz" "$cap" && return 0
  if [[ "$dry" -eq 0 ]]; then
    if multica agent update "$id" --instructions "$(cat "$asm")" >/dev/null; then
      echo "   applied."; verify "$id" "$name" "$asm"
    else
      echo "   ✗ apply FAILED (agent update non-zero) — continuing"; fails+=("$name")
    fi
  fi
}

# report_fails DRY → print the batch outcome and exit non-zero if anything failed or drifted.
# The batch is PARTIALLY applied on failure — a re-run or an individual re-apply reconciles it.
report_fails() {
  local dry="$1"
  echo "Done.$([[ "$dry" -eq 1 ]] && echo ' (dry run)')"
  if ((${#fails[@]})); then
    echo "✗ ${#fails[@]} seat(s) FAILED or DRIFTED: ${fails[*]}" >&2
    echo "  Live squad is now PARTIALLY updated — re-run, or apply the failed card(s) individually." >&2
    exit 1
  fi
}

# warn_uncommitted — applied-but-uncommitted drift guard. WARN-only, never blocks; MCA_WIP=1 silences.
# Scoped to the config dir we just applied from.
warn_uncommitted() {
  [[ -n "${MCA_WIP:-}" ]] && return 0
  local dirty; dirty="$(git status --porcelain . 2>/dev/null)"
  if [[ -n "$dirty" ]]; then
    echo "⚠  config dir is dirty — the state you just applied isn't committed."
    echo "   Commit so the live squad matches git (MCA_WIP=1 silences this):"
    printf '%s\n' "$dirty" | sed 's/^/     /'
  fi
}
