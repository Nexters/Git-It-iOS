# 현재 저장소 local Git config와 hook executable만 변경합니다.

hook_git_config_set() (
	hook_git_config_root=$1
	hook_git_config_hooks_root=$2
	git -C "$hook_git_config_root" config --local core.hooksPath "$hook_git_config_hooks_root"
)

hook_git_config_prepare() (
	hook_git_config_root=$1
	hook_git_config_hooks_root=$2
	chmod +x \
		"$hook_git_config_root/$hook_git_config_hooks_root/commit-msg" \
		"$hook_git_config_root/$hook_git_config_hooks_root/pre-commit" \
		"$hook_git_config_root/$hook_git_config_hooks_root/pre-commit.d/swift-format.sh" \
		"$hook_git_config_root/$hook_git_config_hooks_root/pre-commit.d/build.sh" \
		"$hook_git_config_root/$hook_git_config_hooks_root/pre-commit.d/compile.sh"
)

hook_git_config_read() (
	git -C "$1" config --local --get core.hooksPath
)

# source되는 port는 호출자 상태 격리를 유지합니다.
# shellcheck disable=SC2235
hook_git_config_verify() (
	hook_git_config_root=$1
	hook_git_config_hooks_root=$2
	for hook_git_config_path in \
		commit-msg \
		pre-commit \
		pre-commit.d/swift-format.sh \
		pre-commit.d/build.sh \
		pre-commit.d/compile.sh; do
		[ -x "$hook_git_config_root/$hook_git_config_hooks_root/$hook_git_config_path" ] || return 1
	done
)
