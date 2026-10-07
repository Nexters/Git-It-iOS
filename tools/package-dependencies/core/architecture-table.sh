# 아키텍처 문서 3.1 표와 허용 의존성 설정을 같은 레코드 형식으로 읽는 어댑터입니다.
#
# 레코드: <패키지><TAB><이름순 허용 패키지 공백 구분><TAB><줄 번호>

# 아키텍처 3.1 표를 읽습니다. 제목·머리행·행이 없으면 3을 반환합니다.
package_dependencies_read_table() (
	pd_document=$1
	pd_output=$2
	[ -r "$pd_document" ] || return 3
	awk -v out="$pd_output" '
		function trim(value) {
			sub(/^[ \t]+/, "", value)
			sub(/[ \t]+$/, "", value)
			return value
		}
		function sorted(value,    items, count, i, j, swap, result) {
			gsub(/[ \t]/, "", value)
			count = split(value, items, ",")
			for (i = 2; i <= count; i++) {
				for (j = i; j > 1 && items[j - 1] > items[j]; j--) {
					swap = items[j]
					items[j] = items[j - 1]
					items[j - 1] = swap
				}
			}
			result = ""
			for (i = 1; i <= count; i++) {
				if (items[i] == "") continue
				result = result (result == "" ? "" : " ") items[i]
			}
			return result
		}
		# 3.1 제목 뒤 첫 표만 읽습니다.
		/^### 3\.1([ \t]|$)/ { section = NR; next }
		section && !done && /^#/ { done = 1 }
		section && !done && /^\|/ {
			row++
			split($0, cells, "|")
			first = trim(cells[2])
			second = trim(cells[3])
			if (row == 1) {
				if (first != "패키지" || second != "허용 의존성") broken = 1
				next
			}
			if (row == 2) {
				if (first !~ /^:?-+:?$/) broken = 1
				next
			}
			if (second == "—" || second == "-") second = ""
			printf "%s\t%s\t%d\n", first, sorted(second), NR > out
			rows++
			next
		}
		section && rows > 0 && !/^\|/ { done = 1 }
		END {
			if (!section || broken || rows == 0) exit 3
			printf "__section__\t\t%d\n", section > out
		}
	' "$pd_document"
)

# 허용 의존성 설정을 읽고 형식 오류를 오류 레코드로 남깁니다. 오류가 있으면 2를 반환합니다.
package_dependencies_read_allowed() (
	pd_config=$1
	pd_output=$2
	pd_errors=$3
	pd_known=$4
	awk -v out="$pd_output" -v errors="$pd_errors" -v known="$pd_known" -v file="$pd_config" '
		function fail(message) {
			printf "invalid-config\t%s\t%d\t%s\n", file, NR, message >> errors
			failed = 1
		}
		BEGIN {
			count = split(known, names, " ")
			for (i = 1; i <= count; i++) isknown[names[i]] = 1
		}
		/^[ \t]*(#|$)/ { next }
		{
			if ($0 !~ /^[A-Za-z]+:/) {
				fail("형식이 \"<패키지>: <허용 패키지…>\"가 아님")
				next
			}
			package = $0
			sub(/:.*/, "", package)
			rest = $0
			sub(/^[^:]*:/, "", rest)
			if (!(package in isknown)) fail("알 수 없는 패키지 " package)
			if (package in seen) fail("패키지 " package " 중복")
			seen[package] = 1
			split("", used)
			total = split(rest, items, /[ \t]+/)
			list = ""
			size = 0
			for (i = 1; i <= total; i++) {
				item = items[i]
				if (item == "") continue
				if (!(item in isknown)) fail(package ": 알 수 없는 허용 패키지 " item)
				if (item == package) fail(package ": 자기 자신을 허용함")
				if (item in used) fail(package ": 허용 패키지 " item " 중복")
				used[item] = 1
				size++
				picked[size] = item
			}
			for (i = 2; i <= size; i++) {
				for (j = i; j > 1 && picked[j - 1] > picked[j]; j--) {
					swap = picked[j]
					picked[j] = picked[j - 1]
					picked[j - 1] = swap
				}
			}
			for (i = 1; i <= size; i++) list = list (list == "" ? "" : " ") picked[i]
			printf "%s\t%s\t%d\n", package, list, NR > out
		}
		END {
			for (i = 1; i <= count; i++) {
				if (!(names[i] in seen)) {
					printf "invalid-config\t%s\t0\t패키지 %s 누락\n", file, names[i] >> errors
					failed = 1
				}
			}
			if (failed) exit 2
		}
	' "$pd_config"
)
