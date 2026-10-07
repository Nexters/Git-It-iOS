# 규칙을 실제 파일에 적용하는 외부 어댑터입니다.

# 프리뷰 스캐폴딩을 제외합니다. 이 저장소는 프리뷰를 파일 끝에 두므로 첫 `#Preview`
# 이후 줄을 빈 줄로 바꿔 행 번호를 보존한 채 검사 대상에서 제외합니다.
design_rules_production_source() (
	design_rules_file=$1
	awk 'skip { print ""; next } /#Preview/ { skip = 1; print ""; next } { print }' "$design_rules_file"
)

# 파일 하나를 검사해 위반을 `경로:행:규칙`으로 보고 파일에 덧붙입니다.
design_rules_scan_file() (
	design_rules_name=$1
	design_rules_allow_list=$2
	design_rules_report=$3
	design_rules_file=$4

	design_rules_path_exempt "$design_rules_name" "$design_rules_file" && return 0

	# 허용 목록은 저장소 상대경로와 이유를 한 줄씩 담습니다.
	if [ -n "$design_rules_allow_list" ] && [ -f "$design_rules_allow_list" ]; then
		while IFS= read -r design_rules_entry; do
			case "$design_rules_entry" in '' | '#'*) continue ;; esac
			design_rules_allow_path=${design_rules_entry%%[!!-~]*}
			case "$design_rules_file" in
			*"/$design_rules_allow_path") return 0 ;;
			esac
		done <"$design_rules_allow_list"
	fi

	design_rules_expression=$(design_rules_pattern "$design_rules_name") || return 2
	# 읽기 전용 검사이므로 pipeline을 써도 결과 안전성에 영향이 없습니다.
	design_rules_production_source "$design_rules_file" |
		rg -n -e "$design_rules_expression" |
		while IFS=: read -r design_rules_line design_rules_rest; do
			[ -n "$design_rules_rest" ] || design_rules_rest=''
			printf '%s:%s:%s\n' \
				"$design_rules_file" "$design_rules_line" "$design_rules_name" \
				>>"$design_rules_report"
		done
	return 0
)

# 규칙 하나를 소스 루트 전체에 적용합니다.
design_rules_scan_rule() (
	design_rules_name=$1
	design_rules_target=$2
	design_rules_allow_list=$3
	design_rules_report=$4
	design_rules_library=$5

	[ -d "$design_rules_target" ] || return 0
	# find -exec는 경로를 argv로 전달하므로 공백·한글·개행이 있어도 안전합니다.
	find "$design_rules_target" -type f -name '*.swift' -exec /bin/sh -c '
		. "$1"
		. "$2"
		design_rules_scan_file "$3" "$4" "$5" "$6"
	' _ "$design_rules_library/rules.sh" "$design_rules_library/scan.sh" \
		"$design_rules_name" "$design_rules_allow_list" "$design_rules_report" {} \;
)
