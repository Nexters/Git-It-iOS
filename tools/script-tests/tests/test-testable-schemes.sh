#!/bin/sh
# shellcheck disable=SC1090,SC1091
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
module=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/testable-schemes-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
. "$module/core/testable-schemes.sh"

repository="$work/repository"
projects="$repository/projects"
scheme_source="$repository/tuist/ProjectDescriptionHelpers/ProjectName.swift"
mkdir -p "$(dirname -- "$scheme_source")" \
	"$projects/ReadyTests" \
	"$projects/EmptyTests" \
	"$projects/AuthenticationTests"

printf '%s\n' \
	'case .Ready:' \
	'    [.module(name: "Ready", testTarget: "ReadyTests")]' \
	'case .Empty:' \
	'    [.module(name: "Empty", testTarget: "EmptyTests")]' \
	'case .Infrastructure:' \
	'    [.module(name: "InfrastructureAuthentication", testTarget: "InfrastructureAuthenticationTests")]' >"$scheme_source"
printf '%s\n' 'import Testing' '@Test func sample() {}' \
	>"$projects/ReadyTests/ReadyTests.swift"
printf '%s\n' '// placeholder' >"$projects/EmptyTests/Placeholder.swift"

if script_tests_validate_testable_schemes "$projects" "$scheme_source" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 빈 testTarget을 성공으로 반환\n' >&2
	exit 1
fi
rg -q 'script-tests.empty-test-target.*EmptyTests' "$work/err"

printf '%s\n' 'import XCTest' 'final class EmptyTests: XCTestCase {}' \
	>"$projects/EmptyTests/EmptyTests.swift"

if script_tests_validate_testable_schemes "$projects" "$scheme_source" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: 패키지 접두어를 제거한 test 폴더를 찾지 못했습니다\n' >&2
	exit 1
fi
rg -q 'script-tests.empty-test-target.*InfrastructureAuthenticationTests' "$work/err"

printf '%s\n' 'import Testing' '@Test func authenticationSample() {}' \
	>"$projects/AuthenticationTests/AuthenticationTests.swift"
script_tests_validate_testable_schemes "$projects" "$scheme_source"
printf 'PASS: testable schemes\n'
