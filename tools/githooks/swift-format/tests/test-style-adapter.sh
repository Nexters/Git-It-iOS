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

# 최초 실행: .build가 없으면 조용히 marker만 남기고 기존 내용은 건드리지 않습니다.
cache_dir=$(mktemp -d "${TMPDIR:-/tmp}/swift-format-cache-test.XXXXXX")
trap 'rm -rf "$work" "$cache_dir"' EXIT HUP INT TERM
style_dir="$cache_dir/style"
mkdir -p "$style_dir"
style_adapter_ensure_fresh_build_cache "$style_dir"
assert_equal "$style_dir" "$(cat "$style_dir/.build/.git-it-build-root")" \
	'최초 실행은 현재 경로를 marker에 기록'

# marker가 현재 경로와 같으면 기존 .build 내용을 보존합니다.
: >"$style_dir/.build/kept-artifact"
style_adapter_ensure_fresh_build_cache "$style_dir"
[ -f "$style_dir/.build/kept-artifact" ] || {
	printf 'FAIL: marker가 일치하면 기존 .build를 보존해야 합니다\n' >&2
	exit 1
}

# marker가 다른 경로를 가리키면(저장소 이동/재클론) .build를 통째로 지우고 새로 만듭니다.
printf '%s' "$style_dir-old-location" >"$style_dir/.build/.git-it-build-root"
style_adapter_ensure_fresh_build_cache "$style_dir"
[ -f "$style_dir/.build/kept-artifact" ] && {
	printf 'FAIL: marker가 다르면 .build를 초기화해야 합니다\n' >&2
	exit 1
}
assert_equal "$style_dir" "$(cat "$style_dir/.build/.git-it-build-root")" \
	'경로 불일치 초기화 후 새 경로를 marker에 기록'

printf 'PASS: swift-format style-adapter\n'
