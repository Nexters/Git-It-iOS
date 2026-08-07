#!/bin/sh
# Swift-Style 서브모듈 포매터/린터의 공개 진입점입니다.
#
#   staged           : 커밋에 staged된 *.swift 파일만 포맷하고 재검증합니다.
#   format [paths..] : 지정 경로(기본 Projects)를 포맷합니다. 인자가 없으면 저장소
#                       루트 기준 Projects/ 전체를 대상으로 합니다.
#   lint   [paths..] : 지정 경로(기본 Projects)를 수정 없이 검사만 합니다.
#
# 세 동작 모두 실제로는 Tools/swift-style/scripts/{format,lint}.sh를 호출하지만,
# 그 스크립트가 자기 자신(Tools/swift-style) 기준으로 cd하는 탓에 상대경로를
# 넘기면 바깥 저장소 경로를 못 찾습니다. 이 진입점은 core/style-adapter.sh를 통해
# 모든 대상을 절대경로로 변환해 호출하므로 어디서 실행하든 동일하게 동작합니다.

set -eu

swift_format_main() (
	if [ "$#" -lt 1 ]; then
		printf '오류[common.invalid-input]: ACTION 한 개가 필요합니다\n조치: staged, format, lint 공개 명령을 사용하세요\n' >&2
		return 2
	fi

	swift_format_action=$1
	shift

	# 1. 저장소 루트와 어댑터/서브모듈 경로를 확보합니다.
	swift_format_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	swift_format_root=$(git -C "$swift_format_bin" rev-parse --show-toplevel 2>/dev/null) || {
		printf '오류[common.invalid-input]: Git 저장소를 찾을 수 없습니다\n조치: 저장소 안에서 실행하세요\n' >&2
		return 2
	}
	swift_format_adapter="$swift_format_bin/../core/style-adapter.sh"
	swift_format_style_dir="$swift_format_root/Tools/swift-style"

	case "$swift_format_action" in
	staged | format) swift_format_tool="$swift_format_style_dir/scripts/format.sh" ;;
	lint) swift_format_tool="$swift_format_style_dir/scripts/lint.sh" ;;
	*)
		printf '오류[common.invalid-input]: 지원하지 않는 ACTION=%s\n조치: staged, format, lint 중 하나를 사용하세요\n' "$swift_format_action" >&2
		return 2
		;;
	esac

	[ -x "$swift_format_tool" ] || {
		printf '오류[common.missing-tool]: Swift-Style submodule이 초기화되지 않았습니다\n조치: git submodule update --init --recursive 를 실행하세요\n' >&2
		return 2
	}

	# 2. 대상 목록을 NUL 경계로 임시 파일에 기록합니다(경로에 공백을 허용).
	swift_format_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-swift-format.XXXXXX") || return 2
	trap 'rm -rf "$swift_format_work"' EXIT
	trap 'rm -rf "$swift_format_work"; exit 129' HUP
	trap 'rm -rf "$swift_format_work"; exit 130' INT
	trap 'rm -rf "$swift_format_work"; exit 143' TERM
	swift_format_targets="$swift_format_work/targets.nul"
	: >"$swift_format_targets"

	if [ "$swift_format_action" = staged ]; then
		git -C "$swift_format_root" diff --cached -z --name-only --diff-filter=ACMR -- '*.swift' \
			>"$swift_format_targets"
	elif [ "$#" -eq 0 ]; then
		printf '%s\0' Projects >"$swift_format_targets"
	else
		for swift_format_arg in "$@"; do
			printf '%s\0' "$swift_format_arg" >>"$swift_format_targets"
		done
	fi

	if [ ! -s "$swift_format_targets" ]; then
		printf '건너뜀[swift-format.no-targets]: 대상이 없습니다\n'
		return 0
	fi

	# 3. 대상마다 절대경로로 변환해 Swift-Style 도구를 실행합니다.
	xargs -0 -n 1 "$swift_format_adapter" --format-one "$swift_format_tool" "$swift_format_root" \
		<"$swift_format_targets" || {
		printf '오류[swift-format.formatter-failed]: Swift-Style 실행이 실패했습니다\n조치: 위 SwiftFormat/SwiftLint 출력을 확인하세요\n' >&2
		return 1
	}

	# 4. staged 모드는 포맷팅 후에도 작업 트리가 깨끗한지, 즉 재-add가 필요한지 확인합니다.
	if [ "$swift_format_action" = staged ]; then
		xargs -0 -n 1 "$swift_format_adapter" --verify-one "$swift_format_root" \
			<"$swift_format_targets" || return 1
		printf 'Swift 포맷팅 검증 완료.\n'
	fi
)

swift_format_main "$@"
