# local Git config port를 주입받아 설정·권한·재확인을 수행합니다.

hook_install_run() (
	hook_install_set=$1
	hook_install_prepare=$2
	hook_install_read=$3
	hook_install_verify=$4

	"$hook_install_set" || return 1
	"$hook_install_prepare" || return 1
	hook_install_config=$("$hook_install_read") || return 1
	[ "$hook_install_config" = .githooks ] || return 1
	"$hook_install_verify"
)
