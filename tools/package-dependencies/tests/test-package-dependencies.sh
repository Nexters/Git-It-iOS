#!/bin/sh
# 패키지 의존성 검사가 fixture 저장소의 위반을 막고 정상 구성은 통과시키는지 검사합니다.
set -eu

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
suite=$(CDPATH='' cd -- "$test_dir/.." && pwd -P)
runner="$suite/bin/run.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/package-dependencies-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
fixture="$work/fixture"

# 경로를 만들고 본문을 파일 하나에 씁니다.
write_file() {
	mkdir -p "$(dirname -- "$1")"
	printf '%s\n' "$2" >"$1"
}

# 모든 규칙을 통과하는 최소 저장소를 새로 만듭니다.
make_fixture() {
	rm -rf "$fixture"
	manifests="$fixture/manifest-root/ProjectDescriptionHelpers/Projects"
	projects="$fixture/packages"

	write_file "$fixture/architecture-rules.md" '# 아키텍처

### 3.1 프로젝트 내부 패키지 의존성

| 패키지 | 허용 의존성 |
|---|---|
| App | Feature, Composition, Domain |
| Composition | Domain, Data |
| Feature | Domain, UI |
| Domain | — |
| Data | Infrastructure |
| Infrastructure | — |
| UI | — |

각 패키지는 최소 의존성만 선언합니다.'

	write_file "$fixture/config/allowed-dependencies" '# fixture
App: Feature Composition Domain
Composition: Domain Data
Feature: Domain UI
Domain:
Data: Infrastructure
Infrastructure:
UI:'

	write_file "$fixture/config/source-roots" 'GitIt App/GitIt
GitItTests App/Tests/GitIt
CompositionApp Composition/App
Feature Feature
FeatureTests Feature/Tests
DomainMember Domain/Member
DataMember Data/Member
InfrastructureNetworkClient Infrastructure/NetworkClient
InfrastructureNetworkClientTests Infrastructure/Tests/NetworkClient
DesignSystem UI/DesignSystem
UIComponent UI/Component'

	write_file "$manifests/AppModuleName.swift" 'import ProjectDescription

enum AppModuleName: String, CaseIterable {
    case GitIt
    case GitItTests
}

extension AppModuleName {
    var target: Target {
        switch self {
        case .GitIt:
            .target(
                name: rawValue,
                dependencies: [
                    .fromComposition(.CompositionApp),
                    .fromFeature(.Feature),
                    .fromDomain(.DomainMember),
                ],
            )

        case .GitItTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(
                    name: AppModuleName.GitIt.rawValue
                ),
            )
        }
    }
}'

	write_file "$manifests/CompositionModuleName.swift" 'enum CompositionModuleName: String, CaseIterable {
    case CompositionApp
}

extension CompositionModuleName {
    var target: Target {
        switch self {
        case .CompositionApp:
            .module(
                name: rawValue,
                dependencies: [
                    .fromDomain(.DomainMember),
                    .fromData(.DataMember),
                ],
            )
        }
    }
}'

	write_file "$manifests/FeatureModuleName.swift" 'enum FeatureModuleName: String, CaseIterable {
    case Feature
    case FeatureTests
}

extension FeatureModuleName {
    var sourceDirectory: String {
        switch self {
        case .Feature:
            "."
        case .FeatureTests:
            ""
        }
    }

    var target: Target {
        switch self {
        case .Feature:
            .module(
                name: rawValue,
                dependencies: [
                    .fromDomain(.DomainMember),
                    .fromUI(.UIComponent),
                ],
            )

        case .FeatureTests:
            .testModule(
                name: rawValue,
                productionTarget: .target(name: FeatureModuleName.Feature.rawValue),
            )
        }
    }
}'

	write_file "$manifests/DomainModuleName.swift" 'enum DomainModuleName: String, CaseIterable {
    case DomainMember
}

extension DomainModuleName {
    var target: Target {
        switch self {
        case .DomainMember:
            .module(name: rawValue, dependencies: [])
        }
    }
}'

	write_file "$manifests/DataModuleName.swift" 'enum DataModuleName: String, CaseIterable {
    case DataMember
}

extension DataModuleName {
    var target: Target {
        switch self {
        case .DataMember:
            .module(
                name: rawValue,
                dependencies: [
                    .fromInfrastructure(.InfrastructureNetworkClient)
                ],
            )
        }
    }
}'

	write_file "$manifests/InfrastructureModuleName.swift" 'enum InfrastructureModuleName: String {
    case InfrastructureNetworkClient
    case InfrastructureNetworkClientTests
}

