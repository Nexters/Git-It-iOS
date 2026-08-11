#!/bin/sh
set -eu

suite=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)

for layer in bin core tests config dependencies; do
	[ -d "$suite/$layer" ] || {
		printf 'FAIL: 검증기 계층 누락: %s\n' "$layer" >&2
		exit 1
	}
done

if rg -n 'scripts/(project-build|swift-format|hook-management)/|--include-project-build|verification_project_build' \
	"$suite/bin" "$suite/core" >/dev/null 2>&1; then
	printf 'FAIL: 다른 프로젝트 스크립트 실행 의존이 남아 있음\n' >&2
	exit 1
fi

if rg -n 'VERIFICATION_ROOT/\$VERIFICATION_GITHOOKS_ROOT.*tests|find .*VERIFICATION_ROOT/\$VERIFICATION_GITHOOKS_ROOT.*test-' \
	"$suite/bin" "$suite/core" >/dev/null 2>&1; then
	printf 'FAIL: 다른 기능 테스트 실행 의존이 남아 있음\n' >&2
	exit 1
fi

if rg -n '\.agents/|VERIFICATION_REFERENCE_ROOT|verification_checklist_run|VERIFICATION_DOCUMENT_CHECKLIST' \
	"$suite/bin" "$suite/core" "$suite/config" >/dev/null 2>&1; then
	printf 'FAIL: 검증기에 스킬 또는 문서 체크리스트 의존이 남아 있음\n' >&2
	exit 1
fi

rg -Fq 'VERIFICATION_SUITE_ROOT/tests' "$suite/core/regression.sh"
printf 'PASS: verification boundaries\n'
