# local Git config port를 주입받아 설정·권한·재확인을 수행합니다.

hook_install_run() (
	hook_install_set=$1
	hook_install_prepare=$2
	hook_install_read=$3
	hook_install_verify=$4
	hook_install_root=$5
	hook_install_hooks_root=$6

	"$hook_install_set" "$hook_install_root" "$hook_install_hooks_root" || return 1
	"$hook_install_prepare" "$hook_install_root" "$hook_install_hooks_root" || return 1
	hook_install_config=$("$hook_install_read" "$hook_install_root") || return 1
	[ "$hook_install_config" = "$hook_install_hooks_root" ] || return 1
	"$hook_install_verify" "$hook_install_root" "$hook_install_hooks_root"
)
