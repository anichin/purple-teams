#!/bin/bash
# Cross-compile the Windows (Pidgin 2) DLLs in a Docker container.
# Mirrors .github/workflows/cross.yml.
#
# Usage (from the repo root, in Git Bash or WSL, with Docker running):
#   ./build-win32-docker.sh
#
# Output: build/libteams.dll, build/libteams-personal.dll, build/libjson-glib-1.0.dll
set -euo pipefail

if [ ! -f /.dockerenv ]; then
	cd "$(dirname "$0")"
	# Git Bash needs a Windows path for Docker Desktop; WSL/Linux use the normal one.
	REPO_DIR="$(pwd -W 2>/dev/null || pwd)"
	mkdir -p "$REPO_DIR/build"
	MSYS_NO_PATHCONV=1 exec docker run --rm \
		-v "$REPO_DIR:/repo:ro" \
		-v "$REPO_DIR/build:/out" \
		ubuntu:24.04 bash /repo/build-win32-docker.sh
fi

# Everything below runs inside the container. /repo = source (read-only), /out = output dir.
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq gcc-mingw-w64-i686-win32 make curl unzip bzip2 >/dev/null

mkdir -p /work && cd /work
cp -r /repo src

curl -sS --http1.1 -L https://sourceforge.net/projects/pidgin/files/Pidgin/2.14.1/pidgin-2.14.1.tar.bz2/download -o pidgin.tar.bz2
tar -xf pidgin.tar.bz2
mv pidgin-2.14.1 pidgin
curl -sS --http1.1 -L https://sourceforge.net/projects/pidgin/files/Pidgin/2.14.1/pidgin-2.14.1-win32-bin.zip/download -o pidgin-win32bin.zip
unzip -q pidgin-win32bin.zip
cp pidgin-2.14.1-win32bin/libpurple.dll pidgin/libpurple/

mkdir win32-dev
curl -sS --http1.1 -L https://download.gnome.org/binaries/win32/glib/2.28/glib-dev_2.28.8-1_win32.zip -o glib-dev.zip
unzip -q glib-dev.zip -d win32-dev/glib-2.28.8
curl -sS --http1.1 -L https://download.gnome.org/binaries/win32/dependencies/gettext-runtime-dev_0.18.1.1-2_win32.zip -o gettext-runtime.zip
unzip -q -o gettext-runtime.zip -d win32-dev/glib-2.28.8
curl -sS --http1.1 -L https://download.gnome.org/binaries/win32/dependencies/zlib-dev_1.2.5-2_win32.zip -o zlib-dev.zip
unzip -q -o zlib-dev.zip -d win32-dev/glib-2.28.8
curl -sS --http1.1 -L https://github.com/jgeboski/purple-facebook/releases/download/downloads/json-glib-0.14.tar.gz -o json-glib.tar.gz
tar -xf json-glib.tar.gz -C win32-dev

cd src
rm -f libteams.dll libteams-personal.dll
export WIN32_CC=i686-w64-mingw32-gcc
export WIN32_DEV_TOP=/work/win32-dev
export PIDGIN_TREE_TOP=/work/pidgin
make libteams.dll
make libteams-personal.dll

cp libteams.dll libteams-personal.dll libjson-glib-1.0.dll /out/
ls -l /out
