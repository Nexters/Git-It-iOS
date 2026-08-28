#!/bin/sh
set -eu

test_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd -P)
resolver="$test_root/tools/spec-kit/bin/resolve-feature.sh"
validator="$test_root/tools/spec-kit/bin/validate.sh"

assert_contains() {
	printf '%s' "$1" | grep -F "$2" >/dev/null || {
		printf '기대 문자열 없음: %s\n' "$2" >&2
		exit 1
	}
}

assert_fails_with() {
	assert_command_name=$1
	assert_expected=$2
	shift 2
	if "$@" >"$test_work/$assert_command_name.out" 2>&1; then
		printf '%s가 성공했습니다\n' "$assert_command_name" >&2
		exit 1
	fi
	assert_contains "$(cat "$test_work/$assert_command_name.out")" "$assert_expected"
}

# 모든 검증은 현재 checkout과 무관한 격리 저장소에서 수행합니다.
test_work=$(mktemp -d "${TMPDIR:-/tmp}/git-it-spec-kit-test.XXXXXX")
trap 'rm -rf "$test_work"' EXIT HUP INT TERM
fixture="$test_work/repository"
mkdir -p "$fixture/specs/001-one" "$fixture/specs/002-two" \
	"$fixture/.specify" "$fixture/.agents/skills/speckit-fixture"
git -C "$fixture" init -q
git -C "$fixture" config user.name 'Spec Kit Test'
git -C "$fixture" config user.email 'spec-kit-test@example.invalid'
git -C "$fixture" commit --allow-empty -q -m fixture
git -C "$fixture" branch -m feature/one
printf '## Allowed Write Paths\n' >"$fixture/.agents/skills/speckit-fixture/SKILL.md"
printf 'hooks: {}\n' >"$fixture/.specify/extensions.yml"
printf '**기능 브랜치**: `미생성 (예정: feature/one)`\n' >"$fixture/specs/001-one/spec.md"
printf '**기능 브랜치**: `feature/two`\n' >"$fixture/specs/002-two/spec.md"

