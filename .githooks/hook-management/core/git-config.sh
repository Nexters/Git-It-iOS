# 현재 저장소 local Git config와 hook executable만 변경합니다.

hook_git_config_set() (
	git -C "$HOOK_REPOSITORY_ROOT" config --local core.hooksPath .githooks
)

hook_git_config_prepare() (
	chmod +x \
		"$HOOK_REPOSITORY_ROOT/.githooks/commit-msg" \
		"$HOOK_REPOSITORY_ROOT/.githooks/pre-commit" \
		"$HOOK_REPOSITORY_ROOT/.githooks/pre-commit.d/swift-format.sh" \
		"$HOOK_REPOSITORY_ROOT/.githooks/pre-commit.d/build.sh" \
		"$HOOK_REPOSITORY_ROOT/.githooks/pre-commit.d/compile.sh" \
		"$HOOK_REPOSITORY_ROOT/.githooks/pre-commit.d/test.sh"
)

hook_git_config_read() (
	git -C "$HOOK_REPOSITORY_ROOT" config --local --get core.hooksPath
)

# source되는 port는 호출자 상태 격리를 유지합니다.
# shellcheck disable=SC2235
hook_git_config_verify() (
	for hook_git_config_path in \
		.githooks/commit-msg \
		.githooks/pre-commit \
		.githooks/pre-commit.d/swift-format.sh \
		.githooks/pre-commit.d/build.sh \
		.githooks/pre-commit.d/compile.sh \
		.githooks/pre-commit.d/test.sh; do
		[ -x "$HOOK_REPOSITORY_ROOT/$hook_git_config_path" ] || return 1
	done
)
