#!/bin/sh

# Spec metadata에서 실제 또는 legacy 예정 branch 연결을 엄격하게 읽습니다.
spec_kit_read_branch() (
	spec_kit_spec=$1
	awk '
		/^\*\*기능 브랜치\*\*:[[:space:]]*`[^`]+`[[:space:]]*$/ {
			line=$0
			sub(/^[^:]*:[[:space:]]*`/, "", line)
			sub(/`[[:space:]]*$/, "", line)
			if (line ~ /^미생성 \(예정: /) {
				sub(/^미생성 \(예정: /, "", line)
				sub(/\)$/, "", line)
			}
			print line
			exit
		}
	' "$spec_kit_spec"
)

# 신규 Git-flow namespace와 보존 대상 legacy branch 형식을 검증합니다.
spec_kit_validate_branch() (
	spec_kit_branch=$1
	case "$spec_kit_branch" in
		feature/*|hotfix/*)
			spec_kit_suffix=${spec_kit_branch#*/}
			case "$spec_kit_suffix" in
				''|*/*|*[!a-z0-9-]*|-*|*-) return 1 ;;
			esac
			;;
		release/*)
			spec_kit_suffix=${spec_kit_branch#*/}
			case "$spec_kit_suffix" in
				''|*/*|*[!a-z0-9.-]*|-*|*-) return 1 ;;
			esac
			;;
		[0-9][0-9][0-9]-*)
			spec_kit_suffix=${spec_kit_branch#*-}
			case "$spec_kit_suffix" in ''|*/*|*[!a-z0-9-]*|-*|*-) return 1 ;; esac
			;;
		*) return 1 ;;
	esac
)

# Association에서 제외되는 명시적 legacy artifact 표식을 판정합니다.
spec_kit_is_unlinked_branch() (
	case "$1" in
		'미연결 ('*')') return 0 ;;
		*) return 1 ;;
	esac
)

# JSON pointer가 단일 key를 가진 완전한 JSON 문서인지 확인한 뒤 값을 읽습니다.
spec_kit_read_pointer() (
	spec_kit_pointer_file=$1
	spec_kit_key_count=$(awk '{ line = $0; while (match(line, /"feature_directory"[[:space:]]*:/)) { count++; line = substr(line, RSTART + RLENGTH) } } END { print count + 0 }' "$spec_kit_pointer_file") || return 1
	[ "$spec_kit_key_count" -eq 1 ] || return 1
	if command -v python3 >/dev/null 2>&1; then
		python3 -c 'import json, sys
def reject_duplicate(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key")
        result[key] = value
    return result
document = json.load(open(sys.argv[1]), object_pairs_hook=reject_duplicate)
if set(document) != {"feature_directory"} or not isinstance(document["feature_directory"], str):
    raise ValueError("invalid pointer shape")
print(document["feature_directory"])' "$spec_kit_pointer_file" 2>/dev/null
	elif command -v jq >/dev/null 2>&1; then
		jq -er 'if type == "object" and keys == ["feature_directory"] and (.feature_directory | type) == "string" then .feature_directory else error("invalid pointer shape") end' "$spec_kit_pointer_file" 2>/dev/null
	else
		# 도구가 없는 최소 환경에서는 생성기가 쓰는 단일 key compact 형식만 허용합니다.
		awk 'BEGIN { valid = 0 } /^[[:space:]]*\{"feature_directory":"[^"\\]*"\}[[:space:]]*$/ { value = $0; sub(/^[[:space:]]*\{"feature_directory":"/, "", value); sub(/"\}[[:space:]]*$/, "", value); valid = 1 } END { if (!valid || NR != 1) exit 1; print value }' "$spec_kit_pointer_file"
	fi
)

# specs 직계 하위의 실제 비-symlink 디렉터리만 허용합니다.
spec_kit_validate_directory() (
	spec_kit_root=$1
	spec_kit_candidate=$2
	case "$spec_kit_candidate" in
		"$spec_kit_root"/specs/*) ;;
		*) return 1 ;;
	esac
	spec_kit_relative=${spec_kit_candidate#"$spec_kit_root"/specs/}
	case "$spec_kit_relative" in ''|*/*|.|..) return 1 ;; esac
	[ -d "$spec_kit_candidate" ] || return 1
	[ ! -L "$spec_kit_candidate" ] || return 1
	[ "$(CDPATH='' cd -- "$spec_kit_candidate" && pwd -P)" = "$spec_kit_candidate" ]
)

# spec.md 자체도 외부 파일을 가리키지 않는 regular file이어야 합니다.
spec_kit_validate_spec_file() (
	spec_kit_root=$1
	spec_kit_spec=$2
	spec_kit_directory=${spec_kit_spec%/spec.md}
	spec_kit_validate_directory "$spec_kit_root" "$spec_kit_directory" || return 1
	[ -f "$spec_kit_spec" ] || return 1
	[ ! -L "$spec_kit_spec" ]
)
