# Git It iOS 테스트 컨벤션

**상태**: 정본

**작성일**: 2026-08-19

**최종 수정일**: 2026-08-21

## 목적

이 문서는 Git It iOS의 테스트를 읽을 수 있는 동작 명세로 유지하기 위한 작성 기준입니다.
패키지별 테스트 대상과 의존성 경계는 [아키텍처 문서](../architecture.md#5-테스트-정책)를
함께 따릅니다. 이 문서가 Constitution과 충돌하면 Constitution이 우선합니다.

## 1. 적용 범위

- `sources/Projects/<Package>/Tests/` 아래의 단위·통합·계약 테스트에 적용합니다.
- 같은 `Tests/` 루트 아래의 UI 자동화 테스트에도 적용하되, 테스트 프레임워크 선택은
  §2.2의 예외를 따릅니다.
- 새 테스트와 수정하는 기존 테스트는 이 문서를 준수합니다. 작업 범위와 무관한 기존
  테스트를 컨벤션 적용만을 위해 한꺼번에 변경하지 않습니다.
- 제품 소스의 타입·메서드·프로퍼티 이름은 [네이밍 컨벤션](./naming.md)을 따릅니다.

## 2. 테스트 프레임워크

### 2.1 Swift Testing을 기본으로 사용합니다

일반 테스트는 `Testing`을 import하고 `@Suite`, `@Test`, `#expect`, `#require`를
사용합니다.

```swift
import Testing

@Suite("학습 프로젝트 목록 로딩")
struct LearningProjectListLoadingTests {

    @Test
    func `빈 페이지는 로딩 완료와 빈 상태를 함께 표현한다`() {
        let state = LearningProjectListFeature.State(loadState: .loaded)

        #expect(state.isEmpty)
    }
}
```

- 값과 상태 비교에는 `#expect`를 사용합니다.
- 이후 검증에 필요한 전제 조건과 optional 해제에는 `try #require`를 사용합니다.
- 오류 계약은 동기 코드에 `#expect(throws:)`, 비동기 코드에
  `await #expect(throws:)`를 사용합니다.
- 같은 입력과 기대 결과를 반복할 때는 `@Test(arguments:)`를 사용합니다.
- 비동기 완료 횟수나 콜백을 검증할 때는 임의의 `sleep` 대신 Swift Testing의
  `confirmation` 또는 대상이 제공하는 구조화된 동시성 완료 지점을 사용합니다.

### 2.2 XCTest는 필요한 플랫폼 기능에만 사용합니다

`XCUIApplication`, `XCUIElement`처럼 Swift Testing이 직접 제공하지 않는 XCTest UI
자동화 API가 필요한 경우에만 `XCTestCase`를 사용합니다. 새 예외를 추가하면 테스트
파일 또는 PR 설명에 Swift Testing으로 작성할 수 없는 이유를 남깁니다.

- 하나의 테스트 파일에서 Swift Testing과 XCTest 선언을 섞지 않습니다.
- Xcode가 Swift Testing 테스트를 `xctest` runner로 실행하는 것은 XCTest 작성 예외가
  아닙니다.
- XCTest UI 자동화에서도 §3의 한국어 동작 이름과 §4 이후의 격리·검증 규칙을 따릅니다.

## 3. 테스트 이름

### 3.1 테스트 함수 이름은 한국어 동작 문장으로 작성합니다

Swift Testing의 테스트 함수는 backtick 식별자를 사용해 다음 순서로 작성합니다.

```text
조건 또는 사용자 행동 + 관찰 가능한 결과
```

```swift
@Test
func `조회 실패 뒤 재시도는 같은 입력으로 다시 조회한다`() async {
    // ...
}

@Test
func `삭제 실패는 목록과 삭제 모드를 유지한다`() async throws {
    // ...
}
```

- `testFetchProjects`, `성공한다`, `정상 동작한다`처럼 의도나 결과가 불명확한 이름을
  사용하지 않습니다.
- 구현 절차보다 외부에서 관찰할 수 있는 상태, 반환 값, 오류, 위임과 호출 계약을
  이름에 드러냅니다.
- `HTTP`, `URL`, `Protocol`, `loading`, `delegate`처럼 코드와 직접 대응해야 의미가
  정확한 식별자·API 이름은 원문을 유지할 수 있습니다. 나머지 문장은 한국어로
  작성합니다.
- `@Suite`의 표시 이름은 검증 대상과 범위를 한국어로 설명합니다. 테스트 타입과
  helper, Mock, Test Double의 Swift 식별자는 영어 이름을 유지합니다.

XCTest UI 자동화는 discovery를 위한 `test` 접두어를 유지하고 나머지를 한국어로
작성합니다.

```swift
func test_큰_액션_버튼은_상태가_바뀌어도_높이를_유지한다() {
    // ...
}
```

### 3.2 한 테스트는 하나의 동작 계약을 설명합니다

하나의 동작을 입증하는 데 필요한 여러 기대값은 한 테스트에서 함께 검증할 수 있습니다.
서로 독립적으로 실패하거나 이름 하나로 설명할 수 없는 동작은 별도 테스트로 분리합니다.

## 4. 테스트 구성

테스트 본문은 준비, 실행, 검증 순서를 유지합니다. 단계 주석은 의미를 더할 때만 쓰고,
일반적으로 빈 줄로 구분합니다.

```swift
@Test
func `삭제 확인 성공은 선택한 식별자를 한 번 전달한다`() async throws {
    let project = try makeProject(id: "project-1")
    let deleteProject = DeleteLearningProjectMock(
        behavior: .result(.success(()))
    )
    let store = makeStore(
        project: project,
        isDeleteMode: true,
        deleteLearningProject: deleteProject,
    )

    await store.send(.deleteButtonTapped(project.id)) {
        $0.pendingDeletion = project.id
    }
    await store.send(.deletionConfirmed)
    await store.receive(\.deletionResponse) {
        $0.projects.remove(id: project.id)
        $0.pendingDeletion = nil
        $0.isDeleteMode = false
    }

    #expect(await deleteProject.snapshot() == [project.id])
}
```

- 테스트 입력과 기대값은 테스트 본문에서 확인할 수 있는 결정적인 값으로 구성합니다.
- force unwrap과 강제 타입 변환으로 테스트 전제 조건을 숨기지 않습니다.
- 의미 있는 생성 규칙이 반복될 때만 private helper로 추출합니다.
- 실제 시간, 실행 순서, 네트워크 상태와 공유 전역 mutable state에 결과를 의존시키지
  않습니다.

## 5. 의존성 격리와 Test Double

- Domain Use Case, Repository와 외부 기술 기능은 소유 패키지의 Protocol을 구현한
  Test Double로 대체하고 initializer로 주입합니다.
- 테스트를 위해 production 코드에 Service Locator, 전역 mutable container 또는
  별도 `@Dependency` 경로를 추가하지 않습니다.
- Test Double은 필요한 반환·실패·대기 동작과 호출 기록만 제공합니다. production
  정책을 복제하지 않습니다.
- 동시 접근이 가능한 호출 기록은 `actor` 등 데이터 경쟁을 막는 소유자 안에 두고,
  검증에는 불변 snapshot을 사용합니다.
- 실제 네트워크, Keychain, 파일 시스템 또는 영속 저장소를 사용하는 테스트는 해당
  기술 통합이 검증 대상일 때만 별도 target 또는 명확한 Suite 경계에 둡니다.

## 6. Feature와 TCA 테스트

Feature 테스트는 Swift Testing 안에서 TCA의 `TestStore`를 사용합니다.

Feature 구성과 Effect 취소의 production 규칙은 [TCA 컨벤션](./tca.md)을 함께
따릅니다.

- 초기 State와 initializer로 주입할 Domain Use Case를 명시합니다.
- 사용자 입력은 `store.send`, Effect의 응답과 delegate 출력은 `store.receive`로
  검증합니다.
- State 변화는 가능한 한 `send`와 `receive`의 assertion closure에서 검증합니다.
- 외부 의존성의 입력과 호출 횟수는 Test Double의 snapshot으로 별도 검증합니다.
- 미완료 Effect는 테스트 종료 전에 취소하고 `finish()`로 정리합니다.
- 화면 밖 흐름은 실제 navigation을 실행하지 않고 Feature가 출력한 delegate Action을
  검증합니다.

패키지별 테스트 초점은 아키텍처 문서의 테스트 정책을 따릅니다. Domain은 모델·정책·Use
Case와 상태 전이, Data는 데이터 경계와 오류 처리, Composition은 변환과 위임, Feature는
State·Effect·사용자 상호작용을 중심으로 검증합니다.

## 7. 파일과 Target 구성

### 7.1 물리 폴더와 test target을 분리합니다

- 모든 테스트 소스는 `sources/Projects/<Package>/Tests/` 아래에 둡니다. 패키지 루트에
  `<TargetName>Tests/` 또는 `<TargetName>UITests/` 폴더를 나란히 만들지 않습니다.
- `Tests/`의 하위 폴더는 target 이름이 아니라 검증하는 production 모듈 또는 기능의
  역할을 표현합니다. 패키지 이름과 `Tests` 접미어를 반복하지 않습니다.
- Tuist test target 이름은 빌드 그래프 식별을 위해 패키지 문맥과 `Tests` 또는
  `UITests` 접미어를 유지할 수 있습니다. 폴더 이름과 target 이름을 같게 만들 필요는
  없습니다.
- 각 `Target.testModule`은 실제 테스트가 있는 가장 좁은 `sourceDirectory`를 명시합니다.
  하나의 package-wide test target이 여러 역할을 검증할 때는 `Tests`를 source root로
  지정하고 그 아래를 역할별로 나눌 수 있습니다.
- 같은 production 모듈에 일반 테스트와 UI 자동화 test target이 함께 있으면
  `Tests/<Module>/Unit/`, `Tests/<Module>/UI/`처럼 서로 겹치지 않는 역할 하위 폴더로
  분리합니다.

```text
sources/Projects/Domain/
├── Authentication/
└── Tests/
    └── Authentication/  # DomainAuthenticationTests의 sourceDirectory
```

- 테스트 파일은 검증 대상 또는 동작 범위에 따라 묶고 파일 이름은
  `<Subject>Tests.swift` 형식을 사용합니다.
- 반복 사용하는 Test Double은 대상 테스트 가까이의 `Mocks/` 또는 역할이 드러나는
  테스트 지원 폴더에 둡니다. 한 파일에서만 사용하는 작은 Double은 `private`로 둡니다.
- Tuist test target과 공유 scheme에는 실제 `@Test` 함수 또는 `XCTestCase` 테스트가
  있는 target만 연결합니다. 빈 test target을 scheme에 등록하지 않습니다.

### 7.2 scheme은 패키지와 그 패키지의 test target을 연결합니다

- 공유 scheme은 target별로 만들지 않고 패키지마다 하나만 둡니다. scheme 이름은
  `App`, `Composition`, `Feature`, `Domain`, `Data`, `Infrastructure`, `UI`처럼 패키지
  이름을 사용합니다.
- 패키지 scheme의 Build Action에는 그 패키지의 production target을, Test Action에는
  그 production target을 검증하는 모든 test target을 연결합니다.
- 여러 패키지의 test target을 하나의 scheme에 섞지 않습니다. 각 패키지는 자신의 공유
  scheme에서 독립적으로 컴파일하고 실행할 수 있어야 합니다.
- UI 자동화 test target은 별도 target과 host 구성을 유지하되 `UI` 패키지 scheme의
  Build·Test Action에 함께 연결합니다.
- scheme과 test target 연결의 정본은 `ProjectDescriptionHelpers`의 프로젝트 선언입니다.
  Tuist가 생성한 `.xcscheme` 파일을 직접 수정하지 않습니다.

## 8. 실행 결과와 기록

테스트 컴파일과 테스트 실행은 서로 다른 검증 단계입니다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" compile
"$project_build_runner" test
```

- `compile`의 성공은 `build-for-testing`의 컴파일·링크 성공만 의미합니다.
- 테스트 통과는 `test-without-building`에서 테스트 본문이 실행되고 결과가 성공했을 때만
  기록합니다.
- runner launch, preflight 또는 Simulator bootstrap 단계에서 실패해 테스트 본문에
  진입하지 못하면 제품 동작 실패로 단정하지 않습니다. scheme·test target·host 구성과
  Simulator 환경을 분리해 점검하고, 실행되지 않은 테스트를 통과로 기록하지 않습니다.
- PR에는 실제 실행한 명령, 성공·실패 단계, 실행된 테스트 수와 미검증 범위를 구분해
  기록합니다.

## 9. 검토 체크리스트

- [ ] 일반 테스트가 Swift Testing으로 작성되었는가?
- [ ] XCTest 사용이 UI 자동화 등 필요한 플랫폼 기능으로 제한되었는가?
- [ ] 테스트 함수 이름이 조건·행동과 결과를 설명하는 한국어 문장인가?
- [ ] 테스트가 하나의 동작 계약에 집중하는가?
- [ ] 의존성이 initializer와 최소 Test Double로 격리되었는가?
- [ ] 비동기 작업과 미완료 Effect가 결정적으로 종료되는가?
- [ ] 테스트가 `<Package>/Tests/<Module>/` 원칙에 따라 역할별로 배치되었는가?
- [ ] Tuist test target이 실제 폴더를 `sourceDirectory`로 명시하는가?
- [ ] 패키지 scheme이 같은 패키지의 production·test target만 연결하는가?
- [ ] `compile`과 `test` 결과를 구분해 기록했는가?
- [ ] 테스트 본문에 진입하지 못한 환경 실패를 테스트 통과 또는 제품 실패로 오해하지
  않았는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [TCA 컨벤션](./tca.md)

## 문서 변경 기준

기본 테스트 프레임워크, 테스트 이름·구성, Test Double, TCA 테스트 또는 test target
배치 규칙이 바뀔 때 수정합니다. 패키지별 테스트 책임이 바뀌면 아키텍처와 해당 패키지
규칙을 먼저 갱신합니다.
