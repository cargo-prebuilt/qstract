#!/bin/bash

### Accepts in params (env vars) VERSION, INSTALL_PATH, LIBC, ARCH, OS_TYPE, FORCE, R_TARGET.
### VERSION: Version of qstract to install. (Defaults to latest)
### INSTALL_PATH: Path to where qstract should be installed.
### LIBC: Which libc flavor to use. (gnu or musl) (Does nothing on macos)
### TARGET_STRING: The target type of qstract you want to download.

set -euxo pipefail

# Check if qstract is installed already
if qstract --version; then
    if [ -z ${FORCE+x}]; then
        echo "qstract is already installed on this system."
        echo "Use 'export FORCE=true' then run this script again to overwrite."
        exit 1
    fi
fi

# Start
L_URL="https://github.com/cargo-prebuilt/qstract/releases/latest/download/"
V_URL="https://github.com/cargo-prebuilt/qstract/releases/download/v"

: ${VERSION:="latest"}

: ${ARCH:="$(uname -m)"}
: ${OS_TYPE:="$(uname -s)"}
: ${LIBC:="gnu"}

if [ -z $TARGET_STRING ]; then
    # Build target string
    TARGET_STRING=""

    case "$ARCH" in
    arm64 | aarch64)
        TARGET_STRING+="aarch64-"
        ;;
    amd64 | x86_64)
        TARGET_STRING+="x86_64-"
        ;;
    riscv64 | riscv64gc)
        TARGET_STRING+="riscv64gc-"
        ;;
    s390x)
        TARGET_STRING+="s390x-"
        ;;
    armv7l | armv7)
        TARGET_STRING+="armv7-"
        ;;
    ppc64le | powerpc64le)
        TARGET_STRING+="powerpc64le-"
        ;;
    mips64 | mips64el)
        TARGET_STRING+="mips64el-"
        ;;
    *)
        echo "Unsupported Arch: $ARCH" && popd && exit 1
        ;;
    esac

    case "$OS_TYPE" in
    Darwin)
        TARGET_STRING+="apple-darwin"
        ;;
    Linux)
        TARGET_STRING+="unknown-linux-"
        ;;
    FreeBSD)
        TARGET_STRING+="unknown-freebsd"
        ;;
    NetBSD)
        TARGET_STRING+="unknown-netbsd"
        ;;
    MINGW64* | MSYS_NT*)
        TARGET_STRING+="pc-windows-gnu"
        ;;
    *)
        echo "Unsupported OS: $OS_TYPE" && popd && exit 1
        ;;
    esac

    if [ "$OS_TYPE" == "Linux" ]; then
        TARGET_STRING+="$LIBC"
        case "$ARCH" in
        armv7l | armv7)
            TARGET_STRING+="eabihf"
            ;;
        mips64 | mips64el)
            TARGET_STRING+="abi64"
            ;;
        esac
    fi
fi

echo "Determined target: $TARGET_STRING"

# Determine url
URL=""
if [ "$VERSION" == "latest" ]; then
    URL+="$L_URL"
else
    URL+="$V_URL$VERSION/"
fi

# Download
BIN_URL="$URL"'qstract-'"$TARGET_STRING"

curl --proto '=https' --tlsv1.2 -fsSL "$BIN_URL" -o $INSTALL_PATH/qstract
