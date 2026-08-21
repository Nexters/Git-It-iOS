#!/bin/sh
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
root=$(CDPATH='' cd -- "$test_dir/../../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
ios_relative=$("$paths" GIT_IT_IOS_ROOT)
work=$(mktemp -d "${TMPDIR:-/tmp}/ci-pre-push-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/tools/ci/bin" "$repository/tools/repository-paths/bin" "$repository/tools/runners" \
	"$repository/$ios_relative"
cp "$root/tools/ci/bin/pre-push.sh" "$repository/tools/ci/bin/pre-push.sh"

# fixture 공개 명령은 호출 순서와 인자를 기록하고 UI test만 실패시켜 계속 실행을 검증합니다.
printf '%s\n' '#!/bin/sh' \
	'set -eu' \
	'printf "scripts_changed=false\nswift_changed=true\nui_changed=true\nproject_config_changed=false\ntests_changed=true\n"' \
	>"$repository/tools/ci/bin/classify-changes.sh"
# shellcheck disable=SC2016
printf '%s\n' '#!/bin/sh' 'set -eu' 'printf "lint:%s:%s\n" "$1" "$2" >>"$CALL_LOG"' \
	>"$repository/tools/ci/bin/lint-changed-swift.sh"
# shellcheck disable=SC2016
printf '%s\n' '#!/bin/sh' \
	'set -eu' \
	'[ "$1" = --absolute ] && shift' \
	'case "$1" in' \
	'GIT_IT_SWIFT_FORMAT_RUNNER) printf "%s\n" "$FIXTURE_ROOT/tools/runners/format" ;;' \
	'GIT_IT_PROJECT_BUILD_RUNNER) printf "%s\n" "$FIXTURE_ROOT/tools/runners/build" ;;' \
	'GIT_IT_SCRIPT_TEST_RUNNER) printf "%s\n" "$FIXTURE_ROOT/tools/runners/script-tests" ;;' \
	'GIT_IT_SCRIPT_VERIFICATION_RUNNER) printf "%s\n" "$FIXTURE_ROOT/tools/runners/script-quality" ;;' \
	'GIT_IT_IOS_ROOT) printf "%s\n" "$FIXTURE_ROOT/$FIXTURE_IOS_RELATIVE" ;;' \
	'*) exit 2 ;;' \
	'esac' >"$repository/tools/repository-paths/bin/repository-paths.sh"
for runner in format build script-tests script-quality tuist; do
	# shellcheck disable=SC2016
	printf '%s\n' '#!/bin/sh' 'set -eu' \
		'printf "%s:%s\n" "$(basename -- "$0")" "$*" >>"$CALL_LOG"' \
		'if [ -n "${GIT_IT_XCRESULTS_PATH:-}" ]; then printf "xcresults:%s\n" "$GIT_IT_XCRESULTS_PATH" >>"$CALL_LOG"; fi' \
		'if [ "$(basename -- "$0")" = format ]; then printf "\n" >>"$2"; fi' \
		'if [ "$(basename -- "$0")" = build ] && [ "$1" = test-ui ]; then exit 1; fi' \
		>"$repository/tools/runners/$runner"
done
chmod +x "$repository/tools/ci/bin/pre-push.sh" "$repository/tools/ci/bin/classify-changes.sh" \
	"$repository/tools/ci/bin/lint-changed-swift.sh" "$repository/tools/repository-paths/bin/repository-paths.sh" \
	"$repository/tools/runners/"*
git -C "$repository" init -q
git -C "$repository" config user.name test
git -C "$repository" config user.email test@example.com
printf 'struct Base {}\n' >"$repository/$ios_relative/Base.swift"
git -C "$repository" add .
git -C "$repository" commit -qm base
base=$(git -C "$repository" rev-parse HEAD)
git -C "$repository" update-ref refs/remotes/origin/develop "$base"
printf 'struct Changed {}\n' >"$repository/$ios_relative/Changed.swift"
git -C "$repository" add "$ios_relative/Changed.swift"
git -C "$repository" commit -qm changed

CALL_LOG="$work/calls"
FIXTURE_ROOT="$repository"
FIXTURE_IOS_RELATIVE="$ios_relative"
export CALL_LOG FIXTURE_ROOT FIXTURE_IOS_RELATIVE
if (cd "$repository" && PATH="$repository/tools/runners:$PATH" ./tools/ci/bin/pre-push.sh >"$work/out" 2>"$work/err"); then
	printf 'FAIL: UI test 실패를 pre-push 성공으로 반환\n' >&2
	exit 1
fi
rg -Fqx "format:format $ios_relative/Changed.swift" "$CALL_LOG"
rg -q '^lint:origin/develop:' "$CALL_LOG"
for action in build-app compile-unit test-unit compile-ui test-ui; do
	rg -qx "build:$action" "$CALL_LOG"
done
rg -Fqx "xcresults:$repository/$ios_relative/DerivedData/PrePushTestResults" "$CALL_LOG"
rg -qx 'tuist:install' "$CALL_LOG"
rg -qx 'tuist:generate --no-open' "$CALL_LOG"
rg -Fq '| ui-tests | failure:1 |' "$work/out"
rg -Fq '| swift-format | failure:3 |' "$work/out"
rg -q 'format-corrected' "$work/err"
rg -q 'ci.pre-push.failed' "$work/err"
printf 'PASS: CI pre-push runner\n'
