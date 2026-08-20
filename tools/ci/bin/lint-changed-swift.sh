#!/bin/sh
# PR에서 변경된 Swift 파일만 NUL-safe하게 lint 공개 명령으로 전달합니다.

set -eu

lint_changed_swift_main() (
	[ "$#" -eq 2 ] || {
		printf '오류[ci.lint-changed-swift.invalid-input]: base-sha와 head-sha가 필요합니다\n' >&2
		return 2
	}
	lint_base=$1
	lint_head=$2
	lint_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	lint_root=$(git -C "$lint_bin" rev-parse --show-toplevel 2>/dev/null) || return 2
	lint_paths="$lint_root/tools/repository-paths/bin/repository-paths.sh"
	lint_runner=$("$lint_paths" --absolute GIT_IT_SWIFT_FORMAT_RUNNER) || return $?

	git -C "$lint_root" cat-file -e "${lint_base}^{commit}" 2>/dev/null || return 1
	git -C "$lint_root" cat-file -e "${lint_head}^{commit}" 2>/dev/null || return 1
	lint_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-ci-lint.XXXXXX") || return 2
	trap 'rm -rf "$lint_work"' EXIT
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
	lint_files="$lint_work/swift-files.nul"

	# 삭제된 파일은 제외하고 경로 경계를 유지한 채 공개 runner에 전달합니다.
	git -C "$lint_root" diff --name-only -z --diff-filter=ACMR "$lint_base" "$lint_head" -- '*.swift' >"$lint_files" || return 1
	if [ ! -s "$lint_files" ]; then
		printf '건너뜀[ci.lint-changed-swift.no-targets]: 변경 Swift 파일이 없습니다\n'
		return 0
	fi
	xargs -0 "$lint_runner" lint <"$lint_files"
)

lint_changed_swift_main "$@"
