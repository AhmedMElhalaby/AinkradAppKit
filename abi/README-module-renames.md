# Module renames are ABI breaks that both guardrails miss

Swift mangles the **module name** into every symbol it emits. Moving a public
type from module `A` to module `B` therefore renames every symbol that
mentions it, even though nothing about the type changed. An already-compiled
client references the old names, they no longer exist, and the dynamic load
fails outright.

This bit us in generation 8. Splitting `AinkradAppKit` into
`AinkradAppKitContract` + `AinkradAppKitUI` was believed additive and
source-compatible — it *is* source-compatible; the umbrella re-exports both, so
every consumer compiled unchanged. But a plugin binary built against generation
7 references 71 `AinkradAppKit…` symbols that generation 8 does not export, so
`Bundle.load()` returns false. Confirmed by `nm -u` on a stale versus a fresh
plugin, and by loading both into a signed hardened-runtime host.

## Why neither guardrail saw it

- **`make abi-check`** diffs `AinkradAppKitContract` against a baseline that was
  regenerated *from that same module* in the same change. Contract-vs-contract:
  the move out of `AinkradAppKit` was never in view. The digester compares one
  module to a baseline of one module; it has no concept of "this type used to
  live somewhere else".
- **`ContractFreezeTests`** asserts source-level shape — that a generation-7
  app still satisfies `AinkradApp`, that new capability arrives by cast rather
  than as a protocol requirement. All still true after a rename. Source
  compatibility and ABI compatibility are different properties, and this is
  exactly where they diverge.

## The rule

**Any change to the set of module names is a hard generation break.** Set
`minSupportedAPIVersion == apiVersion` for that generation; do not offer a
deprecation window you cannot honour. A window that lets a bundle pass the
version check and then fail to link is worse than no window: the user sees
"failed to load" instead of "update this app".

## How to check before shipping

Compare the module names a released plugin actually imports against those the
new SDK exports:

    nm -u <plugin>/Contents/MacOS/<plugin> | grep -oE 'AinkradAppKit[A-Za-z]*' \
      | sort -u

Any name in that list which the new SDK no longer exports is a break, however
additive the source diff looks.
