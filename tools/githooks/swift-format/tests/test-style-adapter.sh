#!/bin/sh
# shellcheck disable=SC1091

set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
. "$module/core/style-adapter.sh"
root=$(CDPATH='' cd -- "$module/../../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
projects=$("$paths" GIT_IT_PROJECTS_ROOT)

assert_equal() {
	[ "$1" = "$2" ] || {
		printf 'FAIL: %s expected=%s actual=%s\n' "$3" "$1" "$2" >&2
		exit 1
	}
}

assert_equal "/repo/$projects/App/Foo.swift" \
	"$(style_adapter_absolute /repo "$projects/App/Foo.swift")" '상대경로를 저장소 루트 기준 절대경로로 변환'
assert_equal '/other/App.swift' \
	"$(style_adapter_absolute /repo /other/App.swift)" '이미 절대경로면 그대로 유지'
assert_equal "/repo/$projects" \
	"$(style_adapter_absolute /repo "$projects")" '디렉터리 인자도 동일하게 변환'

work=$(mktemp -d "${TMPDIR:-/tmp}/swift-format-targets-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/Sources/Derived" "$work/Sources/.build" "$work/Sources/Feature"
: >"$work/Sources/Derived/Generated.swift"
: >"$work/Sources/.build/Package.swift"
: >"$work/Sources/Feature/유지 파일.swift"
style_adapter_collect_one "$work" "$work/targets.nul" "$work/Sources"
printf '%s\0' "$work/Sources/Feature/유지 파일.swift" >"$work/expected.nul"
cmp "$work/expected.nul" "$work/targets.nul"

# 제외 경로만 지정해도 포맷터에 전달할 대상이 생기지 않아야 합니다.
style_adapter_collect_one "$work" "$work/excluded.nul" "$work/Sources/Derived"
[ ! -s "$work/excluded.nul" ]

printf 'PASS: swift-format style-adapter\n'
