#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/hook-install-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
repository="$work/repository"
mkdir -p "$repository/.githooks"
cp -R "$root/.githooks/." "$repository/.githooks/"
git -C "$repository" init -q
global_config="$work/global.gitconfig"
printf '[user]\n\tname = Global Test\n' >"$global_config"
global_before=$(cksum "$global_config")
GIT_CONFIG_GLOBAL="$global_config"
export GIT_CONFIG_GLOBAL
"$repository/.githooks/hook-management/bin/install.sh" >/dev/null
[ "$(git -C "$repository" config --local --get core.hooksPath)" = .githooks ]
[ -x "$repository/.githooks/commit-msg" ]
[ -x "$repository/.githooks/pre-commit" ]
for step in swift-format build compile test; do
	[ -x "$repository/.githooks/pre-commit.d/$step.sh" ]
done
[ "$global_before" = "$(cksum "$global_config")" ]
printf 'PASS: hook install\n'
