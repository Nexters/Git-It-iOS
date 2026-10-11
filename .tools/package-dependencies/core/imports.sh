# 프로젝트 Swift 파일 목록과 각 파일의 import 선언을 읽는 어댑터입니다.
#
# files: <파일>
# imports: <파일><TAB><줄><TAB><모듈>

package_dependencies_collect_imports() (
	pd_projects=$1
	pd_files=$2
	pd_imports=$3
	pd_list="$pd_files.nul"

	# 생성물·빌드 산출물과 패키지 manifest는 target 소스가 아니므로 제외합니다.
	find "$pd_projects" \
		\( -name Derived -o -name DerivedData -o -name build -o -name .build -o -name '*.xcodeproj' \) -prune \
		-o -type f -name '*.swift' ! -name Project.swift -print0 >"$pd_list" || return 2
	tr '\0' '\n' <"$pd_list" >"$pd_files" || return 2
	: >"$pd_imports"
	[ -s "$pd_list" ] || return 0

	# 주석과 여러 줄 문자열 안의 텍스트는 import로 보지 않습니다.
	# shellcheck disable=SC2016
	xargs -0 awk '
		FNR == 1 { depth = 0; in_text = 0 }
		{
			line = $0
			if (depth > 0 || in_text || index(line, "/*") || index(line, "*/") || index(line, "\"\"\"")) {
				code = ""
				length_of_line = length(line)
				i = 1
				while (i <= length_of_line) {
					pair = substr(line, i, 2)
					triple = substr(line, i, 3)
					if (in_text) {
						if (triple == "\"\"\"") { in_text = 0; i += 3 } else i++
						continue
					}
					if (depth > 0) {
						if (pair == "/*") { depth++; i += 2 }
						else if (pair == "*/") { depth--; i += 2 }
						else i++
						continue
					}
					if (pair == "//") break
					if (pair == "/*") { depth++; i += 2; continue }
					if (triple == "\"\"\"") { in_text = 1; i += 3; continue }
					character = substr(line, i, 1)
					code = code character
					i++
					# 한 줄 문자열 안의 주석 표식은 건너뜁니다.
					if (character == "\"") {
						while (i <= length_of_line) {
							character = substr(line, i, 1)
							code = code character
							i++
							if (character == "\\") {
								code = code substr(line, i, 1)
								i++
							} else if (character == "\"") break
						}
					}
				}
				line = code
			}
			if (!index(line, "import")) next
			pattern = "^[ \t]*(@[A-Za-z_]+([(][^)]*[)])?[ \t]+)*import[ \t]+"
			if (line !~ pattern) next
			sub(pattern, "", line)
			sub(/^(typealias|struct|class|enum|protocol|let|var|func)[ \t]+/, "", line)
			if (match(line, /^[A-Za-z_][A-Za-z0-9_]*/)) {
				printf "%s\t%d\t%s\n", FILENAME, FNR, substr(line, 1, RLENGTH)
			}
		}
	' <"$pd_list" >"$pd_imports"
)
