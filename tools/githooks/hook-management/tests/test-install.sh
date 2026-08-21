#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../../.." && pwd -P)
paths="$root/tools/repository-paths/bin/repository-paths.sh"
hooks_root=$("$paths" GIT_IT_HOOKS_ROOT)
config_relative=$("$paths" GIT_IT_PATHS_FILE)
fixture_hooks_root='fixture-hooks'
work=$(mktemp -d "${TMPDIR:-/tmp}/hook-install-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/$fixture_hooks_root" "$(dirname -- "$repository/${paths#"$root/"}")"
cp -R "$root/$hooks_root/." "$repository/$fixture_hooks_root/"
cp "$paths" "$repository/${paths#"$root/"}"
cp "$root/$config_relative" "$repository/$config_relative"
/usr/bin/plutil -replace GIT_IT_HOOKS_ROOT -string "$fixture_hooks_root" \
	"$repository/$config_relative"
git -C "$repository" init -q
global_config="$work/global.gitconfig"
printf '[user]\n\tname = Global Test\n' >"$global_config"
global_before=$(cksum "$global_config")
GIT_CONFIG_GLOBAL="$global_config"
export GIT_CONFIG_GLOBAL
"$repository/$fixture_hooks_root/hook-management/bin/install.sh" >/dev/null
[ "$(git -C "$repository" config --local --get core.hooksPath)" = "$fixture_hooks_root" ]
[ -x "$repository/$fixture_hooks_root/commit-msg" ]
[ -x "$repository/$fixture_hooks_root/pre-commit" ]
[ -x "$repository/$fixture_hooks_root/pre-push" ]
for step in swift-format build compile; do
	[ -x "$repository/$fixture_hooks_root/pre-commit.d/$step.sh" ]
done
[ ! -e "$repository/$fixture_hooks_root/pre-commit.d/test.sh" ]
# 기본 pre-commit은 셸 회귀와 staged Swift 포맷을 실행합니다.
rg -qx 'script-tests' "$repository/$fixture_hooks_root/pre-commit.d/enabled"
rg -qx 'swift-format' "$repository/$fixture_hooks_root/pre-commit.d/enabled"
[ "$global_before" = "$(cksum "$global_config")" ]
printf 'PASS: hook install\n'
