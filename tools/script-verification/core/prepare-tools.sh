# lock reader, fetch, integrity와 원자적 배치 포트를 조합합니다.

prepare_tools_run() (
	prepare_tools_lock=$1
	prepare_tools_fetch=$2
	prepare_tools_integrity=$3
	prepare_tools_place=$4

	"$prepare_tools_lock" || return 2
	"$prepare_tools_fetch" || return 1
	"$prepare_tools_integrity" || return 1
	"$prepare_tools_place"
)
