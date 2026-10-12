---
title: 'Debugging Nix derivations'
date: 2025-09-09
last_modified_at: 2025-11-23
related:
  - _posts/2024-10-27-nix-hashes.md
---

A living collection of tips to debug Nix derivations.

## More verbose traces

It is helpful to run `nix build` with the flags `--show-trace
--print-build-logs -v`.

## `breakpointHook`

Instead of stopping when a failure occurs, [`breakpointHook`][0] will let you
attach to the build process (the last line of the logs will print the command
to do that).

```nix
nativeBuildInputs = [ breakpointHook ];
```

It is only available in Linux.

## Tracing all commands

Set `NIX_DEBUG = 7;` anywhere in your derivation. This [sets `-x` on
`stdenv`][3] initialization and can be very verbose. Experiment with lower
values to reduce verbosity.

## Tracing a specific value

[`builtins.trace`][4] takes a value, traces it, and returns its second value.

The [`lib.debug`][5] library functions in Nixpkgs provide a few more tools,
e.g. to trace a value based on a condition (`lib.debug.traceIf`) or to trace a
value and return it (`lib.debug.traceVal`).

## References

- [Debug a failed derivation with `breakpointHook` and `cntr`][1]
- [Debugging Derivations and Nix Expressions][2]

[0]: https://nixos.org/manual/nixpkgs/stable/#breakpointhook
[1]: https://discourse.nixos.org/t/debug-a-failed-derivation-with-breakpointhook-and-cntr/8669
[2]: https://nixos-and-flakes.thiscute.world/best-practices/debugging
[3]: https://nixos.org/manual/nixpkgs/stable/#var-stdenv-NIX_DEBUG
[4]: https://teu5us.github.io/nix-lib.html#builtins.trace
[5]: https://ryantm.github.io/nixpkgs/functions/library/debug/#sec-functions-library-debug
