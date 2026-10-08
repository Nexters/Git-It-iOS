#!/bin/sh
# GIT_IT_SWIFT_STYLE_ROOT의 포매터와 린터를 절대경로로만 호출하는 adapter입니다.
# 도구가 자기 위치를 기준으로 cd하므로 대상은 항상 절대경로로 변환해 넘깁니다.

# 순수 정책: 후보 경로를 저장소 루트 기준 절대경로로 정규화합니다.
style_adapter_absolute() (
	style_adapter_root=$1
	style_adapter_candidate=$2
	case "$style_adapter_candidate" in
	/*) printf '%s\n' "$style_adapter_candidate" ;;
	*) printf '%s/%s\n' "$style_adapter_root" "$style_adapter_candidate" ;;
	esac
)

# 포맷 대상에서 생성 산출물 디렉터리를 제외합니다. 디렉터리 입력은 Swift 파일 목록으로
# 펼치고, 파일 입력은 그대로 NUL 경계로 보존합니다.
style_adapter_collect_one() {
	style_adapter_root=$1
	style_adapter_output=$2
	style_adapter_item=$3
	style_adapter_absolute_item=$(style_adapter_absolute "$style_adapter_root" "$style_adapter_item")
	case "$style_adapter_absolute_item" in
	*/Derived | */Derived/* | */.build | */.build/*) return 0 ;;
	esac
	if [ -d "$style_adapter_absolute_item" ]; then
		find "$style_adapter_absolute_item" \
			\( -type d \( -name Derived -o -name .build \) -prune \) -o \
			\( -type f -name '*.swift' -print0 \) >>"$style_adapter_output"
		return
	fi
	case "$style_adapter_absolute_item" in
	*.swift) printf '%s\0' "$style_adapter_item" >>"$style_adapter_output" ;;
	esac
}

# 수집된 Swift 파일 가운데 작업 트리 또는 index에서 추가·수정된 파일만 NUL 경계로 남깁니다.
# 삭제 파일은 수집 단계에서 실제 파일이 아니므로 자연스럽게 제외됩니다.
style_adapter_collect_changed_one() {
	style_adapter_root=$1
	style_adapter_output=$2
	style_adapter_item=$3
	if ! git -C "$style_adapter_root" diff --quiet -- "$style_adapter_item" ||
		! git -C "$style_adapter_root" diff --cached --quiet -- "$style_adapter_item" ||
		git -C "$style_adapter_root" ls-files --others --exclude-standard --error-unmatch -- \
			"$style_adapter_item" >/dev/null 2>&1; then
		printf '%s\0' "$style_adapter_item" >>"$style_adapter_output"
	fi
}

# xargs -0 -n 1 dispatch 대상: 대상 하나를 절대경로로 바꿔 NUL 경계로 출력합니다.
# 호출자가 전체 대상을 모은 뒤 도구를 한 번만 실행해 프로세스 기동 비용을 대상 수만큼
# 반복하지 않게 합니다.
style_adapter_to_absolute_one() {
	style_adapter_root=$1
	style_adapter_item=$2
	style_adapter_absolute_item=$(style_adapter_absolute "$style_adapter_root" "$style_adapter_item")
	printf '%s\0' "$style_adapter_absolute_item"
}

# xargs -0 -n 1 dispatch 대상: staged 포맷팅 후 작업 트리가 여전히 깨끗한지 확인합니다.
# staged 대상 하나를 invocation 전용 backup과 NUL ledger에 기록합니다.
style_adapter_backup_one() {
	style_adapter_backup_root=$1
	style_adapter_ledger=$2
	style_adapter_root=$3
	style_adapter_item=$4
	style_adapter_absolute_item=$(style_adapter_absolute "$style_adapter_root" "$style_adapter_item")
	[ -f "$style_adapter_absolute_item" ] || return 2
	style_adapter_backup_id=$(printf '%s' "$style_adapter_absolute_item" | shasum -a 256) || return 2
	style_adapter_backup_id=${style_adapter_backup_id%% *}
	style_adapter_backup="$style_adapter_backup_root/$style_adapter_backup_id"
	cp -p "$style_adapter_absolute_item" "$style_adapter_backup" || return 2
	printf '%s\0%s\0' "$style_adapter_absolute_item" "$style_adapter_backup_id" >>"$style_adapter_ledger"
}

# NUL ledger가 전달한 원본 경로와 backup을 사용해 파일을 복원합니다.
style_adapter_restore_one() {
	style_adapter_backup_root=$1
	style_adapter_absolute_item=$2
	style_adapter_backup_id=$3
	style_adapter_backup="$style_adapter_backup_root/$style_adapter_backup_id"
	[ -f "$style_adapter_backup" ] || return 2
	cp -p "$style_adapter_backup" "$style_adapter_absolute_item"
}

# 저장소가 다른 경로로 이동/재클론되면 Swift-Style submodule의 .build 아래 Clang 모듈
# 캐시(.pcm)가 예전 절대경로를 내부에 기록한 채 남아 "missing required module" 빌드
# 실패로 이어집니다. 이전 실행 경로를 marker 파일에 남겨 현재 경로와 비교하고, 다르면
# .build를 통째로 지워 다음 빌드가 새 경로로 캐시를 다시 만들게 합니다.
style_adapter_ensure_fresh_build_cache() {
	style_adapter_style_dir=$1
	style_adapter_build_dir="$style_adapter_style_dir/.build"
	style_adapter_marker="$style_adapter_build_dir/.git-it-build-root"

	if [ -d "$style_adapter_build_dir" ]; then
		style_adapter_recorded=""
		if [ -f "$style_adapter_marker" ]; then
			style_adapter_recorded=$(cat "$style_adapter_marker") || style_adapter_recorded=""
		fi
		if [ "$style_adapter_recorded" != "$style_adapter_style_dir" ]; then
			printf '진단[swift-format.stale-build-cache]: 저장소 경로가 바뀌어 %s 캐시를 초기화합니다\n' \
				"$style_adapter_build_dir" >&2
			# macOS에서 Spotlight/Finder가 .DS_Store를 다시 만들며 rm -rf가 일시적으로
			# "Directory not empty"를 내는 경우가 있어 짧게 재시도합니다.
			style_adapter_remove_attempt=0
			while [ -d "$style_adapter_build_dir" ] && [ "$style_adapter_remove_attempt" -lt 3 ]; do
				rm -rf "$style_adapter_build_dir" 2>/dev/null || :
				style_adapter_remove_attempt=$((style_adapter_remove_attempt + 1))
			done
			if [ -d "$style_adapter_build_dir" ]; then
				printf '오류[swift-format.stale-build-cache-removal-failed]: %s를 지우지 못했습니다\n조치: 디렉터리 권한과 잠긴 프로세스를 확인한 뒤 수동으로 삭제하세요\n' \
					"$style_adapter_build_dir" >&2
				return 2
			fi
		fi
	fi

	mkdir -p "$style_adapter_build_dir" || return 2
	printf '%s' "$style_adapter_style_dir" >"$style_adapter_marker"
}

style_adapter_verify_one() {
	style_adapter_root=$1
	style_adapter_item=$2
	git -C "$style_adapter_root" diff --quiet -- "$style_adapter_item" || {
		printf '오류[swift-format.restage-required]: 포맷팅으로 인해 %s 파일이 변경되었습니다\n조치: 변경사항을 git add 한 후 다시 커밋해 주세요\n' \
			"$style_adapter_item" >&2
		exit 1
	}
}

if [ "${1:-}" = --to-absolute-one ]; then
	shift
	style_adapter_to_absolute_one "$@"
elif [ "${1:-}" = --collect-one ]; then
	shift
	style_adapter_collect_one "$@"
elif [ "${1:-}" = --collect-changed-one ]; then
	shift
	style_adapter_collect_changed_one "$@"
elif [ "${1:-}" = --backup-one ]; then
	shift
	style_adapter_backup_one "$@"
elif [ "${1:-}" = --restore-one ]; then
	shift
	style_adapter_restore_one "$@"
elif [ "${1:-}" = --verify-one ]; then
	shift
	style_adapter_verify_one "$@"
elif [ "${1:-}" = --ensure-fresh-cache ]; then
	shift
	style_adapter_ensure_fresh_build_cache "$@"
fi
