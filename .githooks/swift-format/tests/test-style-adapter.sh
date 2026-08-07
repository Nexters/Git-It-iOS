#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
. "$root/.githooks/swift-format/core/style-adapter.sh"

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: %s expected=%s actual=%s\n' "$3" "$1" "$2" >&2
		exit 1
	}
}

assert_equal '/repo/Projects/App/Foo.swift' \
	"$(style_adapter_absolute /repo Projects/App/Foo.swift)" '상대경로를 저장소 루트 기준 절대경로로 변환'
assert_equal '/other/App.swift' \
	"$(style_adapter_absolute /repo /other/App.swift)" '이미 절대경로면 그대로 유지'
assert_equal '/repo/Projects' \
	"$(style_adapter_absolute /repo Projects)" '디렉터리 인자도 동일하게 변환'

printf 'PASS: swift-format style-adapter\n'