# Legacy 예정 metadata와 실제 legacy branch를 모두 계속 해석합니다.
output=$(SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$resolver" feature/one)
assert_contains "$output" 'SPEC_DIR=specs/001-one'
printf '**기능 브랜치**: `001-legacy-feature`\n' >"$fixture/specs/001-one/spec.md"
git -C "$fixture" symbolic-ref HEAD refs/heads/001-legacy-feature
output=$(SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$resolver" 001-legacy-feature)
assert_contains "$output" 'SPEC_DIR=specs/001-one'

# 중복 association과 지원하지 않는 metadata는 fail-closed입니다.
printf '**기능 브랜치**: `feature/one`\n' >"$fixture/specs/001-one/spec.md"
printf '**기능 브랜치**: `feature/one`\n' >"$fixture/specs/002-two/spec.md"
assert_fails_with duplicate 'speckit.identity.duplicate-branch' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$resolver" feature/one
printf '**기능 브랜치**: `unsupported/name`\n' >"$fixture/specs/002-two/spec.md"
git -C "$fixture" symbolic-ref HEAD refs/heads/feature/one
assert_fails_with invalid_metadata 'speckit.identity.invalid-metadata' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"
printf '**기능 브랜치**: feature/two\n' >"$fixture/specs/002-two/spec.md"
assert_fails_with malformed_metadata 'speckit.identity.invalid-metadata' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"

# 안전한 pointer도 다른 branch metadata를 가리키면 stale입니다.
printf '**기능 브랜치**: `feature/two`\n' >"$fixture/specs/002-two/spec.md"
printf '{\n  "feature_directory":\n  "specs/001-one"\n}\n' >"$fixture/.specify/feature.json"
SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator" >/dev/null
printf '{"feature_directory":"specs/002-two"}\n' >"$fixture/.specify/feature.json"
assert_fails_with stale_safe_pointer 'speckit.identity.stale-pointer' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"
printf '{"feature_directory":"../../outside"}\n' >"$fixture/.specify/feature.json"
assert_fails_with unsafe_pointer 'speckit.identity.stale-pointer' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"

# JSON처럼 보이는 문자열이 아니라 완전한 단일 JSON 문서만 pointer로 허용합니다.
printf '{"feature_directory":"specs/001-one"} trailing-garbage\n' >"$fixture/.specify/feature.json"
assert_fails_with malformed_pointer 'speckit.identity.stale-pointer' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"
printf '{"feature_directory":"specs/002-two","feature_directory":"specs/001-one"}\n' >"$fixture/.specify/feature.json"
assert_fails_with duplicate_pointer_key 'speckit.identity.stale-pointer' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"

# Dangling pointer symlink도 absent로 오인하지 않고 실패합니다.
rm -f "$fixture/.specify/feature.json"
ln -s "$fixture/.specify/missing-feature.json" "$fixture/.specify/feature.json"
assert_fails_with dangling_pointer 'speckit.identity.stale-pointer' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"
rm "$fixture/.specify/feature.json"

# Spec 디렉터리 symlink를 따라 외부 artifact를 읽지 않습니다.
mkdir -p "$fixture/external"
printf '**기능 브랜치**: `feature/link`\n' >"$fixture/external/spec.md"
ln -s "$fixture/external" "$fixture/specs/003-link"
assert_fails_with symlink_directory 'speckit.identity.unsafe-directory' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$resolver" feature/link
rm "$fixture/specs/003-link"

# 안전한 디렉터리 내부의 spec.md symlink도 외부 metadata를 읽지 않습니다.
mkdir -p "$fixture/specs/003-file-link"
ln -s "$fixture/external/spec.md" "$fixture/specs/003-file-link/spec.md"
assert_fails_with spec_file_symlink 'speckit.identity.unsafe-directory' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$resolver" feature/link
assert_fails_with validate_spec_file_symlink 'speckit.identity.unsafe-directory' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"
rm "$fixture/specs/003-file-link/spec.md"
rmdir "$fixture/specs/003-file-link"

# Symbolic branch가 없으면 현재 canonical identity를 결정할 수 없습니다.
rm -f "$fixture/.specify/feature.json"
git -C "$fixture" checkout -q --detach HEAD
assert_fails_with detached 'speckit.identity.detached-head' env SPEC_KIT_REPO_ROOT="$fixture" /bin/sh "$validator"

# 생성 sequence와 branch 출력도 복제 fixture의 상태만 사용합니다.
generator_fixture="$test_work/generator"
mkdir -p "$generator_fixture/.specify/scripts/bash" "$generator_fixture/.specify/templates" \
	"$generator_fixture/specs/007-existing" "$generator_fixture/tools/spec-kit/core"
cp "$test_root/.specify/scripts/bash/common.sh" "$generator_fixture/.specify/scripts/bash/common.sh"
cp "$test_root/.specify/scripts/bash/create-new-feature.sh" "$generator_fixture/.specify/scripts/bash/create-new-feature.sh"
cp "$test_root/.specify/templates/spec-template.md" "$generator_fixture/.specify/templates/spec-template.md"
cp "$test_root/tools/spec-kit/core/identity.sh" "$generator_fixture/tools/spec-kit/core/identity.sh"
git -C "$generator_fixture" init -q
git -C "$generator_fixture" symbolic-ref HEAD refs/heads/feature/fixture-identity
sequence_output=$(SPECIFY_INIT_DIR="$generator_fixture" bash "$generator_fixture/.specify/scripts/bash/create-new-feature.sh" --dry-run --short-name identity-policy 'identity policy')
assert_contains "$sequence_output" 'FEATURE_NUM: 008'
assert_contains "$sequence_output" 'BRANCH_NAME: feature/fixture-identity'

# 생성기와 resolver는 동일한 branch 문법을 사용합니다.
git -C "$generator_fixture" symbolic-ref HEAD refs/heads/feature/nested/invalid
assert_fails_with invalid_generator_branch 'current branch is not a supported canonical identity' env SPECIFY_INIT_DIR="$generator_fixture" bash "$generator_fixture/.specify/scripts/bash/create-new-feature.sh" --dry-run --short-name invalid invalid
git -C "$generator_fixture" symbolic-ref HEAD refs/heads/feature/fixture-identity

# 실제 생성은 association만 렌더링하고 검증 전 pointer를 변경하지 않습니다.
printf '{"feature_directory":"specs/007-existing"}\n' >"$generator_fixture/.specify/feature.json"
pointer_before=$(cat "$generator_fixture/.specify/feature.json")
SPECIFY_INIT_DIR="$generator_fixture" bash "$generator_fixture/.specify/scripts/bash/create-new-feature.sh" --number 8 --short-name identity-policy 'identity policy' >/dev/null
assert_contains "$(cat "$generator_fixture/specs/008-identity-policy/spec.md")" '**기능 브랜치**: `feature/fixture-identity`'
[ "$(cat "$generator_fixture/.specify/feature.json")" = "$pointer_before" ] || {
	printf '검증 전 생성이 기존 pointer를 변경했습니다\n' >&2
	exit 1
}
rm "$generator_fixture/.specify/feature.json"
SPECIFY_INIT_DIR="$generator_fixture" bash "$generator_fixture/.specify/scripts/bash/create-new-feature.sh" --allow-existing-branch --number 8 --short-name identity-policy 'identity policy' >/dev/null
[ ! -e "$generator_fixture/.specify/feature.json" ] || {
	printf '검증 전 생성이 새 pointer를 공개했습니다\n' >&2
	exit 1
}
rm -f "$generator_fixture/.specify/templates/spec-template.md"
assert_fails_with atomic_template_failure 'Spec template' env SPECIFY_INIT_DIR="$generator_fixture" bash "$generator_fixture/.specify/scripts/bash/create-new-feature.sh" --number 9 --short-name failed-artifact 'failed artifact'
[ ! -e "$generator_fixture/specs/009-failed-artifact" ] || {
	printf '실패한 생성이 artifact를 남겼습니다\n' >&2
	exit 1
}
[ ! -e "$generator_fixture/.specify/feature.json" ] || {
	printf '실패한 생성이 pointer를 공개했습니다\n' >&2
	exit 1
}

printf 'Spec-Kit identity 회귀 테스트 완료\n'
