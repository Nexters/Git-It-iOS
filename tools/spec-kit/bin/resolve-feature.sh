#!/bin/sh
# shellcheck disable=SC1091
set -eu

spec_kit_main() (
	[ "$#" -le 1 ] || {
		printf '오류[speckit.common.invalid-input]: branch 인자는 하나만 허용합니다\n조치: resolve-feature.sh [feature/name] 형식으로 실행하세요\n' >&2
		return 2
	}
	spec_kit_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	spec_kit_root=${SPEC_KIT_REPO_ROOT:-$(CDPATH='' cd -- "$spec_kit_bin/../../.." && pwd -P)}
	spec_kit_root=$(CDPATH='' cd -- "$spec_kit_root" && pwd -P)
	. "$spec_kit_bin/../core/identity.sh"
	spec_kit_branch=${1:-$(git -C "$spec_kit_root" symbolic-ref --quiet --short HEAD 2>/dev/null || true)}
	spec_kit_validate_branch "$spec_kit_branch" || {
		printf '오류[speckit.identity.invalid-branch]: 지원하지 않는 branch입니다: %s\n관련 경로: %s\n조치: feature/, hotfix/, release/ namespace를 사용하거나 기존 NNN-slug branch를 보존하세요\n' "$spec_kit_branch" "$spec_kit_root" >&2
		return 2
	}
	spec_kit_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-spec-kit.XXXXXX") || return 2
	trap 'rm -rf "$spec_kit_work"' EXIT
	spec_kit_matches="$spec_kit_work/matches"
	: >"$spec_kit_matches"
	for spec_kit_spec in "$spec_kit_root"/specs/*/spec.md; do
		[ -e "$spec_kit_spec" ] || [ -L "$spec_kit_spec" ] || continue
		spec_kit_dir=${spec_kit_spec%/spec.md}
		spec_kit_validate_spec_file "$spec_kit_root" "$spec_kit_spec" || {
			printf '오류[speckit.identity.unsafe-directory]: 안전하지 않은 spec artifact입니다\n관련 경로: %s\n조치: specs의 비-symlink 직계 하위 디렉터리와 regular non-symlink spec.md를 사용하세요\n' "$spec_kit_spec" >&2
			return 2
		}
		[ "$(spec_kit_read_branch "$spec_kit_spec")" = "$spec_kit_branch" ] && printf '%s\n' "$spec_kit_dir" >>"$spec_kit_matches"
	done
	spec_kit_count=$(wc -l <"$spec_kit_matches" | tr -d ' ')
	[ "$spec_kit_count" -le 1 ] || {
		printf '오류[speckit.identity.duplicate-branch]: 하나의 branch가 여러 spec에 연결되어 있습니다: %s\n관련 경로:\n' "$spec_kit_branch" >&2
		sed 's/^/  - /' "$spec_kit_matches" >&2
		printf '조치: legacy artifact의 branch association을 명시적으로 해제하세요\n' >&2
		return 2
	}
	[ "$spec_kit_count" -eq 1 ] || {
		printf '오류[speckit.identity.not-found]: branch metadata와 일치하는 spec이 없습니다: %s\n관련 경로: %s/specs\n조치: speckit-specify로 새 artifact를 생성하거나 metadata를 교정하세요\n' "$spec_kit_branch" "$spec_kit_root" >&2
		return 3
	}
	spec_kit_dir=$(sed -n '1p' "$spec_kit_matches")
	printf 'GIT_BRANCH_NAME=%s\n' "$spec_kit_branch"
	printf 'SPEC_DIR=%s\n' "${spec_kit_dir#"$spec_kit_root"/}"
	printf 'SPEC_FILE=%s/spec.md\n' "${spec_kit_dir#"$spec_kit_root"/}"
	printf 'RESOLUTION=branch-metadata\n'
)

spec_kit_main "$@"
