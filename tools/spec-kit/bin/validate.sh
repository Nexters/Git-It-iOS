#!/bin/sh
# shellcheck disable=SC1091
set -eu

spec_kit_validate_main() (
	spec_kit_bin=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
	spec_kit_root=${SPEC_KIT_REPO_ROOT:-$(CDPATH='' cd -- "$spec_kit_bin/../../.." && pwd -P)}
	spec_kit_root=$(CDPATH='' cd -- "$spec_kit_root" && pwd -P)
	. "$spec_kit_bin/../core/identity.sh"
	spec_kit_current_branch=$(git -C "$spec_kit_root" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
	[ -n "$spec_kit_current_branch" ] || {
		printf '오류[speckit.identity.detached-head]: 현재 checkout에 symbolic branch가 없습니다\n관련 경로: %s\n조치: 검증할 feature branch를 checkout하세요\n' "$spec_kit_root" >&2
		return 2
	}
	spec_kit_validate_branch "$spec_kit_current_branch" || {
		printf '오류[speckit.identity.invalid-branch]: 현재 branch가 지원되는 Git-flow 또는 legacy 형식이 아닙니다: %s\n조치: feature/, hotfix/, release/ namespace를 사용하거나 기존 NNN-slug branch를 보존하세요\n' "$spec_kit_current_branch" >&2
		return 2
	}
	spec_kit_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-spec-kit-validation.XXXXXX") || return 2
	trap 'rm -rf "$spec_kit_work"' EXIT
	spec_kit_branches="$spec_kit_work/branches"
	: >"$spec_kit_branches"
	for spec_kit_spec in "$spec_kit_root"/specs/*/spec.md; do
		[ -e "$spec_kit_spec" ] || [ -L "$spec_kit_spec" ] || continue
		spec_kit_validate_spec_file "$spec_kit_root" "$spec_kit_spec" || {
			printf '오류[speckit.identity.unsafe-directory]: 안전하지 않은 spec artifact입니다\n관련 경로: %s\n조치: regular non-symlink spec.md를 사용하세요\n' "${spec_kit_spec#"$spec_kit_root"/}" >&2
			return 2
		}
		spec_kit_branch=$(spec_kit_read_branch "$spec_kit_spec")
		[ -n "$spec_kit_branch" ] || {
			printf '오류[speckit.identity.invalid-metadata]: 기능 브랜치 metadata가 없거나 형식이 잘못되었습니다\n관련 경로: %s\n조치: backtick으로 감싼 단일 기능 브랜치 값을 기록하세요\n' "${spec_kit_spec#"$spec_kit_root"/}" >&2
			return 2
		}
		if spec_kit_is_unlinked_branch "$spec_kit_branch"; then
			continue
		fi
		spec_kit_validate_branch "$spec_kit_branch" || {
			printf '오류[speckit.identity.invalid-metadata]: 지원하지 않는 기능 브랜치 metadata입니다: %s\n관련 경로: %s\n조치: Git-flow branch, 보존된 NNN-slug branch 또는 명시적 미연결 표식을 사용하세요\n' "$spec_kit_branch" "${spec_kit_spec#"$spec_kit_root"/}" >&2
			return 2
		}
		printf '%s\t%s\n' "$spec_kit_branch" "${spec_kit_spec#"$spec_kit_root"/}" >>"$spec_kit_branches"
	done
	spec_kit_duplicates=$(cut -f1 "$spec_kit_branches" | sort | uniq -d)
	[ -z "$spec_kit_duplicates" ] || {
		printf '오류[speckit.identity.duplicate-branch]: canonical branch association이 중복되었습니다\n관련 경로:\n' >&2
		for spec_kit_branch in $spec_kit_duplicates; do awk -F '\t' -v branch="$spec_kit_branch" '$1 == branch { print "  - " $2 }' "$spec_kit_branches" >&2; done
		printf '조치: branch마다 하나의 spec.md association만 남기세요\n' >&2
		return 2
	}
	if [ -e "$spec_kit_root/.specify/feature.json" ] || [ -L "$spec_kit_root/.specify/feature.json" ]; then
		[ -f "$spec_kit_root/.specify/feature.json" ] && [ ! -L "$spec_kit_root/.specify/feature.json" ] || {
			printf '오류[speckit.identity.stale-pointer]: feature.json은 regular non-symlink 파일이어야 합니다\n관련 경로: .specify/feature.json\n조치: pointer를 삭제한 뒤 branch metadata에서 재생성하세요\n' >&2
			return 2
		}
		spec_kit_pointer=$(spec_kit_read_pointer "$spec_kit_root/.specify/feature.json" || true)
		case "$spec_kit_pointer" in specs/*) ;; *) spec_kit_pointer='' ;; esac
		case "${spec_kit_pointer#specs/}" in ''|*/*|.|..) spec_kit_pointer='' ;; esac
		[ -n "$spec_kit_pointer" ] && [ -d "$spec_kit_root/$spec_kit_pointer" ] && [ ! -L "$spec_kit_root/$spec_kit_pointer" ] || {
			printf '오류[speckit.identity.stale-pointer]: feature.json이 안전한 specs 직계 하위를 가리키지 않습니다\n관련 경로: .specify/feature.json\n조치: pointer를 삭제한 뒤 branch metadata에서 재생성하세요\n' >&2
			return 2
		}
		spec_kit_pointer_branch=$(spec_kit_read_branch "$spec_kit_root/$spec_kit_pointer/spec.md")
		[ "$spec_kit_pointer_branch" = "$spec_kit_current_branch" ] || {
			printf '오류[speckit.identity.stale-pointer]: feature.json 대상 metadata가 현재 branch와 다릅니다\n관련 경로: %s/spec.md\n조치: pointer를 삭제한 뒤 현재 branch metadata에서 재생성하세요\n' "$spec_kit_pointer" >&2
			return 2
		}
	fi
	# 설치된 모든 Spec-Kit Skill이 자신의 write boundary를 직접 선언하는지 확인합니다.
	for spec_kit_skill in "$spec_kit_root"/.agents/skills/speckit-*/SKILL.md; do
		[ -f "$spec_kit_skill" ] || continue
		grep -Eq '^## (Allowed Write Paths|허용 수정 경로)$' "$spec_kit_skill" || {
			printf '오류[speckit.policy.write-scope-mismatch]: Skill의 write boundary 선언이 없습니다\n관련 경로: %s\n조치: 해당 Skill에 Allowed Write Paths 또는 허용 수정 경로를 선언하세요\n' "${spec_kit_skill#"$spec_kit_root"/}" >&2
			return 2
		}
	done
	# 등록된 mandatory formatter hook의 실제 독립 Skill 존재를 fail-closed로 확인합니다.
	if grep -Eq 'command:[[:space:]]*speckit\.swift-format\.run' "$spec_kit_root/.specify/extensions.yml"; then
		[ -f "$spec_kit_root/.agents/skills/speckit-swift-format-run/SKILL.md" ] || {
			printf '오류[speckit.policy.unknown-skill]: hook command에 대응하는 Skill이 없습니다\n관련 경로: .specify/extensions.yml\n조치: speckit-swift-format-run Skill을 설치하거나 hook을 비활성화하세요\n' >&2
			return 2
		}
	fi
	printf 'Spec-Kit identity 및 정책 정합성 검증 완료\n'
)

spec_kit_validate_main "$@"
