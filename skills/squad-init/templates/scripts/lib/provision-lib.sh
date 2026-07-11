#!/usr/bin/env bash
# provision-lib.sh — the reusable roster-provisioning engine (sourced, never executed).
# Extracted 2026-07-07 from the donor squad's apply-roster.sh. Policy: freeze-and-diverge
# (§10.5) — donor evolution is NOT auto-backported.
#
# What lives here: the create-or-update idempotency primitive, the dry-run gate, the fail-loud
# jq asserts (the crown jewel — they now validate an AUTHORED mcp-config, not a derived one), and
# the ambient-registry presence assert. What does NOT live here: any migration history (rebuilds,
# renames, A/B swaps, rollback logs) — a fresh squad has no past to replay, so the wrapper is a
# clean provisioner.

set -euo pipefail   # surgery halts on any error (unlike the assemble batch, which collects-and-continues):
                    # a half-applied roster edit is worse than a stopped one — fix and re-run.

# run: echo every mutation; execute it only when not --dry. if-form so --dry returns 0 (a bare `&&`
# returns 1 on the skipped branch → set -e would abort --dry after the first step). DRY is a wrapper global.
run(){ echo "+ $*"; if [[ "${DRY:-0}" -eq 0 ]]; then "$@" >/dev/null; fi; }

# agent_exists ID → 0 if the agent is already provisioned (drives create-or-update; a plain create is a
# no-uniqueness INSERT, so never blind-create).
agent_exists(){ multica agent get "$1" >/dev/null 2>&1; }

# assert_json_file PATH LABEL → fail LOUD (halt) if PATH is missing or not valid JSON. Used for authored
# mcp-config files and installed --settings deny profiles before they are handed to a live seat.
assert_json_file(){
  local path="$1" label="${2:-$1}"
  if [[ ! -f "$path" ]] || ! jq empty "$path" >/dev/null 2>&1; then
    echo "✗ $label ($path) missing or not valid JSON — refusing to provision against it" >&2
    exit 1
  fi
}

# assert_settings_profile PATH SEAT → the hardened deny profile MUST exist AND parse BEFORE launch.
# It lives OUTSIDE the repo (an account/machine path — SETTINGS_PROFILE_PATHS), so a git revert can't
# restore it; a missing/corrupt target would silently launch the seat with an empty-deny profile.
assert_settings_profile(){
  local path="$1" seat="$2"
  if [[ ! -f "$path" ]] || ! jq empty "$path" >/dev/null 2>&1; then
    echo "✗ $path missing or not valid JSON — refusing to launch $seat with an empty-deny --settings target" >&2
    exit 1
  fi
}

# assert_mcp_authored FILE SERVER... → fail LOUD if any required server is absent or not a non-null
# object. The authored file (from templates/mcp, authored at P4 from the P0 catalog) can carry a
# "key":null for an absent server and still be valid JSON → this is the assert that catches it. This
# is the donor's derive-from-live crown-jewel assert, now validating the AUTHORED config instead.
assert_mcp_authored(){
  local file="$1"; shift
  local servers; servers=$(printf '%s\n' "$@" | jq -R . | jq -s .)
  jq -e --argjson want "$servers" '
    . as $c | ($want | all(. as $k | ($c.mcpServers[$k] | type) == "object"))
  ' "$file" >/dev/null \
    || { echo "✗ $file malformed — a required server is missing or null (authored-config sanity check failed)" >&2; exit 1; }
}

