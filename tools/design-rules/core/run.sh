# 규칙 8종을 실행하고 결과를 집계·보고하는 유스케이스입니다.

design_rules_run() (
	design_rules_projects=$1
	design_rules_config=$2
	design_rules_library=$3
	design_rules_work=$4

	design_rules_report="$design_rules_work/violations"
	: >"$design_rules_report" || return 2
	design_rules_failed=0
	design_rules_total=0

	# 규칙마다 대상 루트와 허용 목록을 조립해 순서대로 검사합니다.
	design_rules_list=$(design_rules_names)
	while IFS= read -r design_rules_name; do
		[ -n "$design_rules_name" ] || continue
		design_rules_total=$((design_rules_total + 1))
		design_rules_target="$design_rules_projects/$(design_rules_scan_subpath "$design_rules_name")"
		design_rules_allow_name=$(design_rules_allow_file "$design_rules_name")
		design_rules_allow_list=''
		[ -n "$design_rules_allow_name" ] &&
			design_rules_allow_list="$design_rules_config/$design_rules_allow_name"
		design_rules_before=$(wc -l <"$design_rules_report")
		design_rules_scan_rule \
			"$design_rules_name" \
			"$design_rules_target" \
			"$design_rules_allow_list" \
			"$design_rules_report" \
			"$design_rules_library" || return $?
		design_rules_after=$(wc -l <"$design_rules_report")
		if [ "$design_rules_before" -ne "$design_rules_after" ]; then
			design_rules_failed=$((design_rules_failed + 1))
		fi
	done <<EOF
$design_rules_list
EOF

	# 위반이 없으면 성공으로 종료하고, 있으면 파일·행·규칙과 조치를 함께 보고합니다.
	if [ ! -s "$design_rules_report" ]; then
		printf '디자인 규칙 검사 완료: 규칙=%s 위반=0\n' "$design_rules_total"
		return 0
	fi

	while IFS= read -r design_rules_violation; do
		design_rules_rule=${design_rules_violation##*:}
		printf '%s %s\n' \
			"$design_rules_violation" \
			"$(design_rules_description "$design_rules_rule")" >&2
	done <"$design_rules_report"
	printf '오류[design-rules.violated]: 규칙 %s종에서 위반이 있습니다\n조치: 위 파일과 행의 값을 토큰 또는 레이아웃 변수로 바꾸거나 허용 목록에 이유와 함께 등록하세요\n' \
		"$design_rules_failed" >&2
	return 1
)
