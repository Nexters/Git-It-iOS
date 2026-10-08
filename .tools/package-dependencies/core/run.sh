# 설정·표·manifest·import를 수집하고 판정 결과를 보고하는 유스케이스입니다.

# source root 설정을 읽고 루트 디렉터리 존재를 확인합니다.
package_dependencies_read_roots() (
	pd_config=$1
	pd_projects=$2
	pd_output=$3
	pd_errors=$4
	awk -v out="$pd_output" -v errors="$pd_errors" -v file="$pd_config" '
		/^[ \t]*(#|$)/ { next }
		{
			if (NF != 2 || $1 in seen) {
				printf "invalid-config\t%s\t%d\t형식이 \"<target> <루트>\"가 아니거나 target이 중복됨\n", file, NR >> errors
				failed = 1
				next
			}
			seen[$1] = 1
			root = $2
			sub(/\/+$/, "", root)
			printf "%s\t%s\t%d\n", $1, root, NR > out
		}
		END { if (failed) exit 2 }
	' "$pd_config" || return 2

	while IFS="$(printf '\t')" read -r pd_target pd_root pd_line; do
		[ -d "$pd_projects/$pd_root" ] ||
			printf 'source-root-absent\t%s\t%s\ttarget %s: 루트 디렉터리 %s 없음\n' \
				"$pd_config" "$pd_line" "$pd_target" "$pd_root" >>"$pd_errors"
	done <"$pd_output"
	return 0
)

# 저장소 루트 아래 경로는 상대경로로 바꿔 보고합니다.
package_dependencies_relative() (
	pd_root=$1
	awk -v prefix="$pd_root/" -F '\t' 'BEGIN { OFS = "\t" } index($1, prefix) == 1 { $1 = substr($1, length(prefix) + 1) } { print }'
)

# 오류 레코드를 종류별 조치와 함께 출력합니다.
package_dependencies_report_errors() (
	pd_root=$1
	pd_errors=$2
	pd_sorted="$pd_errors.sorted"
	awk -F '\t' 'BEGIN { OFS = "\t" } { print $2, $3, $1, $4 }' "$pd_errors" |
		package_dependencies_relative "$pd_root" | LC_ALL=C sort -u >"$pd_sorted"
	pd_last=''
	while IFS="$(printf '\t')" read -r pd_file pd_line pd_kind pd_reason; do
		pd_location=$pd_file
		[ "$pd_line" = 0 ] || pd_location="$pd_location:$pd_line"
		printf '오류[package-dependencies.%s]: %s %s\n' "$pd_kind" "$pd_location" "$pd_reason" >&2
		if [ "$pd_kind" != "$pd_last" ]; then
			printf '조치: %s\n' "$(package_dependencies_action "$pd_kind")" >&2
			pd_last=$pd_kind
		fi
	done <"$pd_sorted"
)

package_dependencies_run() (
	pd_root=$1
	pd_projects=$2
	pd_tuist=$3
	pd_architecture=$4
	pd_config=$5
	pd_work=$6
	pd_known=$(package_dependencies_packages | tr '\n' ' ')
	pd_errors="$pd_work/errors"
	: >"$pd_errors"

	# 1. 허용 의존성 설정
	pd_allowed_config="$pd_config/allowed-dependencies"
	[ -r "$pd_allowed_config" ] || {
		printf 'missing-config\t%s\t0\t허용 의존성 설정을 읽을 수 없음\n' "$pd_allowed_config" >>"$pd_errors"
		package_dependencies_report_errors "$pd_root" "$pd_errors"
		return 2
	}
	package_dependencies_read_allowed "$pd_allowed_config" "$pd_work/allowed" "$pd_errors" "$pd_known" || {
		package_dependencies_report_errors "$pd_root" "$pd_errors"
		return 2
	}

	# 2. 아키텍처 3.1 표
	package_dependencies_read_table "$pd_architecture" "$pd_work/table" || {
		printf 'table-unreadable\t%s\t0\t3.1 패키지 의존성 표를 읽을 수 없음\n' "$pd_architecture" >>"$pd_errors"
		package_dependencies_report_errors "$pd_root" "$pd_errors"
		return 2
	}

	# 3. 패키지별 manifest
	: >"$pd_work/modules"
	: >"$pd_work/targets"
	: >"$pd_work/declarations"
	for pd_package in $pd_known; do
		pd_manifest="$pd_tuist/ProjectDescriptionHelpers/Projects/${pd_package}ModuleName.swift"
		if [ ! -r "$pd_manifest" ]; then
			printf 'missing-manifest\t%s\t0\t%s 패키지 manifest가 없음\n' "$pd_manifest" "$pd_package" >>"$pd_errors"
			continue
		fi
		package_dependencies_collect_manifest "$pd_manifest" "$pd_package" "$pd_work" || return 2
	done

	# 4. source root
	pd_roots_config="$pd_config/source-roots"
	if [ -r "$pd_roots_config" ]; then
		package_dependencies_read_roots "$pd_roots_config" "$pd_projects" "$pd_work/roots" "$pd_errors" || {
			package_dependencies_report_errors "$pd_root" "$pd_errors"
			return 2
		}
	else
		printf 'missing-config\t%s\t0\tsource root 설정을 읽을 수 없음\n' "$pd_roots_config" >>"$pd_errors"
		: >"$pd_work/roots"
	fi

	# 5. Swift 파일과 import
	package_dependencies_collect_imports "$pd_projects" "$pd_work/files" "$pd_work/imports" || return 2

	# 6. 판정
	: >"$pd_work/violations"
	package_dependencies_judge "$pd_work" "$pd_projects" "$pd_architecture" || return 2
	if [ -s "$pd_errors" ]; then
		package_dependencies_report_errors "$pd_root" "$pd_errors"
		return 2
	fi

	# 7. 보고
	IFS="$(printf '\t')" read -r pd_target_count pd_file_count <"$pd_errors.summary"
	if [ ! -s "$pd_work/violations" ]; then
		printf '패키지 의존성 검사 완료: target=%s 파일=%s 위반=0\n' "$pd_target_count" "$pd_file_count"
		return 0
	fi
	package_dependencies_relative "$pd_root" <"$pd_work/violations" |
		LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2n -k3,3 >"$pd_work/violations.sorted"
	pd_violation_count=0
	while IFS="$(printf '\t')" read -r pd_file pd_line pd_rule pd_reason; do
		printf '%s:%s: [%s] %s\n' "$pd_file" "$pd_line" "$pd_rule" "$pd_reason" >&2
		pd_violation_count=$((pd_violation_count + 1))
	done <"$pd_work/violations.sorted"
	printf '오류[package-dependencies.violated]: 위반 %s건\n조치: %s\n' \
		"$pd_violation_count" "$(package_dependencies_action violated)" >&2
	return 1
)