extension InfrastructureModuleName {
    static let targets: [Target] = [
        .module(
            name: InfrastructureModuleName.InfrastructureNetworkClient.rawValue,
            dependencies: [
                .sdk(name: "Security", type: .framework)
            ],
        ),
        .testModule(
            name: InfrastructureModuleName.InfrastructureNetworkClientTests.rawValue,
            productionTarget: .target(
                name: InfrastructureModuleName.InfrastructureNetworkClient.rawValue
            ),
        ),
    ]
}

extension TargetDependency {
    static func fromInfrastructure(_ name: InfrastructureModuleName) -> Self {
        .project(target: name.rawValue, path: "../Infrastructure")
    }
}'

	write_file "$manifests/UIModuleName.swift" 'enum DesignSystemFontFamily: String, CaseIterable {
    case notoSansKR
}

enum UIModuleName: String {
    case DesignSystem
    case UIComponent
}

extension UIModuleName {
    static let targets: [Target] = [
        .module(
            name: UIModuleName.UIComponent.rawValue,
            dependencies: [
                .target(name: UIModuleName.DesignSystem.rawValue),
                .external(.Lottie),
            ],
        ),
        .module(
            name: UIModuleName.DesignSystem.rawValue,
        ),
    ]
}'

	write_file "$projects/App/GitIt/GitItApp.swift" 'import CompositionApp
import DomainMember
import Feature
import SwiftUI'
	write_file "$projects/App/Tests/GitIt/GitItTests.swift" 'import DomainMember
@testable import GitIt
import Testing'
	write_file "$projects/App/Project.swift" 'import ProjectDescription'
	write_file "$projects/Composition/App/AppComposition.swift" 'import DataMember
import DomainMember'
	write_file "$projects/Feature/Home/HomeFeature.swift" 'import DomainMember
import UIComponent'
	write_file "$projects/Feature/Tests/Home/HomeFeatureTests.swift" 'import DomainMember
@testable import Feature'
	write_file "$projects/Feature/Derived/Sources/Generated.swift" 'import DataMember'
	write_file "$projects/Domain/Member/Member.swift" 'import Foundation'
	write_file "$projects/Data/Member/MemberRemote.swift" 'import InfrastructureNetworkClient'
	write_file "$projects/Infrastructure/NetworkClient/HTTPClient.swift" 'import Foundation'
	write_file "$projects/Infrastructure/Tests/NetworkClient/HTTPClientTests.swift" '@testable import InfrastructureNetworkClient'
	write_file "$projects/UI/DesignSystem/Color.swift" 'import SwiftUI'
	write_file "$projects/UI/Component/Button.swift" 'import DesignSystem'
}

# fixture 경로를 주입해 검사를 실행하고 종료 코드를 기록합니다.
run_check() {
	config_dir=${1:-$fixture/config}
	if GIT_IT_PROJECTS_ROOT="$fixture/packages" \
		GIT_IT_TUIST_ROOT="$fixture/manifest-root" \
		GIT_IT_ARCHITECTURE_PATH="$fixture/architecture-rules.md" \
		PACKAGE_DEPENDENCIES_CONFIG_DIR="$config_dir" \
		"$runner" >"$work/out" 2>"$work/err"; then
		status=0
	else
		status=$?
	fi
}

# 기대 종료 코드와 출력 문구를 확인합니다.
expect() {
	expect_name=$1
	expect_status=$2
	expect_text=$3
	[ "$status" -eq "$expect_status" ] || {
		printf 'FAIL: %s 종료 코드 %s, 기대 %s\n' "$expect_name" "$status" "$expect_status" >&2
		cat "$work/out" "$work/err" >&2
		exit 1
	}
	[ -z "$expect_text" ] || grep -Fq -- "$expect_text" "$work/out" "$work/err" || {
		printf 'FAIL: %s 출력에 %s 없음\n' "$expect_name" "$expect_text" >&2
		cat "$work/out" "$work/err" >&2
		exit 1
	}
}

# 줄 하나를 파일 끝에 덧붙입니다.
append() {
	printf '%s\n' "$2" >>"$1"
}

# 1. 정상 구성은 통과한다. Derived 생성물, Project.swift와 test target 상속은 위반이 아니다.
make_fixture
run_check
expect '정상 구성' 0 '위반=0'

# 2. 허용되지 않는 manifest 선언은 실패한다.
make_fixture
sed 's/\.fromUI(\.UIComponent),/.fromUI(.UIComponent),\
                    .fromData(.DataMember),/' "$manifests/FeatureModuleName.swift" >"$work/edited"
mv "$work/edited" "$manifests/FeatureModuleName.swift"
run_check
expect 'manifest 선언' 1 '[manifest-package] Feature target이 Data 패키지 모듈 DataMember'
expect 'manifest 선언 위치' 1 'FeatureModuleName.swift:24:'

