#!/bin/sh
# shellcheck disable=SC2329
# cleanup은 EXIT·signal trap에서 간접 호출합니다.
# Swift-Style 서브모듈 포매터/린터의 공개 진입점입니다.
#
#   staged           : 커밋에 staged된 *.swift 파일만 포맷하고 재검증합니다.
#   format [paths..] : 현재 변경된 Swift 파일만 포맷합니다. 경로를 지정하면 그 범위로
#                      대상을 더 좁힙니다(기본 GIT_IT_PROJECTS_ROOT).
#   lint   [paths..] : 지정 경로(기본 GIT_IT_PROJECTS_ROOT)를 수정 없이 검사만 합니다.
#                     두 동작 모두 Derived/와 .build/ 하위 생성물은 제외합니다.
#
# 세 동작은 GIT_IT_SWIFT_STYLE_ROOT의 도구를 호출합니다. 도구가 자기 위치를 기준으로
# 상대경로를 해석하므로 이 진입점은 모든 대상을 절대경로로 변환해 전달합니다.

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
	swift_format_module=$(CDPATH='' cd -- "$swift_format_bin/.." && pwd -P)
	swift_format_adapter="$swift_format_module/core/style-adapter.sh"
	swift_format_paths="$swift_format_root/tools/repository-paths/bin/repository-paths.sh"
	[ -x "$swift_format_paths" ] || {
		printf '오류[repository-paths.missing-reader]: %s를 실행할 수 없습니다\n조치: 저장소 공용 경로 판독 명령을 복원하세요\n' \
			"$swift_format_paths" >&2
		return 2
	}

	# JSON 기본값과 환경변수 override를 실행용 절대경로로 읽습니다.
	swift_format_projects=$("$swift_format_paths" --absolute GIT_IT_PROJECTS_ROOT) || return $?
	swift_format_style_dir=$("$swift_format_paths" --absolute GIT_IT_SWIFT_STYLE_ROOT) || return $?

	# 저장소 이동/재클론으로 Swift-Style submodule의 빌드 캐시가 예전 경로를 가리키면
	# 도구 실행 전에 초기화합니다.
	"$swift_format_adapter" --ensure-fresh-cache "$swift_format_style_dir" || return 2

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
	swift_format_cleanup_enabled=true
	swift_format_cleanup() {
		[ "$swift_format_cleanup_enabled" != true ] || rm -rf "$swift_format_work"
	}
	trap 'swift_format_cleanup' EXIT
	trap 'swift_format_cleanup; exit 129' HUP
	trap 'swift_format_cleanup; exit 130' INT
	trap 'swift_format_cleanup; exit 143' TERM
	swift_format_requested="$swift_format_work/requested.nul"
	swift_format_targets="$swift_format_work/targets.nul"
	swift_format_backup="$swift_format_work/backup"
	swift_format_ledger="$swift_format_work/rollback.nul"
	: >"$swift_format_requested"
	: >"$swift_format_targets"
	: >"$swift_format_ledger"

	# 실패·중단 시 staged 대상 전체를 invocation 전 상태로 되돌립니다.
	swift_format_rollback() {
		[ -s "$swift_format_ledger" ] || return 0
		if xargs -0 -n 2 "$swift_format_adapter" --restore-one "$swift_format_backup" \
			<"$swift_format_ledger"; then
			: >"$swift_format_ledger"
			printf '복구[swift-format.rollback-complete]: staged 대상의 원본과 metadata를 복원했습니다\n' >&2
			return 0
		fi
		swift_format_cleanup_enabled=false
		printf '오류[swift-format.rollback-failed]: staged 대상 전체를 복원하지 못했습니다\nbackup: %s\n조치: Git diff와 backup을 확인해 원본을 복구한 뒤 임시 디렉터리를 제거하세요\n' \
			"$swift_format_work" >&2
		return 1
	}

	if [ "$swift_format_action" = staged ]; then
		git -C "$swift_format_root" diff --cached -z --name-only --diff-filter=ACMR -- '*.swift' \
			>"$swift_format_requested"
	elif [ "$#" -eq 0 ]; then
		printf '%s\0' "$swift_format_projects" >"$swift_format_requested"
	else
		for swift_format_arg in "$@"; do
			printf '%s\0' "$swift_format_arg" >>"$swift_format_requested"
		done
	fi

	# 2. 생성 산출물(Derived, .build)은 prune하고 실제 Swift 파일만 대상에 남깁니다.
	if [ -s "$swift_format_requested" ]; then
		xargs -0 -n 1 "$swift_format_adapter" --collect-one "$swift_format_root" \
			"$swift_format_targets" <"$swift_format_requested" || return 2
	fi

	# 일반 포맷은 수집한 후보 중 현재 작업 트리에서 추가·수정된 파일만 남깁니다.
	# staged는 index 기준 대상과 backup/rollback 계약을 그대로 유지합니다.
	if [ "$swift_format_action" = format ] && [ -s "$swift_format_targets" ]; then
		swift_format_changed_targets="$swift_format_work/changed-targets.nul"
		: >"$swift_format_changed_targets"
		xargs -0 -n 1 "$swift_format_adapter" --collect-changed-one "$swift_format_root" \
			"$swift_format_changed_targets" <"$swift_format_targets" || return 2
		mv "$swift_format_changed_targets" "$swift_format_targets" || return 2
	fi

	if [ ! -s "$swift_format_targets" ]; then
		printf '건너뜀[swift-format.no-targets]: 대상이 없습니다\n'
		return 0
	fi

	# staged 모드는 파일을 바꾸기 전에 모든 원본을 backup하고 NUL ledger로 연결합니다.
	if [ "$swift_format_action" = staged ]; then
		mkdir -p "$swift_format_backup" || return 2
		xargs -0 -n 1 "$swift_format_adapter" --backup-one \
			"$swift_format_backup" "$swift_format_ledger" "$swift_format_root" \
			<"$swift_format_targets" || {
			printf '오류[swift-format.backup-failed]: staged 대상의 원본을 보존하지 못했습니다\n조치: 대상 경로와 임시 디렉터리 권한을 확인하세요\n' >&2
			return 2
		}
		trap 'swift_format_rollback || :; swift_format_cleanup; exit 129' HUP
		trap 'swift_format_rollback || :; swift_format_cleanup; exit 130' INT
		trap 'swift_format_rollback || :; swift_format_cleanup; exit 143' TERM
	fi

	# 3. 대상 전체를 절대경로로 변환한 뒤 Swift-Style 도구를 한 번만 실행합니다.
	# 대상마다 도구를 재기동하면 프로세스 기동 비용이 대상 수만큼 반복되므로,
	# 절대경로 변환만 대상별로 수행하고 포맷/린트 실행 자체는 배치로 묶습니다.
	swift_format_absolute_targets="$swift_format_work/absolute-targets.nul"
	: >"$swift_format_absolute_targets"
	xargs -0 -n 1 "$swift_format_adapter" --to-absolute-one "$swift_format_root" \
		<"$swift_format_targets" >"$swift_format_absolute_targets" || return 2

	if xargs -0 "$swift_format_tool" <"$swift_format_absolute_targets"; then
		:
	else
		[ "$swift_format_action" != staged ] || swift_format_rollback || return 2
		printf '오류[swift-format.formatter-failed]: Swift-Style 실행이 실패했습니다\n조치: 위 SwiftFormat/SwiftLint 출력을 확인하세요\n' >&2
		return 1
	fi

	# 4. staged 모드는 포맷팅 후에도 작업 트리가 깨끗한지, 즉 재-add가 필요한지 확인합니다.
	if [ "$swift_format_action" = staged ]; then
		xargs -0 -n 1 "$swift_format_adapter" --verify-one "$swift_format_root" \
			<"$swift_format_targets" || return 1
		printf 'Swift 포맷팅 검증 완료.\n'
	fi
)

swift_format_main "$@"
