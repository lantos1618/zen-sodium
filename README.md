# zen-sodium

Zen bindings and byte-buffer helpers for libsodium. Cryptographic operations
execute in the linked libsodium library; this package does not implement them
in Zen. Native Zen algorithms belong in the separate `zen-crypto` package.

The `sodium` module exports direct header bindings through `Sodium`, plus
`initialize`, `wipe`, `equal`, and `decode_secret_hex`. The bound operations cover
XChaCha20-Poly1305 AEAD, key exchange, generic hashing, authentication, random
bytes, comparison, and erasure. This is a selected API surface, not complete
libsodium coverage. It contains no handwritten C crypto wrappers.

Initialize libsodium before use. Callers own buffers and must provide the sizes
and lifetimes required by each bound C API. The helpers do not turn raw pointers
into checked slices. `equal` and `wipe` call libsodium; the package makes no
whole-program constant-time or secure-memory ownership guarantee. Secret hex
decoding requires an exact-length string and wipes the output on failure.

## Build and test

A Zen compiler and its matching standard library are required. The default
layout places the compiler in sibling `zen-actor-runtime`; overrides work with
other checkouts:

```sh
sh scripts/build-sodium.sh
ZEN_COMPILER=/path/to/zen ZEN_STD=/path/to/zen/src sh scripts/check-sodium.sh
```

The dependency script verifies the pinned libsodium **1.0.22** archive SHA-256
and builds a static library under ignored `build/sodium/<platform>`. It supports
native Linux and macOS builds, plus ARM64 iOS/device-simulator cross-compilation
using Xcode. Native builds run libsodium's own `make check`; cross-builds cannot
run that suite on the build host. `JOBS`, Linux `CC`, and Linux `CFLAGS` may be
set. Nothing installs into the system.

The binding test compiles generated C with UBSan and checks a libsodium AEAD
known-answer vector, ciphertext tampering, associated-data mismatch, key
exchange, invalid peer keys, an independent empty-input hash vector,
authentication, erasure, and strict secret hex decoding. Set `SODIUM_PREFIX` to
an existing prefix containing `include/` and `lib/libsodium.a` to reuse a build.
These checks do not constitute a security audit.

Consumers can stage `src/sodium.zen` into their Zen module root and compile the
generated C with the matching libsodium include path and static library. The
module remains named `sodium`; extraction from `zen-crypto` does not rename its
exports. Package-manager integration and a higher-level checked-buffer API are
not supplied here.

## Validation status

The extracted binding suite passed on macOS ARM64 with UBSan using an existing
pinned libsodium 1.0.22 build. The Linux build branch and Apple cross-build
branches are supplied but have not yet been rerun for this repository.
