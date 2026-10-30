#!/bin/sh
# 컨벤션 표와 issue 템플릿에서 도구가 쓰는 값을 읽는 파일 어댑터입니다.
# 값은 문서가 소유하고, 여기서는 찾기만 합니다.

# 머리글에 지정한 열이 있는 첫 표를 머리글부터 탭으로 구분해 출력합니다.
convention_reader_table() (
	LC_ALL=C awk -v wanted="$2" '
		/^[ \t]*\|/ {
			line = $0
			sub(/^[ \t]*\|/, "", line)
			sub(/\|[ \t]*$/, "", line)
			count = split(line, cells, "|")
			row = ""
			separator = 1
			for (i = 1; i <= count; i++) {
				gsub(/^[ \t]+/, "", cells[i])
				gsub(/[ \t]+$/, "", cells[i])
				if (cells[i] == wanted) matched = 1
				if (cells[i] !~ /^:?-+:?$/) separator = 0
				row = row (i > 1 ? "\t" : "") cells[i]
			}
			if (!found && !matched) next
			found = 1
			if (!separator) print row
			next
		}
		found { exit }
		END { if (!found) exit 1 }
	' "$1"
)

# 레인 표를 "도메인<TAB>경로" 행으로 출력합니다.
convention_reader_lanes() (
	convention_reader_rows=$(convention_reader_table "$1" '도메인') || return 1
	printf '%s\n' "$convention_reader_rows" | LC_ALL=C awk -F '\t' '
		NR == 1 {
			for (i = 1; i <= NF; i++) column[$i] = i
			next
		}
		{
			domain = $(column["도메인"])
			gsub(/`/, "", domain)
			paths = $(column["경로"])
			while (match(paths, /`[^`]+`/)) {
				print domain "\t" substr(paths, RSTART + 1, RLENGTH - 2)
				paths = substr(paths, RSTART + RLENGTH)
			}
		}
	'
)

# 라벨 표를 "카테고리<TAB>라벨<TAB>required|optional" 행으로 출력합니다.
convention_reader_labels() (
	convention_reader_rows=$(convention_reader_table "$1" '카테고리') || return 1
	printf '%s\n' "$convention_reader_rows" | LC_ALL=C awk -F '\t' '
		NR == 1 { next }
		{
			# 첫 열이 비면 위 행의 카테고리를 잇습니다.
			if ($1 != "") {
				required = index($1, "필수") ? "required" : "optional"
				category = $1
				sub(/ .*/, "", category)
				gsub(/`/, "", category)
			}
			name = $2
			gsub(/`/, "", name)
			if (name != "") print category "\t" name "\t" required
		}
	'
)

# 템플릿에서 front matter를 뺀 본문을 출력합니다.
convention_reader_template_body() (
	awk '
		NR == 1 && $0 == "---" { front = 1; next }
		front { if ($0 == "---") front = 0; next }
		{ print }
	' "$1"
)

# 템플릿 front matter의 labels 값을 한 줄에 하나씩 출력합니다.
convention_reader_template_labels() (
	sed -n 's/^labels:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "$1" |
		tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | awk 'NF'
)

# 본문의 목적 절을 제목 문장으로 채웁니다.
convention_reader_fill_purpose() (
	CONVENTION_READER_TITLE=$2 awk '
		{ print }
		$0 == "## 목적" && !filled {
			print ENVIRON["CONVENTION_READER_TITLE"] "."
			filled = 1
		}
	' "$1"
)
