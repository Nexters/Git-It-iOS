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
module_source="$repository/tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift"
infrastructure_module_source="$repository/tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift"
ui_module_source="$repository/tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift"
app_module_source="$repository/tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift"
mkdir -p "$(dirname -- "$scheme_source")" \
	"$projects/ReadyTests" \
	"$projects/EmptyTests" \
		"$projects/Infrastructure/Tests/Authentication" \
		"$projects/Domain/Tests/LearningProject" \
		"$projects/UI/Tests/Component/Unit" \
		"$projects/App/Tests/GitIt" \
	"$(dirname -- "$module_source")"

printf '%s\n' \
	'case .App:' \
	'    [.package(' \
	'        name: .App,' \
	'        testTargets: [],' \
	'    )]' \
	'    [.package(' \
	'        name: .AppTests,' \
	'        testTargets: [' \
	'            AppModuleName.GitItTests.rawValue,' \
	'        ],' \
	'    )]' \
	'case .Ready:' \
	'    [.package(' \
	'        name: .Ready,' \
	'        testTargets: [' \
	'            "ReadyTests",' \
	'        ],' \
	'    )]' \
	'case .Empty:' \
	'    [.package(' \
	'        name: .Empty,' \
	'        testTargets: [' \
	'            "EmptyTests",' \
	'        ],' \
	'    )]' \
	'case .Infrastructure:' \
	'    [.package(' \
	'        name: .Infrastructure,' \
	'        testTargets: [' \
	'            InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,' \
	'        ],' \
	'    )]' \
	'case .Domain:' \
	'    [.package(' \
	'        name: .Domain,' \
	'        testTargets: [' \
	'            DomainModuleName.DomainLearningProjectTests.rawValue,' \
	'        ],' \
	'    )]' \
	'case .UI:' \
	'    [.package(' \
	'        name: .UI,' \
		'        testTargets: [' \
		'            UIModuleName.UIComponentTests.rawValue,' \
		'        ],' \
	'    )]' >"$scheme_source"
printf '%s\n' \
	'var sourceDirectory: String {' \
	'    rawValue.droppingPrefix("Domain")' \
	'}' \
	'var target: Target {' \
	'    switch self {' \
	'    case .DomainLearningProjectTests:' \
	'        .testModule(' \
	'            name: rawValue,' \
	'            sourceDirectory: sourceDirectory,' \
	'        )' \
	'    }' \
	'}' >"$module_source"
printf '%s\n' \
	'.testModule(' \
	'    name: InfrastructureModuleName.InfrastructureAuthenticationTests.rawValue,' \
	'    sourceDirectory: InfrastructureModuleName.InfrastructureAuthenticationTests.sourceDirectory,' \
	')' >"$infrastructure_module_source"
printf '%s\n' \
		'var sourceDirectory: String {' \
		'    "Component/Unit"' \
		'}' \
		'case .UIComponentTests:' \
		'.testModule(' \
		'    name: UIModuleName.UIComponentTests.rawValue,' \
		'    sourceDirectory: UIModuleName.UIComponentTests.sourceDirectory,' \
		')' >"$ui_module_source"
printf '%s\n' \
	'var sourceDirectory: String {' \
	'    switch self {' \
	'    case .GitItTests:' \
	'        "Tests/GitIt"' \
	'    default:' \
	'        ""' \
	'    }' \
	'}' \
	'case .GitItTests:' \
	'    .target(' \
	'        name: rawValue,' \
	'sour''ces: ["\(sourceDirectory)/**"],' \
	'    )' >"$app_module_source"
printf '%s\n' 'import Testing' '@Test func appSample() {}' \
	>"$projects/App/Tests/GitIt/GitItTests.swift"
if script_tests_list_scheme_test_targets "$scheme_source" | rg -q '^GitIt\|App$'; then
	printf 'FAIL: 빈 testTargets 배열 다음의 build target을 test target으로 읽었습니다\n' >&2
	exit 1
fi
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
	>"$projects/Infrastructure/Tests/Authentication/AuthenticationTests.swift"
printf '%s\n' 'import Testing' '@Test func domainLearningProjectSample() {}' \
	>"$projects/Domain/Tests/LearningProject/LearningProjectTests.swift"
if script_tests_validate_testable_schemes "$projects" "$scheme_source" >"$work/out" 2>"$work/err"; then
	printf 'FAIL: UIComponent test target의 역할 폴더를 찾지 못했습니다\n' >&2
	exit 1
fi
rg -q 'script-tests.empty-test-target.*UIComponentTests' "$work/err"

printf '%s\n' 'import Testing' '@Test func componentSample() {}' \
		>"$projects/UI/Tests/Component/Unit/ComponentTests.swift"
script_tests_validate_testable_schemes "$projects" "$scheme_source"
printf 'PASS: testable schemes\n'
