#!/bin/sh

set -eu

BASE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OS=$(uname -s)
ARCH=$(uname -m)
DISTRO=unknown

if [ "$OS" = "Linux" ] && [ -r /etc/os-release ]; then
    . /etc/os-release
    DISTRO=${ID:-unknown}
fi

SCRIPT=

case "$OS:$DISTRO:$ARCH" in
    Linux:ubuntu:aarch64|Linux:ubuntu:arm64)
        SCRIPT="$BASE_DIR/autostart/ubuntu_aarch64.sh"
        ;;
    Linux:ubuntu:x86_64|Linux:ubuntu:amd64)
        SCRIPT="$BASE_DIR/autostart/ubuntu_x64.sh"
        ;;
    Linux:arch:x86_64|Linux:arch:amd64)
        SCRIPT="$BASE_DIR/autostart/arch_x64.sh"
        ;;
esac

if [ -z "$SCRIPT" ] || [ ! -x "$SCRIPT" ]; then
    exit 0
fi

exec sh "$SCRIPT" --display-layout
