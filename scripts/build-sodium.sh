#!/bin/sh
# Pinned local dependency: no system installation.
set -eu
cd "$(dirname "$0")/.."
root=$(pwd)
version=1.0.22
sha=adbdd8f16149e81ac6078a03aca6fc03b592b89ef7b5ed83841c086191be3349
base="$root/build/sodium"
archive="$base/download/libsodium-$version.tar.gz"
case "$(uname -s)" in Darwin) default_platform=macos ;; Linux) default_platform=linux ;; *) default_platform=unsupported ;; esac
platform=${1:-$default_platform}
case "$platform" in macos|linux|iphoneos|iphonesimulator) ;; *) echo 'usage: build-sodium.sh [macos|linux|iphoneos|iphonesimulator]' >&2; exit 2 ;; esac
mkdir -p "$base/download"
if [ ! -f "$archive" ]; then
  curl --fail --location "https://download.libsodium.org/libsodium/releases/libsodium-$version.tar.gz" -o "$archive"
fi
if command -v sha256sum >/dev/null 2>&1; then
  printf '%s  %s\n' "$sha" "$archive" | sha256sum -c -
else
  printf '%s  %s\n' "$sha" "$archive" | shasum -a 256 -c -
fi
if [ ! -d "$base/libsodium-$version" ]; then tar -xzf "$archive" -C "$base"; fi
mkdir -p "$base/obj-$platform"
cd "$base/obj-$platform"
case "$platform" in
  linux)
    CC="${CC:-cc}" CFLAGS="${CFLAGS:--O2}" "$base/libsodium-$version/configure" \
      --prefix="$base/linux" --libdir="$base/linux/lib" --disable-shared --enable-static
    ;;
  *)
    case "$platform" in
      macos) sdk=macosx; flags="-arch $(uname -m) -mmacosx-version-min=13.0"; set -- ;;
      iphoneos) sdk=iphoneos; flags='-arch arm64 -miphoneos-version-min=17.0'; set -- --host=arm-apple-darwin ;;
      iphonesimulator) sdk=iphonesimulator; flags='-target arm64-apple-ios17.0-simulator'; set -- --host=arm-apple-darwin ;;
    esac
    CC="$(xcrun --sdk "$sdk" -f clang)" CFLAGS="-O2 $flags -isysroot $(xcrun --sdk "$sdk" --show-sdk-path)" \
      "$base/libsodium-$version/configure" "$@" --prefix="$base/$platform" \
      --libdir="$base/$platform/lib" --disable-shared --enable-static
    ;;
esac
make -j "${JOBS:-4}"
case "$platform" in macos|linux) make -j "${JOBS:-4}" check ;; esac
make install