# 3. 허용되지 않는 패키지의 import는 실패한다.
make_fixture
append "$projects/Feature/Home/HomeFeature.swift" 'import DataMember'
run_check
expect '패키지 import' 1 '[import-package] Feature target(Feature)에서 Data 패키지 모듈 DataMember'

# 4. 허용 패키지라도 target manifest가 선언하지 않은 모듈 import는 실패한다.
make_fixture
append "$projects/Feature/Home/HomeFeature.swift" 'import DesignSystem'
run_check
expect '미선언 import' 1 '[import-undeclared] Feature target manifest에 DesignSystem 선언 없음'

# 5. 설정과 아키텍처 표가 다르면 실패한다.
make_fixture
sed 's/^UI:$/UI: Domain/' "$fixture/config/allowed-dependencies" >"$work/edited"
mv "$work/edited" "$fixture/config/allowed-dependencies"
run_check
expect '표 불일치' 1 '[table-mismatch] UI: 표 없음 / 설정 Domain'

# 6. 표 형식이 깨지면 통과가 아니라 입력 오류다.
make_fixture
sed 's/| 허용 의존성 |/| 의존성 |/' "$fixture/architecture-rules.md" >"$work/edited"
mv "$work/edited" "$fixture/architecture-rules.md"
run_check
expect '표 형식' 2 'package-dependencies.table-unreadable'

# 7. 설정 파일이 없으면 입력 오류다.
make_fixture
run_check "$fixture/missing-config"
expect '설정 없음' 2 'package-dependencies.missing-config'

# 8. 주석과 문자열 안의 import는 위반이 아니다.
make_fixture
append "$projects/Feature/Home/HomeFeature.swift" '// import DataMember
let pattern = "Tests/**"
/* import DataMember
   /* nested */ import DataMember
*/
let text = """
import DataMember
"""
let url = "https://example.com/*"'
run_check
expect '주석과 문자열' 0 '위반=0'

# 9. 조건부 컴파일 안의 import도 검사한다.
make_fixture
append "$projects/Feature/Home/HomeFeature.swift" '#if DEBUG
@preconcurrency import DataMember
#endif'
run_check
expect '조건부 import' 1 '[import-package]'

# 10. 접두어 없는 내부 모듈도 내부 모듈로 판정한다.
make_fixture
append "$projects/Feature/Home/HomeFeature.swift" 'import GitIt'
run_check
expect '접두어 없는 모듈' 1 'App 패키지 모듈 GitIt'

# 11. test target은 production 선언만 상속하고 그 밖의 모듈은 선언해야 한다.
make_fixture
append "$projects/Feature/Tests/Home/HomeFeatureTests.swift" 'import DesignSystem'
run_check
expect 'test target 상속 밖' 1 '[import-undeclared] FeatureTests target manifest에 DesignSystem 선언 없음'

# 12. 어느 target 루트에도 속하지 않는 Swift 파일은 입력 오류다.
make_fixture
write_file "$projects/Domain/Stray/Stray.swift" 'import Foundation'
run_check
expect '루트 밖 파일' 2 'package-dependencies.source-unmapped'

# 13. manifest target과 source root 표가 어긋나면 입력 오류다.
make_fixture
sed '/^DataMember /d' "$fixture/config/source-roots" >"$work/edited"
mv "$work/edited" "$fixture/config/source-roots"
run_check
expect 'source root 누락' 2 'package-dependencies.source-root-missing'

# 14. Composition의 Infrastructure import는 실패한다.
make_fixture
append "$projects/Composition/App/AppComposition.swift" 'import InfrastructureNetworkClient'
run_check
expect 'Composition Infrastructure import' 1 '[import-package] CompositionApp target(Composition)에서 Infrastructure 패키지 모듈 InfrastructureNetworkClient'

# 15. Composition manifest의 Infrastructure 선언은 실패한다.
make_fixture
sed 's/\.fromData(\.DataMember),/.fromData(.DataMember),\
                    .fromInfrastructure(.InfrastructureNetworkClient),/' "$manifests/CompositionModuleName.swift" >"$work/edited"
mv "$work/edited" "$manifests/CompositionModuleName.swift"
run_check
expect 'Composition Infrastructure manifest' 1 '[manifest-package] CompositionApp target이 Infrastructure 패키지 모듈 InfrastructureNetworkClient'

# 16. 인자는 받지 않는다.
if "$runner" unexpected >"$work/out" 2>"$work/err"; then
	status=0
else
	status=$?
fi
expect '인자 거부' 2 'common.invalid-input'

printf '패키지 의존성 검사 회귀 통과\n'
