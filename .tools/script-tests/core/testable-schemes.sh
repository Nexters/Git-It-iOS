# 공유 scheme에 등록할 수 있는 테스트 target의 실행 가능 여부를 확인합니다.

script_tests_list_scheme_test_targets() (
	script_tests_scheme_source=$1
	# Scheme.package의 testTargets 배열은 해당 case의 패키지 문맥과 함께 관리합니다.
	awk '
		/case[[:space:]]+\.[[:alnum:]_]+:/ {
			package = $0
			sub(/.*case[[:space:]]+\./, "", package)
			sub(/:.*/, "", package)
		}
		/testTargets:[[:space:]]*\[/ {
			in_test_targets = 1
			# 빈 배열은 같은 줄에서 끝나므로 다음 package의 build target을 읽으면 안 됩니다.
			if ($0 ~ /\]/) in_test_targets = 0
			next
		}
		in_test_targets && /ModuleName\.[[:alnum:]_]+\.rawValue/ {
			target = $0
			sub(/.*ModuleName\./, "", target)
			sub(/\.rawValue.*/, "", target)
			if (target != "") print target "|" package
		}
		in_test_targets && /"[[:alnum:]_]+"/ {
			target = $0
			sub(/^[^"]*"/, "", target)
			sub(/".*/, "", target)
			if (target != "") print target "|" package
		}
		in_test_targets && /\]/ {
			in_test_targets = 0
		}
		# 이전 단수 선언도 읽어 migration 중 빈 target 검증을 유지합니다.
		/testTarget:[[:space:]]*"/ {
			target = $0
			sub(/.*testTarget:[[:space:]]*"/, "", target)
			sub(/".*/, "", target)
			if (target != "") print target "|" package
		}
	' "$script_tests_scheme_source"
)

script_tests_declared_source_directory() (
	script_tests_scheme_source=$1
	script_tests_target=$2
	script_tests_package=$3
	script_tests_module_source="$(dirname -- "$script_tests_scheme_source")/Projects/${script_tests_package}ModuleName.swift"
	[ -f "$script_tests_module_source" ] || return 1

	# switch case와 배열식 target 선언에서 명시한 sourceDirectory를 경로 계약으로 사용합니다.
	# ModuleName.sourceDirectory 연산 프로퍼티를 전달하면 target 이름의 패키지 접두어와
	# 테스트 접미어를 제거해 테스트 컨벤션의 역할 경로로 해석합니다.
	script_tests_source_declaration=$(awk -v expected_target="$script_tests_target" '
		/var[[:space:]]+sourceDirectory[[:space:]]*:/ {
			in_source_directory = 1
			next
		}
		/var[[:space:]]+target[[:space:]]*:/ {
			in_source_directory = 0
		}
		/case[[:space:]]+\.[[:alnum:]_]+:/ {
			matches_target = index($0, "." expected_target) > 0
			matches_source_directory_case = in_source_directory && matches_target
			next
		}
		# sourceDirectory enum 분기의 문자열은 target 이름이 아닌 실제 역할 경로입니다.
		matches_source_directory_case && /^[[:space:]]*"[^"]+"[[:space:]]*$/ {
			source_directory = $0
			sub(/^[[:space:]]*"/, "", source_directory)
			sub(/"[[:space:]]*$/, "", source_directory)
			print source_directory
			found = 1
			exit
		}
		/name:[[:space:]]*/ && index($0, "." expected_target ".rawValue") > 0 {
			matches_target = 1
		}
		matches_target && /sourceDirectory:[[:space:]]*"/ {
			source_directory = $0
			sub(/.*sourceDirectory:[[:space:]]*"/, "", source_directory)
			sub(/".*/, "", source_directory)
			if (source_directory != "") {
				print source_directory
				found = 1
				exit
			}
		}
		matches_target && /sourceDirectory:[[:space:]]*/ && $0 !~ /sourceDirectory:[[:space:]]*"/ {
			print "@computed"
			found = 1
			exit
		}
		matches_target && /sourceDirectory/ && /\/\*\*/ {
			print "@computed"
			found = 1
			exit
		}
		END { if (!found) exit 1 }
	' "$script_tests_module_source") || return 1

	if [ "$script_tests_source_declaration" != '@computed' ]; then
		printf '%s\n' "$script_tests_source_declaration"
		return 0
	fi

	script_tests_directory_name=${script_tests_target#"$script_tests_package"}
	case $script_tests_directory_name in
	*UITests)
		script_tests_directory_name=${script_tests_directory_name%UITests}
		[ -n "$script_tests_directory_name" ] || return 1
		printf 'Tests/%s/UI\n' "$script_tests_directory_name"
		;;
	*Tests)
		script_tests_directory_name=${script_tests_directory_name%Tests}
		if [ -z "$script_tests_directory_name" ]; then
			printf 'Tests\n'
		elif rg -q "case[[:space:]]+\\.${script_tests_target%Tests}UITests([[:space:]]|:)" \
			"$script_tests_module_source"; then
			printf 'Tests/%s/Unit\n' "$script_tests_directory_name"
		else
			printf 'Tests/%s\n' "$script_tests_directory_name"
		fi
		;;
	*) return 1 ;;
	esac
)

script_tests_target_has_test_case() (
	script_tests_projects=$1
	script_tests_target=$2
	script_tests_package=$3
	script_tests_scheme_source=$4
	script_tests_target_list=$(mktemp "${TMPDIR:-/tmp}/git-it-test-targets.XXXXXX") || return 2
	trap 'rm -f "$script_tests_target_list"' EXIT HUP INT TERM
	if script_tests_source_directory=$(script_tests_declared_source_directory \
		"$script_tests_scheme_source" "$script_tests_target" "$script_tests_package"); then
		# 선언 경로는 패키지 안에서만 해석해 같은 이름의 다른 target을 오인하지 않습니다.
		case $script_tests_source_directory in
		'' | /* | .. | ../* | */../* | */..) return 2 ;;
		esac
		script_tests_declared_path="$script_tests_projects/$script_tests_package/$script_tests_source_directory"
		# 일부 Tuist target은 테스트 역할 경로만 제공하고 소스 목록 선언에서 Tests 접두어를 붙입니다.
		# 직접 경로가 없을 때만 테스트 루트 아래의 같은 역할 경로를 보조로 확인합니다.
		if [ ! -d "$script_tests_declared_path" ] && [ -d "$script_tests_projects/$script_tests_package/Tests/$script_tests_source_directory" ]; then
			script_tests_declared_path="$script_tests_projects/$script_tests_package/Tests/$script_tests_source_directory"
		fi
		[ -d "$script_tests_declared_path" ] || return 1
		printf '%s\0' "$script_tests_declared_path" >"$script_tests_target_list"
	else
		# sourceDirectory가 없는 기존 target 이름 폴더를 이전 구조와 호환합니다.
		find "$script_tests_projects" -type d -name "$script_tests_target" -print0 \
			>"$script_tests_target_list"
		if [ ! -s "$script_tests_target_list" ] && [ -n "$script_tests_package" ]; then
			# 패키지 접두어를 제거한 역할 폴더를 이전 target 규칙으로 확인합니다.
			script_tests_source_directory=${script_tests_target#"$script_tests_package"}
			find "$script_tests_projects" -type d -name "$script_tests_source_directory" -print0 \
				>"$script_tests_target_list"
		fi
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
		if script_tests_target_has_test_case "$script_tests_projects" "$script_tests_target" \
			"$script_tests_package" "$script_tests_scheme_source"; then
			continue
		fi
		printf '오류[script-tests.empty-test-target]: %s에는 실행 가능한 @Test 또는 XCTestCase가 없습니다\n조치: 테스트를 추가한 뒤 testTarget에 등록하거나 빈 테스트 target을 scheme에서 제외하세요\n' \
			"$script_tests_target" >&2
		return 1
	done <<EOF
$script_tests_targets
EOF
)
