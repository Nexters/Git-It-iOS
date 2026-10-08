# 실행 환경을 읽지 않는 저장소 경로 정책입니다.

path_policy_is_within() (
	path_policy_allowed=$1
	path_policy_candidate=$2

	case "$path_policy_candidate/" in
	"$path_policy_allowed/" | "$path_policy_allowed/"*) return 0 ;;
	*) return 1 ;;
	esac
)

path_policy_repository_relative() (
	path_policy_root=$1
	path_policy_absolute=$2

	if [ "$path_policy_absolute" = "$path_policy_root" ]; then
		printf '.\n'
		return 0
	fi

	case "$path_policy_absolute/" in
	"$path_policy_root/"*) printf '%s\n' "${path_policy_absolute#"$path_policy_root/"}" ;;
	*) return 2 ;;
	esac
)

path_policy_is_allowed_source() (
	path_policy_source_root=$1
	path_policy_candidate=$2
	path_policy_is_within "$path_policy_source_root" "$path_policy_candidate"
)

path_policy_file_kind() (
	path_policy_path=$1
	case "$path_policy_path" in
	*.swift) printf 'swift\n' ;;
	*.sh) printf 'shell\n' ;;
	*.json | *.xcstrings) printf 'json\n' ;;
	*.pbxproj | *.plist | *.entitlements) printf 'plist\n' ;;
	*.xcscheme) printf 'scheme\n' ;;
	*) printf 'other\n' ;;
	esac
)
