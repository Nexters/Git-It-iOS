# 패키지 목록과 규칙·오류 종류별 조치를 argv만으로 결정하는 순수 정책입니다.

# 아키텍처 3.1 표가 다루는 프로젝트 내부 패키지입니다.
package_dependencies_packages() (
	printf '%s\n' App Composition Feature Domain Data Infrastructure UI
)

# 허용 목록(공백 구분)에 대상 패키지가 있으면 성공합니다. 같은 패키지는 항상 허용합니다.
package_dependencies_allows() (
	[ "$#" -eq 3 ] || return 2
	pd_package=$1
	pd_target_package=$2
	pd_allowed=$3
	[ "$pd_package" = "$pd_target_package" ] && return 0
	case " $pd_allowed " in
	*" $pd_target_package "*) return 0 ;;
	esac
	return 1
)

# 오류·위반 종류에 대한 조치 문장을 출력합니다.
package_dependencies_action() (
	[ "$#" -eq 1 ] || return 2
	case "$1" in
	violated)
		printf '%s\n' '위 선언이나 import를 아키텍처 3.1 표가 허용하는 방향으로 고치거나, 표와 config/allowed-dependencies를 함께 바꾸세요'
		;;
	missing-config | invalid-config)
		printf '%s\n' '.tools/package-dependencies/config의 설정 파일 형식과 패키지 이름을 확인하세요'
		;;
	table-unreadable)
		printf '%s\n' '아키텍처 문서의 "### 3.1" 제목과 "| 패키지 | 허용 의존성 |" 표 형식을 복원하세요'
		;;
	missing-manifest | module-duplicate | target-missing | target-unknown | target-duplicate | declaration-mismatch)
		printf '%s\n' 'Tuist <패키지>ModuleName.swift의 모듈 enum과 target 선언이 서로 대응하는지 확인하세요'
		;;
	source-root-missing | source-root-unknown | source-root-absent | source-root-package | source-unmapped)
		printf '%s\n' 'config/source-roots를 manifest의 target과 실제 소스 디렉터리에 맞게 갱신하세요'
		;;
	*)
		return 2
		;;
	esac
)
