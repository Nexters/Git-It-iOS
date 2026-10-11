# 빠른 시작: UC01~UC20 전체 UseCase end-to-end 구현 검증

이 문서는 각 패키지 단계(Domain → Infrastructure → Data → Composition → UI → Feature → App)의 구현이 실제로 동작하는지 확인하는 실행 가능한 검증 절차다. UC별 계약은 [contracts/usecase-catalog.md](./contracts/usecase-catalog.md), 엔터티·오류 정본은 [data-model.md](./data-model.md), 패키지 컨벤션은 [research.md](./research.md)를 참고한다. 구현 파일 목록과 세부 작업 순서는 `tasks.md`(2단계 산출물)가 정한다.

## 사전 준비

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

workspace가 없으면 먼저 생성한다.

```bash
cd sources && tuist install && tuist generate && cd -
```

## 패키지별 검증 순서

각 패키지 단계는 구현 완료 후 아래 명령으로 독립 검증하고, 결과를 사용자에게 보고한 뒤 승인을 받아야 다음 패키지로 진행한다(Constitution 원칙 7).

### 1. Domain (DomainAuthentication, DomainLearningProject, DomainMember)

```bash
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**기대 결과**: UC01~UC20 각각 대응하는 `XxxUseCase` Protocol·concrete `Xxx`·모델·오류가 컴파일되고, Domain 테스트(모델 불변식·success/error/cancellation)가 통과한다. Domain 공개 API에 DTO·HTTP·TCA·SwiftUI 타입이 없는지 `import` 목록을 확인한다.

### 2. Infrastructure

```bash
"$project_build_runner" build
"$project_build_runner" test
```

**기대 결과**: HTTP request headers/body/query/cancellation/timeout, Keychain atomic write/rollback, Apple callback state/replay/expiry, 알림 인증 adapter 테스트가 통과한다.

### 3. Data (DataAuthentication, DataExternalRepository, DataLearningProject, DataMember)

```bash
"$project_build_runner" build
"$project_build_runner" test
```

**기대 결과**:
- `HTTPLearningSetRemote`, `HTTPAnswerRemote`, `HTTPBookmarkRemote`, `HTTPMemberRemote`가 실제로 존재하고 실행 가능하다.
- 보호 request 캡처 테스트에서 `Authorization: Bearer <token>` 헤더가 매 요청 존재를 확인한다(UC01의 GitHub 요청에는 없어야 한다).
- 400/401/404/500/decoding/cancellation이 서로 다른 Data 오류로 매핑된다.

### 4. Composition (CompositionAdapter)

```bash
"$project_build_runner" build
"$project_build_runner" test
```

**기대 결과**:
- `AppComposition`의 모든 public property가 `any XxxUseCase` 타입이다(concrete/DTO/HTTPClient 노출 0건).
- in-memory Keychain/stub transport로 조립한 graph에서 여러 보호 Remote가 동일 session/transport identity를 공유한다.
- DTO→Domain, Data 오류→Domain 오류 매핑에서 nil ID·raw status·set progress·bookmark ID 손실이 0건이다.
- UC12/UC14는 서버 capability 부재를 release blocker로 명시하고 임의 endpoint를 만들지 않았는지 확인한다.

### 5. UI (DesignSystem, UIComponent, UIComponentPreviewApp)

```bash
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

시뮬레이터에서 확인:

```text
UIComponentPreviewApp(구 UIComponentLayoutHarness)을 실행해 신규 component(TextField
Default/Active/Filled/Error, setting row, selectable setting row, account action row,
learning-set row 320×130pt, question prompt, choice answer state, essay input, rubric,
labeled progress bar)가 카탈로그에 나타나는지 확인한다.
```

**기대 결과**: 모든 component가 scalar/value·Binding·callback만 공개 입력으로 받고 ViewModel/State/Props wrapper가 없다. 최대 Dynamic Type에서 44×44pt 미만 control이 없다.

### 6. Feature (U01~U08, FeatureTests)

```bash
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

**기대 결과**: TCA `TestStore` 기반 테스트가 각 화면의 성공/오류/delegate/취소/중복 방지 경로를 통과한다. Feature production 코드에 Data·Infrastructure·Composition import와 `@Dependency` 조회가 0건이다.

### 7. App (GitIt, GitItTests)

```bash
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

시뮬레이터 수동 확인(iOS 26.0+, `iPhone 17 Pro` 기본):

1. 앱을 최초 실행해 `Hello, world!` 또는 preview-only root가 아니라 세션 복원 → U01/U03 분기가 일어나는지 확인한다.
2. U01에서 Apple 로그인·약관·curation을 완료하면 U02 또는 U03으로 이동하는지 확인한다.
3. MainShell 탭 전환 후 로그아웃하면 보호 탭 state가 폐기되고 U01로 돌아오는지 확인한다.
4. U03/U04 → U07 → U08 → U05 경로에서 `projectID`/`setID`/`preferredQuestionID?` 등 route payload가 손실 없이 전달되는지 확인한다.

### 8. 전체 read-only 검증 (최종 승인 게이트 이후)

```bash
./tools/script-tests/bin/run.sh                  # 셸 스크립트를 변경했다면
./tools/script-verification/bin/run.sh           # 상동
```

CI에서 Swift lint, production build, unit test compile+execution, App root integration test, 변경 범위 UI test execution이 `GIT_IT_CI_VALIDATION_ENABLED` global flag로 인해 skip되지 않았는지 워크플로 실행 결과를 확인한다.

## 완료 판정

UC가 "구현됨"으로 판정되려면 [spec.md](./spec.md) "구현 완료 정의"(성공 기준 SC-014-001~015)를 모두 충족해야 한다. UC12/UC14처럼 서버 capability가 없는 경우 "구조 완료 / production 차단"으로 구분 표시하고 완료로 보고하지 않는다.
