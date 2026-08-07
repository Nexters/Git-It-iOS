#!/bin/sh
# Swift-Style 서브모듈 스크립트(format.sh/lint.sh)를 절대경로로만 호출하는 adapter입니다.
# 서브모듈 스크립트는 자기 자신(Tools/swift-style) 기준으로 cd하므로 상대경로를 그대로
# 넘기면 바깥 저장소 경로를 찾지 못합니다. 여기서 항상 절대경로로 변환해 넘깁니다.

# 순수 정책: 후보 경로를 저장소 루트 기준 절대경로로 정규화합니다.
style_adapter_absolute() (
	style_adapter_root=$1
	style_adapter_candidate=$2
	case "$style_adapter_candidate" in
	/*) printf '%s\n' "$style_adapter_candidate" ;;
	*) printf '%s/%s\n' "$style_adapter_root" "$style_adapter_candidate" ;;
	esac
)

# xargs -0 -n 1 dispatch 대상: 대상 하나를 절대경로로 바꿔 포맷/린트 도구를 실행합니다.
style_adapter_format_one() {
	style_adapter_tool=$1
	style_adapter_root=$2
	style_adapter_item=$3
	style_adapter_absolute_item=$(style_adapter_absolute "$style_adapter_root" "$style_adapter_item")
	"$style_adapter_tool" "$style_adapter_absolute_item"
}

# xargs -0 -n 1 dispatch 대상: staged 포맷팅 후 작업 트리가 여전히 깨끗한지 확인합니다.
style_adapter_verify_one() {
	style_adapter_root=$1
	style_adapter_item=$2
	git -C "$style_adapter_root" diff --quiet -- "$style_adapter_item" || {
		printf '오류[swift-format.restage-required]: 포맷팅으로 인해 %s 파일이 변경되었습니다\n조치: 변경사항을 git add 한 후 다시 커밋해 주세요\n' \
			"$style_adapter_item" >&2
		exit 1
	}
}

if [ "${1:-}" = --format-one ]; then
	shift
	style_adapter_format_one "$@"
elif [ "${1:-}" = --verify-one ]; then
	shift
	style_adapter_verify_one "$@"
fi
