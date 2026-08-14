# 공유 scheme에 등록할 수 있는 테스트 target의 실행 가능 여부를 확인합니다.

script_tests_list_scheme_test_targets() (
	script_tests_scheme_source=$1
	# Scheme.module의 testTarget은 해당 case의 패키지 문맥과 함께 관리합니다.
	awk '
		/case[[:space:]]+\.[[:alnum:]_]+:/ {
			package = $0
			sub(/.*case[[:space:]]+\./, "", package)
			sub(/:.*/, "", package)
		}
		/testTarget:[[:space:]]*"/ {
			target = $0
			sub(/.*testTarget:[[:space:]]*"/, "", target)
			sub(/".*/, "", target)
			if (target != "") print target "|" package
		}
	' "$script_tests_scheme_source"
)

script_tests_target_has_test_case() (
	script_tests_projects=$1
	script_tests_target=$2
	script_tests_package=$3
	script_tests_target_list=$(mktemp "${TMPDIR:-/tmp}/git-it-test-targets.XXXXXX") || return 2
	trap 'rm -f "$script_tests_target_list"' EXIT HUP INT TERM
	# 기존 target 이름 폴더를 먼저 확인해 이전 구조와 호환합니다.
	find "$script_tests_projects" -type d -name "$script_tests_target" -print0 \
		>"$script_tests_target_list"
	if [ ! -s "$script_tests_target_list" ] && [ -n "$script_tests_package" ]; then
		# 패키지 접두어를 제거한 역할 폴더를 새 target 규칙으로 확인합니다.
		script_tests_source_directory=${script_tests_target#"$script_tests_package"}
		find "$script_tests_projects" -type d -name "$script_tests_source_directory" -print0 \
			>"$script_tests_target_list"
	fi
	[ -s "$script_tests_target_list" ] || return 1
	# Swift Testing과 XCTest의 실제 실행 단위를 모두 인정합니다.
	xargs -0 rg -q --glob '*.swift' \
		'^[[:space:]]*@Test([[:space:]]|\(|$)|:[[:space:]]*XCTestCase([[:space:]]|\{|$)' \
		<"$script_tests_target_list"
)

script_tests_validate_testable_schemes() (
	script_tests_projects=$1
	script_tests_scheme_source=$2
	[ -d "$script_tests_projects" ] || {
		printf '오류[script-tests.missing-projects-root]: %s 누락\n조치: 중앙 경로 설정의 프로젝트 루트를 복구하세요\n' \
			"$script_tests_projects" >&2
		return 2
	}
	[ -f "$script_tests_scheme_source" ] || {
		printf '오류[script-tests.missing-scheme-source]: %s 누락\n조치: 공유 scheme 선언 경로를 복구하세요\n' \
			"$script_tests_scheme_source" >&2
		return 2
	}

	# target 식별자와 패키지 이름은 Swift 문자열이므로 경로에 쓰이지 않는 구분자로 분리합니다.
	script_tests_targets=$(script_tests_list_scheme_test_targets "$script_tests_scheme_source") || return $?
	[ -z "$script_tests_targets" ] && return 0
	while IFS='|' read -r script_tests_target script_tests_package; do
		[ -n "$script_tests_target" ] || continue
		if script_tests_target_has_test_case "$script_tests_projects" "$script_tests_target" "$script_tests_package"; then
			continue
		fi
		printf '오류[script-tests.empty-test-target]: %s에는 실행 가능한 @Test 또는 XCTestCase가 없습니다\n조치: 테스트를 추가한 뒤 testTarget에 등록하거나 빈 테스트 target을 scheme에서 제외하세요\n' \
			"$script_tests_target" >&2
		return 1
	done <<EOF
$script_tests_targets
EOF
)
