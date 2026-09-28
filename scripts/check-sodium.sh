#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
compiler=${ZEN_COMPILER:-../zen-actor-runtime/zen}
export ZEN_STD=${ZEN_STD:-../zen-actor-runtime/src}
case "$(uname -s)" in Darwin) platform=macos ;; Linux) platform=linux ;; *) echo 'Unsupported test host' >&2; exit 2 ;; esac
prefix=${SODIUM_PREFIX:-build/sodium/$platform}
if [ ! -f "$prefix/lib/libsodium.a" ]; then
  if [ -n "${SODIUM_PREFIX:-}" ]; then echo "Missing $prefix/lib/libsodium.a" >&2; exit 1; fi
  sh scripts/build-sodium.sh "$platform"
fi
mkdir -p build
"$compiler" build src --std "$ZEN_STD" --entry ../tests/sodium_test.zen --emit-c -o build/sodium_test.c
${CC:-clang} -O2 -fsanitize=undefined -fno-sanitize-recover=all -I"$prefix/include" \
  build/sodium_test.c "$prefix/lib/libsodium.a" -o build/sodium_test
build/sodium_test
