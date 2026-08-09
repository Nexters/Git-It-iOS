#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
root=$(CDPATH='' cd -- "$module/../.." && pwd -P)
paths="$module/bin/repository-paths.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/repository-path-literals-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
matches="$work/matches"
: >"$matches"

# 중앙 JSON의 구체 경로값이 실행 스크립트나 CI에 복제되지 않도록 검사합니다.
for key in \
	GIT_IT_IOS_ROOT \
	GIT_IT_PROJECTS_ROOT \
	GIT_IT_TUIST_ROOT \
	GIT_IT_WORKSPACE_PATH \
	GIT_IT_DERIVED_DATA_PATH \
	GIT_IT_SWIFT_STYLE_ROOT \
	GIT_IT_HOOKS_ROOT \
	GIT_IT_ARCHITECTURE_PATH \
	GIT_IT_SWIFT_FORMAT_RUNNER \
	GIT_IT_PROJECT_BUILD_RUNNER \
	GIT_IT_SCRIPT_VERIFICATION_RUNNER; do
	value=$("$paths" "$key")
	if rg -n -F --hidden --glob '!.git/**' --glob '!**/DerivedData/**' \
		--glob '!**/.build/**' \
		--glob '*.sh' --glob '*.bash' --glob '*.zsh' --glob '*.py' \
		--glob '*.rb' --glob '*.pl' --glob '*.yml' --glob '*.yaml' \
		--glob '*.xcconfig' --glob 'Makefile' --glob 'Justfile' \
		--glob 'pre-commit' --glob 'commit-msg' \
		"$value" "$root" \
		>>"$matches"; then
		:
	else
		result=$?
		[ "$result" -eq 1 ] || exit "$result"
	fi
done

# workspace 이름만 정책에 복제하는 경우도 경로 설정 변경을 막으므로 금지합니다.
workspace=$("$paths" GIT_IT_WORKSPACE_PATH)
workspace_name=${workspace##*/}
if rg -n -F --hidden --glob '!.git/**' --glob '!**/DerivedData/**' \
	--glob '!**/.build/**' \
	--glob '*.sh' --glob '*.bash' --glob '*.zsh' --glob '*.py' \
	--glob '*.rb' --glob '*.pl' --glob '*.yml' --glob '*.yaml' \
	--glob '*.xcconfig' --glob 'Makefile' --glob 'Justfile' \
	--glob 'pre-commit' --glob 'commit-msg' \
	"$workspace_name" "$root" \
	>>"$matches"; then
	:
else
	result=$?
	[ "$result" -eq 1 ] || exit "$result"
fi

[ ! -s "$matches" ] || {
	printf 'FAIL: 중앙 JSON 밖에 저장소 경로가 하드코딩됨\n' >&2
	cat "$matches" >&2
	exit 1
}

printf 'PASS: no hardcoded repository paths\n'
