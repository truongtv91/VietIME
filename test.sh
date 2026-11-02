#!/bin/zsh
cd "$(dirname $0)"
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-/tmp/mcache}
swiftc tests/main.swift src/Telex.swift -o /tmp/vietime_test && /tmp/vietime_test