# assert_exa_restricted FILE → the egress gate (the deny profile cannot restrict a stdio MCP's own
# tools): exa MUST carry an enabledTools= restriction AND that restriction must NOT re-enable an
# arbitrary-URL fetch tool. A bare presence check (any enabledTools= arg) is NOT enough — it passes
# enabledTools=["<fetch-tool>"], the exact egress tool the gate exists to remove (F25). We enforce
# fetch-tool ABSENCE generically (no hardcoded allowed-tool name = no smuggled specificity): the
# restriction is present AND no enabledTools= arg names a *fetch* tool.
# NOTE: the server KEY (.mcpServers.exa) is the donor catalog's search-egress server name — if the target
# account's search server key differs, rename it here + in drift-lib + the exa-egress-restriction flag name.
assert_exa_restricted(){
  local file="$1"
  jq -e '
    (.mcpServers.exa.args // []) as $a
    | ($a | any(startswith("enabledTools=")))
      and ($a | map(select(startswith("enabledTools="))) | all(ascii_downcase | contains("fetch") | not))
  ' "$file" >/dev/null \
    || { echo "✗ $file — exa egress gate missing or defeated: no search-only enabledTools= restriction, or one re-enables an arbitrary-URL fetch tool" >&2; exit 1; }
}

# assert_memory_endpoint FILE EXPECTED → the authored memory-backed mcp MUST point at the configured
# backend endpoint ({{MEMORY_BACKEND_URL_API}}), never a stray operator-machine URL (R3: the donor's
# localhost endpoint never ships). Empty EXPECTED (a squad with no memory backend) skips the check.
assert_memory_endpoint(){
  local file="$1" expected="$2"
  [[ -z "$expected" ]] && return 0
  grep -qF -- "$expected" "$file" \
    || { echo "✗ $file — memory backend endpoint does not match the configured MEMORY_BACKEND_URL_API ($expected)" >&2; exit 1; }
}

# assert_ambient_registry REGISTRY SERVER... → for ambient-registry runtimes (per-agent mcp_config is
# INERT), the seat's ENTIRE MCP surface is a registry no squad script owns. Assert each seat-critical
# server is still registered; warn LOUDLY (non-fatal) if any is gone — a card-promised capability lost.
assert_ambient_registry(){
  local reg="$1"; shift
  local srv
  for srv in "$@"; do
    if ! jq -e --arg s "$srv" '(.mcpServers // {}) | has($s)' "$reg" >/dev/null 2>&1; then
      echo "⚠  ambient registry $reg is MISSING '$srv' — an ambient-registry seat loses a card-promised capability" >&2
    fi
  done
}

# provision_agent — create-or-update one agent idempotently. Fields come in via PS_* globals the caller
# sets per seat (a named-field convention, not a 13-positional footgun). The dual-branch discipline is
# load-bearing: --custom-args is re-pinned in BOTH the create AND the update branch, or a re-apply
# silently drops a scripted run-fuse / deny-profile flag (the F20/mentor-1 regression).
#
#   PS_ID PS_NAME PS_RUNTIME_UUID PS_MODEL   — identity + placement
#   PS_EFFORT (e.g. "--thinking-level high", or "" when the lever is the model token / custom-args)
#   PS_CUSTOM_ARGS (a JSON array string, or "" — the hardened seats' --settings deny-profile flag rides
#   IN this array, per the seat-manifest custom-args rows)   PS_MCP_FILE (authored config, or "")
#   PS_MAX_CONC ("" to leave default)   PS_VISIBILITY ("" to leave default)
#   PS_INSTR_FILE (card to bootstrap a fresh seat)   PS_DESC (<=255 chars — the server 400s past it)
provision_agent(){
  local common=( )
  [[ -n "${PS_MODEL:-}"     ]] && common+=( --model "$PS_MODEL" )
  [[ -n "${PS_EFFORT:-}"    ]] && common+=( $PS_EFFORT )
  [[ -n "${PS_MAX_CONC:-}"  ]] && common+=( --max-concurrent-tasks "$PS_MAX_CONC" )
  [[ -n "${PS_MCP_FILE:-}"  ]] && common+=( --mcp-config-file "$PS_MCP_FILE" )
  [[ -n "${PS_CUSTOM_ARGS:-}" ]] && common+=( --custom-args "$PS_CUSTOM_ARGS" )
  [[ -n "${PS_DESC:-}"      ]] && common+=( --description "$PS_DESC" )
  if agent_exists "$PS_ID"; then
    run multica agent update "$PS_ID" --name "$PS_NAME" "${common[@]}"
  else
    local create=( --name "$PS_NAME" --runtime-id "$PS_RUNTIME_UUID" )
    [[ -n "${PS_VISIBILITY:-}" ]] && create+=( --visibility "$PS_VISIBILITY" )
    [[ -n "${PS_INSTR_FILE:-}" ]] && create+=( --instructions "$(cat "$PS_INSTR_FILE")" )
    run multica agent create "${create[@]}" "${common[@]}"
    echo "   NOTE: new id assigned — capture it into the manifest (SEAT_UUIDS) so re-runs update in place."
  fi
}
