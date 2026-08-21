#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
root=$(CDPATH='' cd -- "$test_dir/../../.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/make-init-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/한글 저장소"
call_log="$work/calls"
ios_root='제품 소스 Fixture'

# 공백과 한글이 있는 격리 저장소에 Makefile과 공개 명령의 Test Double을 구성합니다.
mkdir -p "$repository/tools/repository-paths/bin" \
	"$repository/hooks/hook-management/bin" "$repository/$ios_root" "$work/bin"
cp "$root/Makefile" "$repository/Makefile"
# shellcheck disable=SC2016
printf '%s\n' \
	'#!/bin/sh' \
	'case "$1" in' \
	"GIT_IT_IOS_ROOT) printf '%s\\n' '$ios_root' ;;" \
	'GIT_IT_HOOKS_ROOT) printf "hooks\\n" ;;' \
	'GIT_IT_SWIFT_FORMAT_RUNNER) printf "./format.sh\\n" ;;' \
	'GIT_IT_PROJECT_SETUP_RUNNER) printf "./setup.sh\\n" ;;' \
	'*) exit 2 ;;' \
	'esac' >"$repository/tools/repository-paths/bin/repository-paths.sh"
# shellcheck disable=SC2016
printf '%s\n' \
	'#!/bin/sh' \
	'printf "tuist|%s|%s\\n" "$PWD" "$*" >>"$TEST_CALL_LOG"' >"$work/bin/tuist"
# shellcheck disable=SC2016
printf '%s\n' \
	'#!/bin/sh' \
	'printf "setup|%s\\n" "$*" >>"$TEST_CALL_LOG"' >"$repository/setup.sh"
# shellcheck disable=SC2016
printf '%s\n' \
	'#!/bin/sh' \
	'printf "hooks|install\\n" >>"$TEST_CALL_LOG"' \
	>"$repository/hooks/hook-management/bin/install.sh"
chmod +x "$repository/tools/repository-paths/bin/repository-paths.sh" \
	"$work/bin/tuist" "$repository/setup.sh" \
	"$repository/hooks/hook-management/bin/install.sh"
repository=$(CDPATH='' cd -- "$repository" && pwd -P)

# make init이 Tuist 편집 workspace까지 만든 뒤 나머지 초기화를 계속하는지 검증합니다.
TEST_CALL_LOG=$call_log PATH="$work/bin:$PATH" \
	make -s -C "$repository" init
printf '%s\n' \
	"tuist|$repository/$ios_root|install" \
	"tuist|$repository/$ios_root|generate" \
	"tuist|$repository/$ios_root|edit --permanent" \
	'setup|workspace-link' \
	'hooks|install' \
	'setup|developer-tools' >"$work/expected"
diff -u "$work/expected" "$call_log"

printf 'PASS: make init\n'
