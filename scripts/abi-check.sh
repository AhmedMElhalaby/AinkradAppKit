#!/usr/bin/env bash
#
# Evaluates swift-api-digester's report and decides pass/fail.
#
# ## Why this is a script and not a grep
#
# The Makefile used to decide with `grep -q "has been" abi/report.txt`. That
# catches the *phrasing* of removals ("Func X has been removed") and nothing
# else. The digester reports breakage in a dozen sections, and several of the
# highest-risk ones never use that phrase:
#
#   /* Protocol Requirement Change */   "Protocol AinkradApp has added a
#                                        required method ..."
#   /* Protocol Conformance Change */
#   /* Fixed-layout Type Changes */
#   /* Class Inheritance Change */
#
# Added protocol requirements are precisely the ABI cliff that library
# evolution does NOT cover — an existing plugin binary has no witness for a new
# requirement and fails to load. So the one class of break the guardrail most
# needed to catch was the one its grep could not see.
#
# This flips the logic: **any** residual line is a failure unless it matches an
# explicit, reviewed ignore pattern. Fail-closed, like the rest of the system.
set -euo pipefail

cd "$(dirname "$0")/.."

REPORT="${1:-abi/report.txt}"
IGNORE_FILE="abi/report-ignore.txt"

[[ -f "$REPORT" ]] || { echo "abi-check: no report at $REPORT" >&2; exit 1; }

# Strip: blank lines, section headers (`/* ... */`), and reviewed ignores.
FILTER=(grep -vE '^[[:space:]]*$|^[[:space:]]*/\*.*\*/[[:space:]]*$')
residual="$("${FILTER[@]}" "$REPORT" || true)"

if [[ -f "$IGNORE_FILE" ]]; then
  # Ignore patterns are extended regexes, one per line; `#` starts a comment.
  patterns="$(grep -vE '^[[:space:]]*(#|$)' "$IGNORE_FILE" || true)"
  if [[ -n "$patterns" ]]; then
    residual="$(printf '%s\n' "$residual" | grep -vE -f <(printf '%s\n' "$patterns") || true)"
  fi
fi

residual="$(printf '%s' "$residual" | sed '/^[[:space:]]*$/d')"

if [[ -n "$residual" ]]; then
  echo "ABI CHECK FAILED — unreviewed API/ABI changes vs the committed baseline:"
  echo
  printf '%s\n' "$residual"
  echo
  echo "If these are intentional:"
  echo "  • a source-compatible addition  -> add a pattern to $IGNORE_FILE"
  echo "  • a real ABI break              -> bump the SDK generation and repin every plugin"
  echo "  • baseline is simply stale      -> make abi-baseline (review the diff!)"
  exit 1
fi

echo "abi-check: no unreviewed API/ABI changes"
